import AppKit
import Combine

public class DockTracker: ObservableObject {
    public static let shared = DockTracker()

    @Published public private(set) var activeHoveredItem: DockItem?
    @Published public private(set) var isTrackingEnabled: Bool = true

    private var mouseMonitor: Any?
    private var clickMonitor: Any?
    private var trackingTimer: Timer?

    private var hoverTimer: Timer?
    private var dismissTimer: Timer?

    private var candidateItem: DockItem?

    private init() {
        startTracking()
    }

    deinit {
        stopTracking()
    }

    public func startTracking() {
        isTrackingEnabled = true

        // 1. High frequency tracking timer to catch smooth cursor motions
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { [weak self] _ in
            self?.evaluateMousePosition()
        }

        // 2. Global mouse move monitor
        if mouseMonitor == nil {
            mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
                self?.evaluateMousePosition()
            }
        }

        // 3. Global click monitor to auto-dismiss on outside click
        if clickMonitor == nil {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                guard let self = self else { return }
                let mousePoint = NSEvent.mouseLocation
                if !PreviewPanel.shared.frame.contains(mousePoint) {
                    self.cancelHover()
                    PreviewPanel.shared.hide(animated: true)
                }
            }
        }
    }

    public func stopTracking() {
        isTrackingEnabled = false
        trackingTimer?.invalidate()
        trackingTimer = nil

        if let mm = mouseMonitor {
            NSEvent.removeMonitor(mm)
            mouseMonitor = nil
        }
        if let cm = clickMonitor {
            NSEvent.removeMonitor(cm)
            clickMonitor = nil
        }

        cancelHover()
        PreviewPanel.shared.hide(animated: false)
    }

    private func evaluateMousePosition() {
        guard isTrackingEnabled else { return }

        let mousePoint = NSEvent.mouseLocation

        // Step 1: Query the macOS Dock directly to see if cursor is resting on an icon
        let hoveredItem = DockDetector.shared.dockItem(at: mousePoint)

        if let item = hoveredItem {
            // Cursor is directly over a Dock icon
            dismissTimer?.invalidate()
            dismissTimer = nil

            if item.title == candidateItem?.title && item.processIdentifier == candidateItem?.processIdentifier {
                // Still hovering over the same candidate
                return
            }

            // Switched to a new dock icon!
            candidateItem = item
            hoverTimer?.invalidate()

            // If a preview is already open on screen, switch between dock icons instantly (50ms)
            let delay = PreviewPanel.shared.isVisible ? 0.05 : SettingsManager.shared.hoverDelay
            hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.triggerPreview(for: item)
            }
            return
        }

        // Step 2: If NOT on any Dock icon, check if cursor is inside the open preview panel
        if PreviewPanel.shared.isVisible && PreviewPanel.shared.frame.contains(mousePoint) {
            // User is interacting with window cards / controls inside preview panel
            dismissTimer?.invalidate()
            dismissTimer = nil
            return
        }

        // Step 3: Mouse is neither on a Dock icon nor inside the preview panel
        cancelHover()

        if PreviewPanel.shared.isVisible && dismissTimer == nil {
            let delay = SettingsManager.shared.dismissDelay
            dismissTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                PreviewPanel.shared.hide(animated: true)
                self?.dismissTimer = nil
            }
        }
    }

    private func cancelHover() {
        candidateItem = nil
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    private func triggerPreview(for item: DockItem) {
        guard let pid = item.processIdentifier,
              let app = NSRunningApplication(processIdentifier: pid) else {
            PreviewPanel.shared.show(dockItem: item, windows: [])
            return
        }

        Task { @MainActor in
            let windows = await WindowEngine.shared.fetchWindows(for: app)
            let displayWindows = SettingsManager.shared.showMinimizedWindows ? windows : windows.filter { !$0.isMinimized }

            self.activeHoveredItem = item
            PreviewPanel.shared.show(dockItem: item, windows: displayWindows)
        }
    }

    public func simulatePreviewForFrontmostApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let item = DockItem(
                title: frontApp.localizedName ?? "Active App",
                bundleIdentifier: frontApp.bundleIdentifier,
                processIdentifier: frontApp.processIdentifier,
                screenBounds: CGRect(x: 200, y: 50, width: 64, height: 64),
                icon: frontApp.icon,
                isRunning: true
            )
            triggerPreview(for: item)
        }
    }
}
