import AppKit
import ApplicationServices
import ScreenCaptureKit
import CoreGraphics

// Internal Accessibility SPI to get CGWindowID directly from AXUIElement
@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ wid: UnsafeMutablePointer<CGWindowID>) -> AXError

public class WindowEngine: ObservableObject {
    public static let shared = WindowEngine()

    private var thumbnailCache = NSCache<NSNumber, NSImage>()
    private var lastThumbnailRequestTimes: [CGWindowID: Date] = [:]

    private init() {
        thumbnailCache.countLimit = 40
    }

    /// Fetches all active windows for a given application PID.
    public func fetchWindows(for app: NSRunningApplication) async -> [WindowInfo] {
        let pid = app.processIdentifier
        let appName = app.localizedName ?? "App"
        let appIcon = app.icon
        let bundleID = app.bundleIdentifier

        var windows: [WindowInfo] = []

        // 1. Query via Accessibility API
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let axResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        if axResult == .success, let axWindows = windowsRef as? [AXUIElement] {
            for axWin in axWindows {
                var titleRef: CFTypeRef?
                var posVal: CFTypeRef?
                var sizeVal: CFTypeRef?
                var minVal: CFTypeRef?
                var subroleRef: CFTypeRef?

                AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleRef)
                AXUIElementCopyAttributeValue(axWin, kAXSubroleAttribute as CFString, &subroleRef)
                AXUIElementCopyAttributeValue(axWin, "AXPosition" as CFString, &posVal)
                AXUIElementCopyAttributeValue(axWin, "AXSize" as CFString, &sizeVal)
                AXUIElementCopyAttributeValue(axWin, "AXMinimized" as CFString, &minVal)

                let subrole = subroleRef as? String ?? ""
                // Skip non-standard helper windows (tooltips, popups, menus)
                if !subrole.isEmpty && subrole != "AXStandardWindow" && subrole != "AXDialog" {
                    continue
                }

                let title = titleRef as? String ?? appName
                let isMinimized = minVal as? Bool ?? false
                var pos = CGPoint.zero
                var size = CGSize.zero

                if let posVal = posVal {
                    AXValueGetValue(posVal as! AXValue, .cgPoint, &pos)
                }
                if let sizeVal = sizeVal {
                    AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
                }

                // Filter out invisible or tiny auxiliary windows
                guard size.width > 80 && size.height > 60 else { continue }

                let bounds = CGRect(origin: pos, size: size)

                // Retrieve real CGWindowID directly from AXUIElement
                var wid: CGWindowID = 0
                let winRes = _AXUIElementGetWindow(axWin, &wid)
                let windowID = (winRes == .success && wid > 0) ? wid : CGWindowID(arc4random())

                let winInfo = WindowInfo(
                    id: windowID,
                    title: title.isEmpty ? appName : title,
                    appName: appName,
                    bundleIdentifier: bundleID,
                    owningPID: pid,
                    bounds: bounds,
                    isMinimized: isMinimized,
                    isOnScreen: !isMinimized,
                    axWindowElement: axWin,
                    thumbnail: nil,
                    appIcon: appIcon
                )
                windows.append(winInfo)
            }
        }

        // 2. If Accessibility didn't return any windows, query Quartz Window Services
        if windows.isEmpty {
            let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

            for win in windowList {
                let ownerPID = win[kCGWindowOwnerPID as String] as? pid_t ?? 0
                guard ownerPID == pid else { continue }

                let layer = win[kCGWindowLayer as String] as? Int ?? -1
                guard layer == 0 else { continue } // Normal window layer only

                let windowID = win[kCGWindowNumber as String] as? CGWindowID ?? 0
                let winName = win[kCGWindowName as String] as? String ?? ""
                let boundsDict = win[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
                let bounds = CGRect(
                    x: boundsDict["X"] ?? 0,
                    y: boundsDict["Y"] ?? 0,
                    width: boundsDict["Width"] ?? 800,
                    height: boundsDict["Height"] ?? 600
                )

                guard bounds.width > 100 && bounds.height > 80 else { continue }

                let winInfo = WindowInfo(
                    id: windowID,
                    title: winName.isEmpty ? appName : winName,
                    appName: appName,
                    bundleIdentifier: bundleID,
                    owningPID: pid,
                    bounds: bounds,
                    isMinimized: false,
                    isOnScreen: true,
                    axWindowElement: nil,
                    thumbnail: nil,
                    appIcon: appIcon
                )
                windows.append(winInfo)
            }
        }

        // 3. Capture thumbnails for retrieved windows
        for i in 0..<windows.count {
            let thumb = await captureThumbnail(for: windows[i])
            windows[i].thumbnail = thumb
        }

        return windows
    }

