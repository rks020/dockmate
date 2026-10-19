import AppKit

public enum DockOrientation: String {
    case bottom
    case left
    case right
}

public struct GeometryHelpers {
    /// Converts a point or rect from Accessibility (top-left origin) to Cocoa (bottom-left origin) coordinates.
    public static func axRectToCocoaRect(_ axRect: CGRect, in screen: NSScreen = NSScreen.screens.first ?? NSScreen.main!) -> CGRect {
        let screenHeight = screen.frame.height
        let cocoaY = screenHeight - axRect.origin.y - axRect.size.height
        return CGRect(x: axRect.origin.x, y: cocoaY, width: axRect.size.width, height: axRect.size.height)
    }

    /// Converts Cocoa point to Quartz/AX point.
    public static func cocoaPointToAXPoint(_ cocoaPoint: CGPoint, in screen: NSScreen = NSScreen.screens.first ?? NSScreen.main!) -> CGPoint {
        let screenHeight = screen.frame.height
        return CGPoint(x: cocoaPoint.x, y: screenHeight - cocoaPoint.y)
    }

    /// Reads system Dock orientation from defaults or screen insets.
    public static func getDockOrientation() -> DockOrientation {
        if let orientation = UserDefaults(suiteName: "com.apple.dock")?.string(forKey: "orientation") {
            if orientation == "left" { return .left }
            if orientation == "right" { return .right }
        }
        // Fallback: inspect visibleFrame difference with screen frame
        guard let screen = NSScreen.main else { return .bottom }
        let full = screen.frame
        let visible = screen.visibleFrame
        if visible.origin.x > full.origin.x { return .left }
        if visible.width < full.width && visible.origin.x == full.origin.x { return .right }
        return .bottom
    }

    /// Computes the optimal origin for the floating preview panel given the dock item and content size.
    public static func calculatePanelOrigin(
        dockItemScreenBounds: CGRect,
        panelSize: CGSize,
        orientation: DockOrientation = .bottom,
        screen: NSScreen = NSScreen.main ?? NSScreen.screens.first!
    ) -> CGPoint {
        let visibleFrame = screen.visibleFrame
        let margin: CGFloat = 10.0

        var targetX: CGFloat = 0
        var targetY: CGFloat = 0

        switch orientation {
        case .bottom:
            // Centered horizontally over the dock icon
            targetX = dockItemScreenBounds.midX - (panelSize.width / 2.0)
            // Positioned right above the dock icon
            targetY = dockItemScreenBounds.maxY + margin

            // Clamp horizontally to stay within the visible screen
            let minX = visibleFrame.minX + 16.0
            let maxX = visibleFrame.maxX - panelSize.width - 16.0
            targetX = max(minX, min(targetX, maxX))

            // Ensure not overflowing top
            if targetY + panelSize.height > visibleFrame.maxY {
                targetY = visibleFrame.maxY - panelSize.height - margin
            }

        case .left:
            targetX = dockItemScreenBounds.maxX + margin
            targetY = dockItemScreenBounds.midY - (panelSize.height / 2.0)

            let minY = visibleFrame.minY + 16.0
            let maxY = visibleFrame.maxY - panelSize.height - 16.0
            targetY = max(minY, min(targetY, maxY))

        case .right:
            targetX = dockItemScreenBounds.minX - panelSize.width - margin
            targetY = dockItemScreenBounds.midY - (panelSize.height / 2.0)

            let minY = visibleFrame.minY + 16.0
            let maxY = visibleFrame.maxY - panelSize.height - 16.0
            targetY = max(minY, min(targetY, maxY))
        }

        return CGPoint(x: targetX, y: targetY)
    }
}
