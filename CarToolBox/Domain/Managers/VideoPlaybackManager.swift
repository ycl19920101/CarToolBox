//
//  VideoPlaybackManager.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI
import AVKit
import Combine
import CoreMedia

@MainActor
class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()

    @Published var currentPlayingPostId: String?
    @Published var currentPlayer: AVPlayer?
    @Published var isMuted: Bool = true
    @Published var playbackTime: CMTime = .zero
    @Published var duration: CMTime = .zero
    @Published var isPlaying: Bool = false

    private var looperObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// Play video for a specific post
    /// - Parameters:
    ///   - postId: The post identifier
    ///   - url: The video URL
    func playVideo(postId: String, url: URL) {
        // Stop current video if playing a different one
        if currentPlayingPostId != postId {
            stopCurrentVideo()

            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            currentPlayer = player
            currentPlayingPostId = postId

            // Start playback
            player.play()
            isPlaying = true

            // Setup loop playback
            setupLoopPlayback(for: player)

            // Setup time observer
            setupTimeObserver(for: player)
        }
    }

    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        currentPlayer?.isMuted = isMuted
    }

    /// Stop the currently playing video
    func stopCurrentVideo() {
        // Remove time observer before clearing player
        if let observer = timeObserver, let player = currentPlayer {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Remove loop observer
        if let observer = looperObserver {
            NotificationCenter.default.removeObserver(observer)
            looperObserver = nil
        }

        currentPlayer?.pause()
        currentPlayer?.replaceCurrentItem(with: nil)
        currentPlayer = nil
        currentPlayingPostId = nil
        isPlaying = false
        playbackTime = .zero
        duration = .zero
    }

    /// Pause the currently playing video (without clearing it)
    func pauseCurrentVideo() {
        currentPlayer?.pause()
        isPlaying = false
    }

    /// Resume playing the current video
    func resumeCurrentVideo() {
        currentPlayer?.play()
        isPlaying = true
    }

    /// Seek to a specific time
    func seekTo(_ time: CMTime) {
        currentPlayer?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pauseCurrentVideo()
        } else {
            resumeCurrentVideo()
        }
    }

    /// Check if a specific post is currently playing
    func isPlaying(postId: String) -> Bool {
        return currentPlayingPostId == postId
    }

    // MARK: - Private Methods

    private func setupLoopPlayback(for player: AVPlayer) {
        // Remove previous observer
        if let observer = looperObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Add observer for video end to loop
        looperObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private func setupTimeObserver(for player: AVPlayer) {
        // Remove previous time observer
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
        }

        // Add periodic time observer (every 0.1 seconds)
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.playbackTime = time
        }

        // Observe duration changes
        player.publisher(for: \.currentItem?.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                if let duration = duration, duration.isValid {
                    self?.duration = duration
                }
            }
            .store(in: &cancellables)
    }
}
