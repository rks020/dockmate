import AppKit
import ApplicationServices

public class DockDetector: ObservableObject {
    public static let shared = DockDetector()

    @Published public private(set) var dockItems: [DockItem] = []
    @Published public private(set) var orientation: DockOrientation = .bottom
    @Published public private(set) var dockBounds: CGRect = .zero

    private init() {
        self.orientation = GeometryHelpers.getDockOrientation()
    }

    /// Finds the exact DockItem currently under the mouse location using direct Accessibility hit-testing.
    public func dockItem(at cocoaPoint: CGPoint) -> DockItem? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return nil }
        let dockHeight = screen.frame.height - screen.visibleFrame.height + 25

        // Only evaluate if mouse is within the bottom dock strip
        guard cocoaPoint.y >= 0 && cocoaPoint.y <= dockHeight else {
            return nil
        }

        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            return nil
        }

        let dockElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        let axX = Float(cocoaPoint.x)
        let axY = Float(screen.frame.height - cocoaPoint.y)

        var hitRef: AXUIElement?
        let res = AXUIElementCopyElementAtPosition(dockElement, axX, axY, &hitRef)
        guard res == .success, let hit = hitRef else { return nil }

        var subroleRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var urlRef: CFTypeRef?
        var posVal: CFTypeRef?
        var sizeVal: CFTypeRef?

        AXUIElementCopyAttributeValue(hit, kAXSubroleAttribute as CFString, &subroleRef)
        AXUIElementCopyAttributeValue(hit, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(hit, "AXURL" as CFString, &urlRef)
        AXUIElementCopyAttributeValue(hit, "AXPosition" as CFString, &posVal)
        AXUIElementCopyAttributeValue(hit, "AXSize" as CFString, &sizeVal)

        let subrole = subroleRef as? String ?? ""
        guard subrole == "AXApplicationDockItem" else { return nil }

        let title = titleRef as? String ?? ""
        guard !title.isEmpty else { return nil }

        var pos = CGPoint.zero
        var size = CGSize.zero
        if let posVal = posVal { AXValueGetValue(posVal as! AXValue, .cgPoint, &pos) }
        if let sizeVal = sizeVal { AXValueGetValue(sizeVal as! AXValue, .cgSize, &size) }

        guard size.width > 0 && size.height > 0 else { return nil }

        let cocoaY = screen.frame.height - pos.y - size.height
        let screenBounds = CGRect(x: pos.x, y: cocoaY, width: size.width, height: size.height)

        var bundleID: String? = nil
        if let url = urlRef as? URL {
            bundleID = Bundle(url: url)?.bundleIdentifier
        } else if let urlStr = urlRef as? String, let url = URL(string: urlStr) {
            bundleID = Bundle(url: url)?.bundleIdentifier
        }

        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let matchingApp = runningApps.first { app in
            if let bid = bundleID, app.bundleIdentifier == bid { return true }
            if let name = app.localizedName, name.caseInsensitiveCompare(title) == .orderedSame { return true }
            return false
        }

        let icon: NSImage?
        if let app = matchingApp {
            icon = app.icon
        } else if let bid = bundleID, let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid)?.path {
            icon = NSWorkspace.shared.icon(forFile: appPath)
        } else {
            icon = nil
        }

        return DockItem(
            title: title,
            bundleIdentifier: bundleID ?? matchingApp?.bundleIdentifier,
            processIdentifier: matchingApp?.processIdentifier,
            screenBounds: screenBounds,
            axBounds: CGRect(origin: pos, size: size),
            axElement: hit,
            icon: icon,
            isRunning: matchingApp != nil,
            isFolder: false
        )
    }

    public func refreshDockItems() {
        self.orientation = GeometryHelpers.getDockOrientation()
    }
}
