// [協作區] BoardModeSelectorView.swift
// 用途：顯示四種滑板模式卡片，供 SessionStartView 選擇 SportMode.skateboard。
// 委派至：ModeSelectionCardView 呈現共用卡片視覺。

import SwiftUI

struct BoardModeSelectorView: View {
    @Binding var selectedMode: BoardMode
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(BoardMode.allCases, id: \.self) { mode in
                    ModeSelectionCardView(
                        titleKey: mode.localizationKey,
                        descriptionKey: mode.descriptionKey,
                        tagKey: mode.primaryTagKey,
                        iconName: mode.iconName,
                        accentColor: mode.accentColor,
                        isSelected: selectedMode == mode,
                        isLocked: false,
                        onTap: { selectedMode = mode }
                    )
                    .accessibilityIdentifier("board-mode-\(mode.rawValue)")
                }
            }
        }
    }

    private var sectionTitle: some View {
        HStack {
            Text("sport.skateboard")
                .tracking(2)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer()
            Text("session.start.skateboard.subtitle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
    }
}

extension BoardMode {
    var descriptionKey: String {
        switch self {
        case .streetPark:
            return "mode.description.streetpark"
        case .longboard:
            return "mode.description.longboard"
        case .surfskate:
            return "mode.description.surfskate"
        case .freebord:
            return "mode.description.freebord"
        }
    }

    var primaryTagKey: String {
        switch self {
        case .streetPark:
            return "mode.tag.tricks"
        case .longboard:
            return "mode.tag.speed"
        case .surfskate:
            return "mode.tag.pump"
        case .freebord:
            return "mode.tag.carve"
        }
    }

    var iconName: String {
        switch self {
        case .streetPark:
            return "figure.skateboarding"
        case .longboard:
            return "arrow.left.and.right"
        case .surfskate:
            return "waveform.path"
        case .freebord:
            return "rotate.3d"
        }
    }

    var accentColor: Color {
        switch self {
        case .streetPark:
            return SkateTrackSessionStartColors.accent
        case .longboard:
            return SkateTrackSessionStartColors.teal
        case .surfskate:
            return SkateTrackSessionStartColors.blueCold
        case .freebord:
            return SkateTrackSessionStartColors.purple
        }
    }
}

#Preview("Board Modes") {
    BoardModeSelectorView(
        selectedMode: .constant(.streetPark),
        accentColor: SkateTrackSessionStartColors.accent
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
