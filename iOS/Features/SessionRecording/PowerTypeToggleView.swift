// [協作區] PowerTypeToggleView.swift
// 用途：提供滑板模式的人力 / 電動動力切換，直排輪流程不顯示此元件。
// 委派至：SessionStartView 在切換到 inline 時自動回復 humanPowered。

import SwiftUI

struct PowerTypeToggleView: View {
    @Binding var selectedPowerType: PowerType
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("power.type.title")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("session.start.skateboard.subtitle")
                    .font(.caption2)
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                ForEach(PowerType.allCases, id: \.self) { powerType in
                    Button {
                        selectedPowerType = powerType
                    } label: {
                        powerTypePill(powerType)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("power-type-\(powerType.rawValue)")
                }
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
    }

    private func powerTypePill(_ powerType: PowerType) -> some View {
        let isSelected = selectedPowerType == powerType

        return HStack(spacing: 6) {
            Image(systemName: powerType == .electric ? "bolt.fill" : "figure.skateboarding")
            Text(LocalizedStringKey(powerType.localizationKey))
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .foregroundStyle(isSelected ? .white : accentColor)
        .background(isSelected ? accentColor : accentColor.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(accentColor.opacity(isSelected ? 0 : 0.22), lineWidth: 1))
    }
}

#Preview("Power Type") {
    PowerTypeToggleView(
        selectedPowerType: .constant(.humanPowered),
        accentColor: SkateTrackSessionStartColors.accent
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
