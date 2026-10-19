import AppKit
import ApplicationServices
import ScreenCaptureKit

/// Represents an application window on macOS.
public struct WindowInfo: Identifiable, Equatable {
    public let id: CGWindowID
    public var title: String
    public var appName: String
    public var bundleIdentifier: String?
    public var owningPID: pid_t
    public var bounds: CGRect
    public var isMinimized: Bool
    public var isOnScreen: Bool
    public var axWindowElement: AXUIElement?
    public var scWindow: SCWindow?
    public var thumbnail: NSImage?
    public var appIcon: NSImage?

    public init(
        id: CGWindowID,
        title: String,
        appName: String,
        bundleIdentifier: String? = nil,
        owningPID: pid_t = 0,
        bounds: CGRect = .zero,
        isMinimized: Bool = false,
        isOnScreen: Bool = true,
        axWindowElement: AXUIElement? = nil,
        scWindow: SCWindow? = nil,
        thumbnail: NSImage? = nil,
        appIcon: NSImage? = nil
    ) {
        self.id = id
        self.title = title
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.owningPID = owningPID
        self.bounds = bounds
        self.isMinimized = isMinimized
        self.isOnScreen = isOnScreen
        self.axWindowElement = axWindowElement
        self.scWindow = scWindow
        self.thumbnail = thumbnail
        self.appIcon = appIcon
    }

    public static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isMinimized == rhs.isMinimized &&
               lhs.isOnScreen == rhs.isOnScreen
    }
}
