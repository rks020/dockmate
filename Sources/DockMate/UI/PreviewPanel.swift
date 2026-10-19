import AppKit
import SwiftUI

public class PreviewPanel: NSPanel {
    public static let shared = PreviewPanel()

    private var hostingView: NSHostingView<AnyView>?
    public private(set) var currentDockItem: DockItem?
    public private(set) var isMouseInside: Bool = false
    private var trackingArea: NSTrackingArea?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .popUpMenu
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
    }

    public func show(dockItem: DockItem, windows: [WindowInfo]) {
        self.currentDockItem = dockItem

        let isMedia = (dockItem.bundleIdentifier == "com.apple.Music" ||
                       dockItem.bundleIdentifier == "com.spotify.client" ||
                       dockItem.title.localizedCaseInsensitiveContains("music") ||
                       dockItem.title.localizedCaseInsensitiveContains("spotify"))

        let contentView = DockPreviewContainerView(
            dockItem: dockItem,
            windows: windows,
            isMediaApp: isMedia,
            onSelectWindow: { [weak self] win in
                WindowEngine.shared.focusWindow(win)
                self?.hide(animated: true)
            },
            onCloseWindow: { [weak self] win in
                WindowEngine.shared.closeWindow(win)
                // Refresh windows after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let app = NSRunningApplication(processIdentifier: win.owningPID) {
                        Task {
                            let updated = await WindowEngine.shared.fetchWindows(for: app)
                            if updated.isEmpty {
                                self?.hide(animated: true)
                            } else {
                                self?.show(dockItem: dockItem, windows: updated)
                            }
                        }
                    }
                }
            },
            onMinimizeWindow: { win in
                WindowEngine.shared.toggleMinimize(win)
            },
            onLaunchNewWindow: { [weak self] in
                if let pid = dockItem.processIdentifier, let app = NSRunningApplication(processIdentifier: pid) {
                    app.activate()
                }
                self?.hide(animated: true)
            },
            onQuitApp: { [weak self] in
                if let pid = dockItem.processIdentifier, let app = NSRunningApplication(processIdentifier: pid) {
                    app.terminate()
                }
                self?.hide(animated: true)
            }
        )

        let hosting = NSHostingView(rootView: AnyView(contentView))
        self.contentView = hosting
        self.hostingView = hosting

        // Fit content size
        let fittingSize = hosting.fittingSize
        self.setContentSize(fittingSize)

        // Calculate screen placement
        let orientation = GeometryHelpers.getDockOrientation()
        let screen = NSScreen.screens.first { $0.frame.contains(dockItem.screenBounds.origin) } ?? NSScreen.main ?? NSScreen.screens.first!
        let origin = GeometryHelpers.calculatePanelOrigin(
            dockItemScreenBounds: dockItem.screenBounds,
            panelSize: fittingSize,
            orientation: orientation,
            screen: screen
        )

        self.setFrameOrigin(origin)
        self.orderFrontRegardless()

        // Setup tracking area for mouse enter/exit
        updateTrackingArea()

        // Fade in animation
        self.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
    }

    public func hide(animated: Bool = true) {
        if !animated {
            self.orderOut(nil)
            self.currentDockItem = nil
            self.isMouseInside = false
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.currentDockItem = nil
            self.isMouseInside = false
        })
    }

    private func updateTrackingArea() {
        if let existing = trackingArea {
            contentView?.removeTrackingArea(existing)
        }
        guard let view = contentView else { return }
        let area = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(area)
        self.trackingArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        self.isMouseInside = true
    }

    public override func mouseExited(with event: NSEvent) {
        self.isMouseInside = false
    }
}
