import AppKit
import ApplicationServices
import CoreGraphics
import Combine

public class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public var isAccessibilityGranted: Bool = false
    @Published public var isScreenCaptureGranted: Bool = false

    private var pollTimer: Timer?

    private init() {
        refreshStatus()
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }

    public func refreshStatus() {
        let axTrusted = AXIsProcessTrusted()
        let scTrusted = CGPreflightScreenCaptureAccess()

        DispatchQueue.main.async {
            self.isAccessibilityGranted = axTrusted
            self.isScreenCaptureGranted = scTrusted
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    // MARK: - Accessibility

    public func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Screen Capture

    public func requestScreenCapture() {
        _ = CGRequestScreenCaptureAccess()
        openScreenCaptureSettings()
    }

    public func openScreenCaptureSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
