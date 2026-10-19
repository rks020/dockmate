import AppKit
import SwiftUI

public class StatusMenuController: NSObject, NSMenuDelegate {
    public static let shared = StatusMenuController()

    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    public override init() {
        super.init()
        setupStatusItem()
    }

    public func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "DockMate") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🪟"
            }
            button.toolTip = "DockMate - macOS Dock Önizleme Aracı"
        }

        rebuildMenu()
    }

    public func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        // Title item
        let titleItem = NSMenuItem(title: "DockMate", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Status indicator
        let isTracking = DockTracker.shared.isTrackingEnabled
        let statusTitle = isTracking ? "● Durum: Aktif" : "○ Durum: Duraklatıldı"
        let statusToggle = NSMenuItem(title: statusTitle, action: #selector(toggleTracking), keyEquivalent: "s")
        statusToggle.target = self
        menu.addItem(statusToggle)

        menu.addItem(NSMenuItem.separator())

        // Test preview
        let testItem = NSMenuItem(title: "Önizleme Testini Tetikle", action: #selector(triggerTestPreview), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        // Dock refresh
        let refreshItem = NSMenuItem(title: "Dock Simgelerini Yeniden Tara", action: #selector(rescanDock), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Ayarlar...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        // Permissions wizard
        let wizardItem = NSMenuItem(title: "İzin ve Kurulum Sihirbazı...", action: #selector(openOnboarding), keyEquivalent: "")
        wizardItem.target = self
        menu.addItem(wizardItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "DockMate'den Çık", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleTracking() {
        let tracker = DockTracker.shared
        if tracker.isTrackingEnabled {
            tracker.stopTracking()
        } else {
            tracker.startTracking()
        }
        rebuildMenu()
    }

    @objc private func triggerTestPreview() {
        DockTracker.shared.simulatePreviewForFrontmostApp()
    }

    @objc private func rescanDock() {
        DockDetector.shared.refreshDockItems()
    }

    @objc public func openPreferences() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "DockMate Ayarları"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PreferencesView())
            self.preferencesWindow = window
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func openOnboarding() {
        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 490),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "DockMate Kurulum"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: OnboardingView { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            })
            self.onboardingWindow = window
        }

        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }
}
