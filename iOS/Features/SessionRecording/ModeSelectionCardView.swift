// [協作區] ModeSelectionCardView.swift
// 用途：提供滑板與直排輪模式選擇器共用的模式卡片視覺元件。
// 委派至：BoardModeSelectorView 與 InlineModeSelectorView。

import SwiftUI

struct ModeSelectionCardView: View {
    let titleKey: String
    let descriptionKey: String
    let tagKey: String
    let iconName: String
    let accentColor: Color
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                topRow

                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isLocked ? SkateTrackSessionStartColors.textSecondary : .white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(LocalizedStringKey(descriptionKey))
                        .font(.caption2)
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 3)

                Text(LocalizedStringKey(isLocked ? "mode.locked.subscriberOnly" : tagKey))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(isLocked ? SkateTrackSessionStartColors.textTertiary : accentColor)
                    .background((isLocked ? Color.white : accentColor).opacity(isLocked ? 0.08 : 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(minHeight: 146, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(cardBorder)
            .shadow(color: accentColor.opacity(isSelected ? 0.24 : 0.0), radius: 14, x: 0, y: 0)
            .opacity(isLocked ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }

    private var topRow: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(isLocked ? SkateTrackSessionStartColors.textTertiary : accentColor)
                .frame(width: 34, height: 34)

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .accessibilityLabel(Text("mode.locked.subscriberOnly"))
            } else if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(accentColor)
                    .clipShape(Circle())
            }
        }
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.card,
                isSelected ? accentColor.opacity(0.16) : SkateTrackSessionStartColors.navy3.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                isSelected ? accentColor : SkateTrackSessionStartColors.border,
                lineWidth: isSelected ? 2 : 1
            )
    }
}

#Preview("Mode Card") {
    ModeSelectionCardView(
        titleKey: "sport.mode.streetpark",
        descriptionKey: "mode.description.streetpark",
        tagKey: "mode.tag.tricks",
        iconName: "figure.skateboarding",
        accentColor: SkateTrackSessionStartColors.accent,
        isSelected: true,
        isLocked: false,
        onTap: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
