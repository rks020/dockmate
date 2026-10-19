import AppKit

/// Represents track information for Apple Music or Spotify.
public struct MediaTrackInfo: Equatable {
    public var appName: String      // "Music" or "Spotify"
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var duration: Double
    public var playerPosition: Double
    public var artwork: NSImage?

    public init(
        appName: String = "Music",
        title: String = "",
        artist: String = "",
        album: String = "",
        isPlaying: Bool = false,
        duration: Double = 0,
        playerPosition: Double = 0,
        artwork: NSImage? = nil
    ) {
        self.appName = appName
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.duration = duration
        self.playerPosition = playerPosition
        self.artwork = artwork
    }

    public static func == (lhs: MediaTrackInfo, rhs: MediaTrackInfo) -> Bool {
        return lhs.appName == rhs.appName &&
               lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.album == rhs.album &&
               lhs.isPlaying == rhs.isPlaying
    }
}