    /// Captures a thumbnail image for a window using ScreenCaptureKit or fallback rendering.
    public func captureThumbnail(for window: WindowInfo) async -> NSImage {
        let key = NSNumber(value: window.id)

        // Check cache with 5s freshness
        if let lastReq = lastThumbnailRequestTimes[window.id], Date().timeIntervalSince(lastReq) < 5.0 {
            if let cached = thumbnailCache.object(forKey: key) {
                return cached
            }
        }

        // Check if Screen Recording permission is available
        if CGPreflightScreenCaptureAccess() {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                if let scWin = content.windows.first(where: { $0.windowID == window.id }) {
                    let filter = SCContentFilter(desktopIndependentWindow: scWin)
                    let config = SCStreamConfiguration()
                    config.width = 360
                    config.height = 228
                    config.showsCursor = false

                    let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: config.width, height: config.height))
                    thumbnailCache.setObject(nsImage, forKey: key)
                    lastThumbnailRequestTimes[window.id] = Date()
                    return nsImage
                }
            } catch {
                // SCK capture failed, will use fallback
            }
        }

        // Fallback: render stylish placeholder preview (DO NOT cache indefinitely)
        let fallback = renderFallbackThumbnail(for: window)
        return fallback
    }

    /// Renders a modern window card thumbnail with real window title when screen capture is unavailable.
    private func renderFallbackThumbnail(for window: WindowInfo) -> NSImage {
        let size = NSSize(width: 180, height: 114)
        let image = NSImage(size: size)

        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)

        // Window background gradient
        let gradient = NSGradient(
            colors: [
                NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.20, alpha: 0.98),
                NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.14, alpha: 0.98)
            ]
        )
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        gradient?.draw(in: path, angle: -45)

        // Window Title Bar mockup
        let titleBarRect = NSRect(x: 0, y: size.height - 20, width: size.width, height: 20)
        let titleBarPath = NSBezierPath(roundedRect: titleBarRect, xRadius: 8, yRadius: 8)
        NSColor(white: 1.0, alpha: 0.08).setFill()
        titleBarPath.fill()

        // Traffic light dots
        let dotColors: [NSColor] = [
            NSColor(red: 1.0, green: 0.36, blue: 0.33, alpha: 1.0),
            NSColor(red: 1.0, green: 0.75, blue: 0.22, alpha: 1.0),
            NSColor(red: 0.16, green: 0.80, blue: 0.38, alpha: 1.0)
        ]
        for (i, dotColor) in dotColors.enumerated() {
            let dotRect = NSRect(x: 8 + (i * 10), y: Int(size.height) - 15, width: 6, height: 6)
            dotColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }

        // App icon in center
        if let icon = window.appIcon {
            let iconSize: CGFloat = 34.0
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2.0,
                y: (size.height - iconSize) / 2.0 + 4,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 0.95)
        }

        // Title text at bottom
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9.5, weight: .medium),
            .foregroundColor: NSColor(white: 0.85, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]
        let titleRect = NSRect(x: 8, y: 8, width: size.width - 16, height: 24)
        (window.title as NSString).draw(in: titleRect, withAttributes: attrs)

        image.unlockFocus()
        return image
    }

    // MARK: - Window Actions

    /// Focuses and brings the exact selected window to front.
    public func focusWindow(_ window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.owningPID) else { return }

        if let axWin = window.axWindowElement {
            // 1. Deminimize if minimized
            if window.isMinimized {
                AXUIElementSetAttributeValue(axWin, "AXMinimized" as CFString, kCFBooleanFalse)
            }

            // 2. Perform raise action first
            AXUIElementPerformAction(axWin, kAXRaiseAction as CFString)

            // 3. Set window as AXMain
            AXUIElementSetAttributeValue(axWin, "AXMain" as CFString, kCFBooleanTrue)

            // 4. Set as focused window on application element
            let appElement = AXUIElementCreateApplication(window.owningPID)
            AXUIElementSetAttributeValue(appElement, "AXMainWindow" as CFString, axWin)
            AXUIElementSetAttributeValue(appElement, "AXFocusedWindow" as CFString, axWin)
        }

        // 5. Activate the owning application
        app.activate()

        // 6. Chrome-specific window index booster for tabbed/PWA windows
        if window.bundleIdentifier == "com.google.Chrome" && !window.title.isEmpty {
            let prefix = window.title.components(separatedBy: " - ").first ?? window.title
            let safeTitle = prefix.replacingOccurrences(of: "\"", with: "\\\"")
            let script = """
            tell application "Google Chrome"
                repeat with w in windows
                    if title of w contains "\(safeTitle)" then
                        set index of w to 1
                        exit repeat
                    end if
                end repeat
            end tell
            """
            DispatchQueue.global(qos: .userInitiated).async {
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            }
        }
    }

    /// Closes the selected window.
    public func closeWindow(_ window: WindowInfo) {
        if let axWin = window.axWindowElement {
            var closeBtnRef: CFTypeRef?
            let res = AXUIElementCopyAttributeValue(axWin, kAXCloseButtonAttribute as CFString, &closeBtnRef)
            if res == .success, let closeBtn = closeBtnRef {
                AXUIElementPerformAction(closeBtn as! AXUIElement, kAXPressAction as CFString)
                return
            }
        }
    }

    /// Minimizes or unminimizes the selected window.
    public func toggleMinimize(_ window: WindowInfo) {
        if let axWin = window.axWindowElement {
            var minBtnRef: CFTypeRef?
            let res = AXUIElementCopyAttributeValue(axWin, kAXMinimizeButtonAttribute as CFString, &minBtnRef)
            if res == .success, let minBtn = minBtnRef {
                AXUIElementPerformAction(minBtn as! AXUIElement, kAXPressAction as CFString)
                return
            }
        }
    }

    /// Clears cached thumbnails.
    public func clearCache() {
        thumbnailCache.removeAllObjects()
        lastThumbnailRequestTimes.removeAll()
    }
}
