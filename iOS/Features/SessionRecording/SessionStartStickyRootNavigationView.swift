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
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            rootNavigationAccessory
                .padding(.horizontal, 20)
                .padding(.top, topInset + SessionStartScrollMetrics.stickyNavigationContentTopSpacing)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(stickyBackground)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -16)
                .allowsHitTesting(isVisible)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.18), value: isVisible)
        .accessibilityHidden(!isVisible)
        .accessibilityIdentifier("session-start-sticky-root-navigation")
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
