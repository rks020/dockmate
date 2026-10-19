import AppKit
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as background accessory application (Menu Bar / Agent)
        NSApp.setActivationPolicy(.accessory)

        // Initialize core services
        _ = PermissionManager.shared
        _ = DockDetector.shared
        _ = WindowEngine.shared
        _ = MediaController.shared
        _ = StatusMenuController.shared

        // Start tracking
        DockTracker.shared.startTracking()

        // If Accessibility permission is not yet granted, present setup onboarding
        if !PermissionManager.shared.isAccessibilityGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                StatusMenuController.shared.openOnboarding()
            }
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        DockTracker.shared.stopTracking()
        PreviewPanel.shared.hide(animated: false)
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        StatusMenuController.shared.openPreferences()
        return true
    }
}
