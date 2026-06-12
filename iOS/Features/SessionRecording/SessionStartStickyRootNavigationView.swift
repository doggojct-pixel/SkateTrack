// [協作區] SessionStartStickyRootNavigationView.swift
// 用途：提供 Session Start 內的浮動 root navigation 行為，讓滑行頁上方分頁在下滑後固定於安全區下方。
// 委派至：SessionStartView 提供滾動狀態；RootNavigationView 提供實際分頁控制。

import SwiftUI

enum SessionStartScrollMetrics {
    static let coordinateSpaceName = "session-start-scroll-space"
    static let stickyNavigationFallbackThreshold: CGFloat = -28
    static let stickyNavigationActivationPadding: CGFloat = 8
    static let minimumStickyNavigationTopInset: CGFloat = 58
    static let stickyNavigationContentTopSpacing: CGFloat = 10
    static let stickyNavigationBackgroundFadeDistance: CGFloat = 22
}

struct SessionStartScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SessionStartNavigationPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

struct SessionStartStickyRootNavigationView: View {
    let rootNavigationAccessory: AnyView
    let topInset: CGFloat
    let navigationRowMinY: CGFloat
    let isMeasured: Bool
    let isPinned: Bool

    var body: some View {
        VStack(spacing: 0) {
            rootNavigationAccessory
                .padding(.horizontal, 20)
                .padding(.top, displayedTopPosition)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(stickyBackground.opacity(stickyBackgroundOpacity))
                .opacity(isMeasured ? 1 : 0)
                .allowsHitTesting(isMeasured)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.interactiveSpring(response: 0.20, dampingFraction: 0.88), value: displayedTopPosition)
        .animation(.easeInOut(duration: 0.16), value: stickyBackgroundOpacity)
        .accessibilityHidden(!isMeasured)
        .accessibilityIdentifier("session-start-sticky-root-navigation")
    }

    private var pinnedTopPosition: CGFloat {
        topInset + SessionStartScrollMetrics.stickyNavigationContentTopSpacing
    }

    private var displayedTopPosition: CGFloat {
        guard isMeasured else { return pinnedTopPosition }
        return max(navigationRowMinY, pinnedTopPosition)
    }

    private var stickyBackgroundOpacity: Double {
        guard isMeasured else { return 0 }
        guard !isPinned else { return 1 }
        let distanceFromPinnedTop = navigationRowMinY - pinnedTopPosition
        let fadeDistance = SessionStartScrollMetrics.stickyNavigationBackgroundFadeDistance
        let progress = 1 - min(max(distanceFromPinnedTop / fadeDistance, 0), 1)
        return Double(progress)
    }

    private var stickyBackground: some View {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.navy3.opacity(0.98),
                SkateTrackSessionStartColors.navy2.opacity(0.90),
                SkateTrackSessionStartColors.navy.opacity(0.18),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }
}
