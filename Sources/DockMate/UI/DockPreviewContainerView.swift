import SwiftUI
import AppKit

public struct DockPreviewContainerView: View {
    public let dockItem: DockItem
    public let windows: [WindowInfo]
    public let isMediaApp: Bool
    @ObservedObject var settings: SettingsManager = .shared
    @ObservedObject var mediaController: MediaController = .shared
    @ObservedObject var permissions: PermissionManager = .shared

    public let onSelectWindow: (WindowInfo) -> Void
    public let onCloseWindow: (WindowInfo) -> Void
    public let onMinimizeWindow: (WindowInfo) -> Void
    public let onLaunchNewWindow: () -> Void
    public let onQuitApp: () -> Void

    public var body: some View {
        VStack(spacing: 6) {
            // Header Bar
            HStack(spacing: 6) {
                if let icon = dockItem.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                }

                Text(dockItem.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)

                if !windows.isEmpty {
                    Text("\(windows.count)")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.secondary.opacity(0.18), in: Capsule())
                }

                Spacer()

                // New Window Button
                Button(action: onLaunchNewWindow) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .background(Color.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Yeni Pencere Aç (Cmd+N)")

                // Quit App Button
                Button(action: onQuitApp) {
                    Image(systemName: "power")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .background(Color.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Uygulamadan Çık")
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)

            // Media Player preview if applicable
            if isMediaApp && settings.enableMediaControls && mediaController.currentTrack != nil {
                MediaPreviewCardView(mediaController: mediaController) {
                    onLaunchNewWindow()
                }
                .padding(.horizontal, 8)
            }

            // Window Cards Content
            if windows.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Açık pencere yok")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Button(action: onLaunchNewWindow) {
                        Text("Pencere Aç")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 14)
                .frame(minWidth: 160)
            } else {
                // Layout windows horizontally
                HStack(alignment: .top, spacing: 8) {
                    ForEach(windows.prefix(settings.windowLimit)) { win in
                        WindowPreviewCardView(
                            window: win,
                            previewSize: settings.previewSize,
                            onSelect: onSelectWindow,
                            onClose: onCloseWindow,
                            onMinimize: onMinimizeWindow
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }

            // Subtle permission banner if Screen Recording is not yet granted
            if !permissions.isScreenCaptureGranted {
                HStack(spacing: 6) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("Canlı ekran için Ekran Kaydı izni gerekir")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("İzin Ver") {
                        permissions.requestScreenCapture()
                    }
                    .font(.system(size: 9.5, weight: .semibold))
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 6)
    }
}
