// [協作區] InlineModeSelectorView.swift
// 用途：顯示四種直排輪模式與訂閱鎖定狀態。
// 委派至：useSubscriptionStatus 判斷付費模式是否可開始。

import SwiftUI

struct InlineModeSelectorView: View {
    @Binding var selectedMode: InlineMode
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel

    let accentColor: Color
    let onLockedModeTap: (GatedFeature) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(InlineMode.allCases, id: \.self) { mode in
                    let feature = mode.gatedFeature
                    let locked = feature.map { !subscriptionStatus.hasAccess(to: $0) } ?? false

                    ModeSelectionCardView(
                        titleKey: mode.localizationKey,
                        descriptionKey: mode.descriptionKey,
                        tagKey: mode.primaryTagKey,
                        iconName: mode.iconName,
                        accentColor: mode.accentColor,
                        isSelected: selectedMode == mode,
                        isLocked: locked,
                        onTap: {
                            selectedMode = mode
                            if let feature, locked {
                                onLockedModeTap(feature)
                            }
                        }
                    )
                    .accessibilityIdentifier("inline-mode-\(mode.rawValue)")
                }
            }
        }
    }

    private var sectionTitle: some View {
        HStack {
            Text("sport.inline")
                .tracking(2)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer()
            Text("session.start.inline.subtitle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
    }
}

extension InlineMode {
    var gatedFeature: GatedFeature? {
        switch self {
        case .urbanFreestyle:
            return nil
        case .fitnessSpeed:
            return .inlineFitnessMode
        case .aggressive:
            return .inlineAggressiveMode
        case .slalom:
            return .inlineSlalomMode
        }
    }

    var descriptionKey: String {
        switch self {
        case .urbanFreestyle:
            return "mode.description.inline.urban"
        case .fitnessSpeed:
            return "mode.description.inline.fitness"
        case .aggressive:
            return "mode.description.inline.aggressive"
        case .slalom:
            return "mode.description.inline.slalom"
        }
    }

    var primaryTagKey: String {
        switch self {
        case .urbanFreestyle:
            return "mode.tag.cadence"
        case .fitnessSpeed:
            return "mode.tag.speed"
        case .aggressive:
            return "mode.tag.tricks"
        case .slalom:
            return "mode.tag.rhythm"
        }
    }

    var iconName: String {
        switch self {
        case .urbanFreestyle:
            return "skateTrack.inlineGlyph"
        case .fitnessSpeed:
            return "speedometer"
        case .aggressive:
            return "bolt.fill"
        case .slalom:
            return "point.3.connected.trianglepath.dotted"
        }
    }

    var accentColor: Color {
        switch self {
        case .urbanFreestyle:
            return SkateTrackSessionStartColors.purple
        case .fitnessSpeed:
            return SkateTrackSessionStartColors.teal
        case .aggressive:
            return SkateTrackSessionStartColors.accent
        case .slalom:
            return SkateTrackSessionStartColors.blueCold
        }
    }
}

#Preview("Inline Modes") {
    InlineModeSelectorView(
        selectedMode: .constant(.urbanFreestyle),
        subscriptionStatus: useSubscriptionStatus(),
        accentColor: SkateTrackSessionStartColors.purple,
        onLockedModeTap: { _ in }
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
