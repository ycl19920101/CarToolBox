//
//  VisibilityTracker.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI

// MARK: - View Frame Preference Key

struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Frame Tracker View Extension

extension View {
    /// Tracks the frame of a view in global coordinates and reports it via preference
    func trackFrame(id: String) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewFramePreferenceKey.self,
                    value: [id: geometry.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - Visibility Calculator

struct VisibilityCalculator {
    /// Calculate the distance from a rect to the screen center
    static func distanceToScreenCenter(_ rect: CGRect, screenHeight: CGFloat) -> CGFloat {
        let screenCenterY = screenHeight / 2
        let rectCenterY = rect.midY
        return abs(rectCenterY - screenCenterY)
    }

    /// Check if a rect is visible on screen
    static func isVisible(_ rect: CGRect, screenHeight: CGFloat) -> Bool {
        let visibleRange: ClosedRange<CGFloat> = -rect.height...screenHeight + rect.height
        return visibleRange.contains(rect.midY)
    }

    /// Find the closest visible view to the screen center
    static func findClosestToCenter(
        frames: [String: CGRect],
        screenHeight: CGFloat
    ) -> String? {
        var closestId: String?
        var minDistance: CGFloat = .infinity

        for (id, frame) in frames {
            guard isVisible(frame, screenHeight: screenHeight) else { continue }
            let distance = distanceToScreenCenter(frame, screenHeight: screenHeight)
            if distance < minDistance {
                minDistance = distance
                closestId = id
            }
        }

        return closestId
    }
}
