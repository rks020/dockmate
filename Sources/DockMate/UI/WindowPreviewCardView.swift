import SwiftUI
import AppKit

public struct WindowPreviewCardView: View {
    public let window: WindowInfo
    public let previewSize: PreviewSize
    public let onSelect: (WindowInfo) -> Void
    public let onClose: (WindowInfo) -> Void
    public let onMinimize: (WindowInfo) -> Void

    @State private var isHovered: Bool = false

    public init(
        window: WindowInfo,
        previewSize: PreviewSize,
        onSelect: @escaping (WindowInfo) -> Void,
        onClose: @escaping (WindowInfo) -> Void,
        onMinimize: @escaping (WindowInfo) -> Void
    ) {
        self.window = window
        self.previewSize = previewSize
        self.onSelect = onSelect
        self.onClose = onClose
        self.onMinimize = onMinimize
    }

    public var body: some View {
        VStack(spacing: 4) {
            // Preview Thumbnail Container
            ZStack(alignment: .topTrailing) {
                // Window image / mockup
                if let thumbnail = window.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: previewSize.width, height: previewSize.height)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                        .frame(width: previewSize.width, height: previewSize.height)
                        .overlay {
                            VStack(spacing: 4) {
                                if let icon = window.appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                                Text(window.title)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 6)
                            }
                        }
                }

                // Minimized badge if applicable
                if window.isMinimized {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 8, weight: .bold))
                        Text("Küçültülmüş")
                            .font(.system(size: 8.5, weight: .medium))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundColor(.white)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                // Quick action buttons overlay on hover
                if isHovered {
                    HStack(spacing: 5) {
                        // Minimize button
                        Button(action: { onMinimize(window) }) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Image(systemName: "minus")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(Color.black.opacity(0.7))
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Simge Durumuna Küçült")

                        // Close button
                        Button(action: { onClose(window) }) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(Color.black.opacity(0.7))
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Pencereyi Kapat")
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .padding(5)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.accentColor : Color.white.opacity(0.12), lineWidth: isHovered ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.3 : 0.12), radius: isHovered ? 6 : 3, x: 0, y: isHovered ? 3 : 1)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)

            // Window Title
            Text(window.title.isEmpty ? window.appName : window.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovered ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: previewSize.width)
        }
        .padding(2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(window)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
