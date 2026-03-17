//
//  ImageViewerView.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI

struct ImageViewerView: View {
    let images: [MediaDTO]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0

    init(images: [MediaDTO], initialIndex: Int = 0) {
        self.images = images
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Top bar with close button and counter
                HStack {
                    Spacer()

                    Text("\(currentIndex + 1)/\(images.count)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                Spacer()

                // Image viewer with TabView for swiping
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, media in
                        ZoomableImageView(urlString: media.fullURL)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()
            }
        }
    }
}

// MARK: - Zoomable Image View

struct ZoomableImageView: View {
    let urlString: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = lastScale * value
                                        scale = min(max(newScale, 1), 4) // Limit scale between 1x and 4x
                                    }
                                    .onEnded { _ in
                                        lastScale = scale

                                        // Reset if too small
                                        if scale < 1 {
                                            withAnimation {
                                                scale = 1
                                                lastScale = 1
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            let newOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            offset = limitOffset(newOffset, in: geometry.size)
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to toggle zoom
                            withAnimation {
                                if scale > 1 {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                    lastScale = 2
                                }
                            }
                        }
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("加载失败")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .empty:
                    ProgressView()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                @unknown default:
                    ProgressView()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func limitOffset(_ newOffset: CGSize, in size: CGSize) -> CGSize {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        return CGSize(
            width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
        )
    }
}

#Preview {
    ImageViewerView(images: [
        MediaDTO(type: "image", url: "https://picsum.photos/800/600"),
        MediaDTO(type: "image", url: "https://picsum.photos/800/600")
    ])
}
