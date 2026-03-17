//
//  VideoPlaybackManager.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI
import AVKit
import Combine

@MainActor
class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()

    @Published var currentPlayingPostId: String?
    @Published var currentPlayer: AVPlayer?
    @Published var isMuted: Bool = true

    private var looperObserver: NSObjectProtocol?

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

            // Setup loop playback
            setupLoopPlayback(for: player)
        }
    }

    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        currentPlayer?.isMuted = isMuted
    }

    /// Stop the currently playing video
    func stopCurrentVideo() {
        currentPlayer?.pause()
        currentPlayer?.replaceCurrentItem(with: nil)
        currentPlayer = nil
        currentPlayingPostId = nil

        // Remove loop observer
        if let observer = looperObserver {
            NotificationCenter.default.removeObserver(observer)
            looperObserver = nil
        }
    }

    /// Pause the currently playing video (without clearing it)
    func pauseCurrentVideo() {
        currentPlayer?.pause()
    }

    /// Resume playing the current video
    func resumeCurrentVideo() {
        currentPlayer?.play()
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
}
