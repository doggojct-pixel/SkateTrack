// [協作區] SlideToEndSessionControl.swift
// 用途：提供騎乘中防誤觸的滑動結束 Session 控制，達 85% 才觸發結束。
// 委派至：LiveHUDView 呼叫 useSessionRecording.actions.requestEndSession。

import SwiftUI

struct SlideToEndSessionControl: View {
    let accentColor: Color
    let isDisabled: Bool
    let onEnd: () -> Void

    @State private var dragProgress: CGFloat = 0
    @State private var hasTriggeredEnd = false

    var body: some View {
        GeometryReader { proxy in
            let thumbSize: CGFloat = 52
            let availableWidth = max(1, proxy.size.width - thumbSize - 12)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(SkateTrackSessionStartColors.card.opacity(0.92))
                    .overlay(Capsule().stroke(accentColor.opacity(0.22), lineWidth: 1))

                HStack {
                    Spacer()
                    Text("session.hud.slideToEnd")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    Spacer()

                    HStack(spacing: -2) {
                        Text("›")
                        Text("›")
                        Text("›")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .padding(.trailing, 18)
                }
                .opacity(isDisabled ? 0.45 : 1)

                Capsule()
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 12 + dragProgress * availableWidth + thumbSize, height: 62)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentColor.opacity(0.55), radius: 14, x: 0, y: 4)

                    Image(systemName: "stop.fill")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: 6 + dragProgress * availableWidth)
                .gesture(dragGesture(availableWidth: availableWidth))
                .allowsHitTesting(!isDisabled)
            }
        }
        .frame(height: 62)
        .accessibilityIdentifier("live-hud-slide-to-end")
    }

    private func dragGesture(availableWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isDisabled, !hasTriggeredEnd else { return }
                let progress = value.translation.width / availableWidth
                dragProgress = max(0, min(1, progress))
            }
            .onEnded { _ in
                guard !isDisabled, !hasTriggeredEnd else { return }

                if dragProgress >= 0.85 {
                    hasTriggeredEnd = true
                    onEnd()
                }

                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    dragProgress = 0
                }
            }
    }
}

#Preview("Slide End") {
    SlideToEndSessionControl(
        accentColor: SkateTrackSessionStartColors.accent,
        isDisabled: false,
        onEnd: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
