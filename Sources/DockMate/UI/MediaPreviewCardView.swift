import SwiftUI
import AppKit

public struct MediaPreviewCardView: View {
    @ObservedObject var mediaController: MediaController
    public let onOpenApp: () -> Void

    public init(mediaController: MediaController = .shared, onOpenApp: @escaping () -> Void) {
        self.mediaController = mediaController
        self.onOpenApp = onOpenApp
    }

    public var body: some View {
        if let track = mediaController.currentTrack {
            VStack(spacing: 12) {
                // Header: App name badge
                HStack {
                    Image(systemName: track.appName == "Music" ? "music.note" : "dot.radiowaves.left.and.right")
                        .foregroundColor(track.appName == "Music" ? .red : .green)
                    Text(track.appName == "Music" ? "Apple Music" : "Spotify")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if track.isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(track.appName == "Music" ? Color.red : Color.green)
                                    .frame(width: 2.5, height: CGFloat([8, 14, 10][i]))
                            }
                        }
                    }
                }

                // Track & Artist info
                HStack(spacing: 12) {
                    // Artwork / Icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)

                        Image(systemName: "music.note")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(track.artist)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if !track.album.isEmpty {
                            Text(track.album)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }

                // Playback Controls
                HStack(spacing: 16) {
                    Button(action: { mediaController.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)

                    Button(action: { mediaController.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 32, height: 32)
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(nsColor: .windowBackgroundColor))
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { mediaController.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
            .padding(14)
            .frame(width: 280)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .onTapGesture {
                onOpenApp()
            }
        }
    }
}
