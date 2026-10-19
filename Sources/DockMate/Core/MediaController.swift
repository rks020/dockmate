import AppKit
import Foundation

public class MediaController: ObservableObject {
    public static let shared = MediaController()

    @Published public var currentTrack: MediaTrackInfo?
    @Published public var isMediaAppActive: Bool = false

    private init() {
        setupNotificationObservers()
        refreshMediaStatus()
    }

    private func setupNotificationObservers() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleMusicNotification(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSpotifyNotification(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }

    @objc private func handleMusicNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let state = userInfo["Player State"] as? String ?? ""
            let name = userInfo["Name"] as? String ?? ""
            let artist = userInfo["Artist"] as? String ?? ""
            let album = userInfo["Album"] as? String ?? ""
            let isPlaying = (state == "Playing")

            DispatchQueue.main.async {
                self.currentTrack = MediaTrackInfo(
                    appName: "Music",
                    title: name,
                    artist: artist,
                    album: album,
                    isPlaying: isPlaying,
                    artwork: nil
                )
                self.isMediaAppActive = true
            }
        }
    }

    @objc private func handleSpotifyNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let state = userInfo["Player State"] as? String ?? ""
            let name = userInfo["Name"] as? String ?? ""
            let artist = userInfo["Artist"] as? String ?? ""
            let album = userInfo["Album"] as? String ?? ""
            let isPlaying = (state == "Playing" || state == "kPSP")

            DispatchQueue.main.async {
                self.currentTrack = MediaTrackInfo(
                    appName: "Spotify",
                    title: name,
                    artist: artist,
                    album: album,
                    isPlaying: isPlaying,
                    artwork: nil
                )
                self.isMediaAppActive = true
            }
        }
    }

    /// Checks if Music or Spotify is running and queries its current state.
    public func refreshMediaStatus() {
        let isMusicRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
        let isSpotifyRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty

        if isMusicRunning {
            queryMusicStatus()
        } else if isSpotifyRunning {
            querySpotifyStatus()
        } else {
            DispatchQueue.main.async {
                self.isMediaAppActive = false
                self.currentTrack = nil
            }
        }
    }

    private func queryMusicStatus() {
        let script = """
        tell application "Music"
            set s to player state as string
            set t to name of current track
            set a to artist of current track
            set al to album of current track
            return s & "|||" & t & "|||" & a & "|||" & al
        end tell
        """
        runAppleScript(script) { result in
            guard let result = result else { return }
            let parts = result.components(separatedBy: "|||")
            if parts.count >= 4 {
                let isPlaying = (parts[0].lowercased() == "playing")
                DispatchQueue.main.async {
                    self.currentTrack = MediaTrackInfo(
                        appName: "Music",
                        title: parts[1],
                        artist: parts[2],
                        album: parts[3],
                        isPlaying: isPlaying
                    )
                    self.isMediaAppActive = true
                }
            }
        }
    }

    private func querySpotifyStatus() {
        let script = """
        tell application "Spotify"
            set s to player state as string
            set t to name of current track
            set a to artist of current track
            set al to album of current track
            return s & "|||" & t & "|||" & a & "|||" & al
        end tell
        """
        runAppleScript(script) { result in
            guard let result = result else { return }
            let parts = result.components(separatedBy: "|||")
            if parts.count >= 4 {
                let isPlaying = (parts[0].lowercased() == "playing")
                DispatchQueue.main.async {
                    self.currentTrack = MediaTrackInfo(
                        appName: "Spotify",
                        title: parts[1],
                        artist: parts[2],
                        album: parts[3],
                        isPlaying: isPlaying
                    )
                    self.isMediaAppActive = true
                }
            }
        }
    }

    // MARK: - Playback Controls

    public func togglePlayPause() {
        guard let track = currentTrack else { return }
        let script = """
        tell application "\(track.appName)" to playpause
        """
        runAppleScript(script) { [weak self] _ in
            self?.refreshMediaStatus()
        }
    }

    public func nextTrack() {
        guard let track = currentTrack else { return }
        let script = """
        tell application "\(track.appName)" to next track
        """
        runAppleScript(script) { [weak self] _ in
            self?.refreshMediaStatus()
        }
    }

    public func previousTrack() {
        guard let track = currentTrack else { return }
        let script = """
        tell application "\(track.appName)" to previous track
        """
        runAppleScript(script) { [weak self] _ in
            self?.refreshMediaStatus()
        }
    }

    private func runAppleScript(_ source: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: source) {
                let output = appleScript.executeAndReturnError(&error)
                if error == nil {
                    completion(output.stringValue)
                    return
                }
            }
            completion(nil)
        }
    }
}
