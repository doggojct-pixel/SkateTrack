// [協作區] SnowDisciplineSelectorView.swift
// 用途：在正式 Session Start 流程中選擇 Snow Mode 的 snowboard / skiing 子類型。
// 委派至：SessionStartView 產生 SportMode.snow；後續 Snow-Task-005 會接上正式 Snow HUD。

import SwiftUI

struct SnowDisciplineSelectorView: View {
    @Binding var selectedDiscipline: SnowDiscipline
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(SnowDiscipline.allCases, id: \.self) { discipline in
                    ModeSelectionCardView(
                        titleKey: discipline.localizationKey,
                        descriptionKey: discipline.descriptionKey,
                        tagKey: discipline.primaryTagKey,
                        iconName: discipline.iconName,
                        accentColor: discipline.accentColor,
                        isSelected: selectedDiscipline == discipline,
                        isLocked: false,
                        onTap: { selectedDiscipline = discipline }
                    )
                    .accessibilityIdentifier("snow-discipline-\(discipline.rawValue)")
                }
            }
        }
    }

    private var sectionTitle: some View {
        HStack {
            Text("snow.sport.title")
                .tracking(2)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer()
            Text("session.start.snow.subtitle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
    }
}

extension SnowDiscipline {
    var descriptionKey: String {
        switch self {
        case .snowboard:
            return "mode.description.snow.snowboard"
        case .skiing:
            return "mode.description.snow.skiing"
        }
    }

    var primaryTagKey: String {
        switch self {
        case .snowboard:
            return "mode.tag.snowboard"
        case .skiing:
            return "mode.tag.skiing"
        }
    }

    var iconName: String {
        switch self {
        case .snowboard:
            return "snowflake"
        case .skiing:
            return "figure.skiing.downhill"
        }
    }

    var accentColor: Color {
        switch self {
        case .snowboard:
            return SkateTrackSessionStartColors.ice
        case .skiing:
            return SkateTrackSessionStartColors.mint
        }
    }
}

#Preview("Snow Disciplines") {
    SnowDisciplineSelectorView(
        selectedDiscipline: .constant(.snowboard),
        accentColor: SkateTrackSessionStartColors.ice
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
