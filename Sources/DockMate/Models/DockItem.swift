import AppKit
import ApplicationServices

/// Represents an item present on the macOS Dock.
public struct DockItem: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public var bundleIdentifier: String?
    public var processIdentifier: pid_t?
    public var screenBounds: CGRect // Cocoa coordinates (bottom-left origin)
    public var axBounds: CGRect     // AX coordinates (top-left origin)
    public var axElement: AXUIElement?
    public var icon: NSImage?
    public var isRunning: Bool
    public var isFolder: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        bundleIdentifier: String? = nil,
        processIdentifier: pid_t? = nil,
        screenBounds: CGRect = .zero,
        axBounds: CGRect = .zero,
        axElement: AXUIElement? = nil,
        icon: NSImage? = nil,
        isRunning: Bool = false,
        isFolder: Bool = false
    ) {
        self.id = id
        self.title = title
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.screenBounds = screenBounds
        self.axBounds = axBounds
        self.axElement = axElement
        self.icon = icon
        self.isRunning = isRunning
        self.isFolder = isFolder
    }

    public static func == (lhs: DockItem, rhs: DockItem) -> Bool {
        return lhs.title == rhs.title &&
               lhs.bundleIdentifier == rhs.bundleIdentifier &&
               lhs.processIdentifier == rhs.processIdentifier &&
               lhs.screenBounds.equalTo(rhs.screenBounds)
    }
}
