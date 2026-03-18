//
//  VideoPlayerOverlayView.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI
import CoreMedia

struct VideoPlayerOverlayView: View {
    @ObservedObject var playbackManager: VideoPlaybackManager
    let onBack: () -> Void
    let onMore: () -> Void

    @State private var isControlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Tap area to toggle controls visibility
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleControls()
                }

            if isControlsVisible {
                // Top bar
                VStack {
                    HStack {
                        // Back button
                        Button(action: {
                            playbackManager.stopCurrentVideo()
                            onBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }

                        Spacer()

                        // More button
                        Button(action: onMore) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Bottom controls
                    VStack(spacing: 12) {
                        // Play/Pause and Mute buttons
                        HStack(spacing: 24) {
                            // Play/Pause button
                            Button(action: {
                                playbackManager.togglePlayPause()
                            }) {
                                Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }

                            // Mute button
                            Button(action: {
                                playbackManager.toggleMute()
                            }) {
                                Image(systemName: playbackManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }

                            Spacer()

                            // Time labels
                            Text(formatTime(playbackManager.playbackTime))
                                .font(.caption)
                                .foregroundColor(.white)
                                .monospacedDigit()
                            Text("/")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(formatTime(playbackManager.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 16)

                        // Progress bar
                        VideoProgressSlider(
                            playbackTime: playbackManager.playbackTime,
                            duration: playbackManager.duration,
                            onSeek: { time in
                                playbackManager.seekTo(time)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }

    // MARK: - Controls Visibility

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isControlsVisible.toggle()
        }

        if isControlsVisible {
            scheduleHideControls()
        } else {
            hideControlsTask?.cancel()
        }
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isControlsVisible = false
                    }
                }
            }
        }
    }

    // MARK: - Time Formatting

    private func formatTime(_ time: CMTime) -> String {
        guard time.isValid else { return "0:00" }
        let seconds = time.seconds
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secondsRemaining = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secondsRemaining)
    }
}

// MARK: - Video Progress Slider

struct VideoProgressSlider: View {
    let playbackTime: CMTime
    let duration: CMTime
    let onSeek: (CMTime) -> Void

    @State private var isDragging = false
    @State private var dragValue: Double = 0

    private var progress: Double {
        guard duration.isValid && duration.seconds > 0 else { return 0 }
        return playbackTime.seconds / duration.seconds
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Progress track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * (isDragging ? dragValue : progress), height: 4)
                    .cornerRadius(2)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragValue = max(0, min(1, value.location.x / geometry.size.width))
                    }
                    .onEnded { value in
                        let seekProgress = max(0, min(1, value.location.x / geometry.size.width))
                        if duration.isValid {
                            let seekTime = CMTime(
                                seconds: seekProgress * duration.seconds,
                                preferredTimescale: duration.timescale
                            )
                            onSeek(seekTime)
                        }
                        isDragging = false
                    }
            )
        }
        .frame(height: 20) // Touch area height
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VideoPlayerOverlayView(
            playbackManager: VideoPlaybackManager.shared,
            onBack: {},
            onMore: {}
        )
    }
}
