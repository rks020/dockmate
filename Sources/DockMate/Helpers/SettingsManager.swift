import Foundation
import SwiftUI
import Combine

public enum PreviewSize: String, CaseIterable, Identifiable {
    case small = "Küçük (150px)"
    case medium = "Orta (180px)"
    case large = "Büyük (220px)"

    public var id: String { rawValue }

    public var width: CGFloat {
        switch self {
        case .small: return 150
        case .medium: return 180
        case .large: return 220
        }
    }

    public var height: CGFloat {
        switch self {
        case .small: return 95
        case .medium: return 114
        case .large: return 138
        }
    }
}

public class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    @AppStorage("previewSize") public var previewSizeRaw: String = PreviewSize.medium.rawValue
    @AppStorage("hoverDelay") public var hoverDelay: Double = 0.15
    @AppStorage("dismissDelay") public var dismissDelay: Double = 0.20
    @AppStorage("showMinimizedWindows") public var showMinimizedWindows: Bool = true
    @AppStorage("showWindowTitles") public var showWindowTitles: Bool = true
    @AppStorage("enableMediaControls") public var enableMediaControls: Bool = true
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("showAppIconBadge") public var showAppIconBadge: Bool = true
    @AppStorage("windowLimit") public var windowLimit: Int = 8

    public var previewSize: PreviewSize {
        get {
            // Support migration from old raw values
            if previewSizeRaw.contains("300") || previewSizeRaw.contains("Orta") {
                return .medium
            } else if previewSizeRaw.contains("Küçük") {
                return .small
            } else if previewSizeRaw.contains("Büyük") {
                return .large
            }
            return PreviewSize(rawValue: previewSizeRaw) ?? .medium
        }
        set { previewSizeRaw = newValue.rawValue }
    }

    private init() {}
}
