// [協作區] SessionEquipmentPickerView.swift
// 用途：在 Session Start Flow 提供本次使用裝備選擇，不進入裝備 CRUD 詳情以避免 root UI 疊層。
// 委派至：SessionStartView 傳入已通過付費 gating 的裝備清單與 selectedEquipmentID。

import SwiftUI

struct SessionEquipmentPickerView: View {
    let equipment: [EquipmentProfile]
    let selectedSportMode: SportMode
    let selectedPowerType: PowerType
    let hasAccess: Bool
    @Binding var selectedEquipmentID: UUID?
    let onUnlock: () -> Void

    private var compatibleEquipment: [EquipmentProfile] {
        equipment.filter { equipment in
            equipment.isCompatible(with: selectedSportMode, powerType: selectedPowerType)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if hasAccess == false {
                lockedContent
            } else if compatibleEquipment.isEmpty {
                emptyContent
            } else {
                selectionContent
            }
        }
        .padding(15)
        .background(SkateTrackSessionStartColors.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .accessibilityIdentifier("session-equipment-picker")
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(SkateTrackSessionStartColors.teal.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("gear.session.title")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                Text(subtitleKey)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Text(LocalizedStringKey(hasAccess ? "gear.session.optional" : "gear.pro.badge"))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(hasAccess ? SkateTrackSessionStartColors.textTertiary : SkateTrackSessionStartColors.amber)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background((hasAccess ? SkateTrackSessionStartColors.border : SkateTrackSessionStartColors.amber).opacity(0.16))
                .clipShape(Capsule())
        }
    }

    private var subtitleKey: LocalizedStringKey {
        if hasAccess == false { return "gear.session.locked.subtitle" }
        if compatibleEquipment.isEmpty { return "gear.session.empty.subtitle" }
        return "gear.session.subtitle"
    }

    private var lockedContent: some View {
        Button(action: onUnlock) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                Text("gear.session.locked.cta")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .font(.callout.weight(.heavy))
            .foregroundStyle(.white)
            .padding(12)
            .background(SkateTrackSessionStartColors.accent.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("session-equipment-locked-cta")
    }

    private var emptyContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            Text("gear.session.empty.title")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy3.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("session-equipment-empty")
    }

    private var selectionContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                selectionChip(
                    id: nil,
                    titleKey: "gear.session.none",
                    subtitle: NSLocalizedString("gear.session.none.subtitle", comment: ""),
                    iconName: "minus.circle.fill",
                    isInline: false
                )

                ForEach(compatibleEquipment) { gear in
                    selectionChip(
                        id: gear.id,
                        titleKey: gear.name,
                        subtitle: subtitle(for: gear),
                        iconName: gear.equipmentType.iconName,
                        isInline: gear.equipmentType == .inlineSkates
                    )
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityIdentifier("session-equipment-selection-scroll")
    }

    private func subtitle(for equipment: EquipmentProfile) -> String {
        let mode = NSLocalizedString(equipment.sportMode.modeLocalizationKey, comment: "")
        guard equipment.equipmentType == .skateboard else { return mode }

        let power = NSLocalizedString(equipment.powerType.localizationKey, comment: "")
        return "\(mode) · \(power)"
    }

    private func selectionChip(
        id: UUID?,
        titleKey: String,
        subtitle: String,
        iconName: String,
        isInline: Bool
    ) -> some View {
        let isSelected = selectedEquipmentID == id
        return Button {
            selectedEquipmentID = id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if isInline {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 15, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 15, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Spacer(minLength: 8)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(isSelected ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    titleText(id: id, title: titleKey)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 126, alignment: .leading)
            .padding(12)
            .background(isSelected ? SkateTrackSessionStartColors.teal.opacity(0.18) : SkateTrackSessionStartColors.navy3.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? SkateTrackSessionStartColors.teal.opacity(0.58) : SkateTrackSessionStartColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id == nil ? "session-equipment-none" : "session-equipment-option")
    }

    @ViewBuilder
    private func titleText(id: UUID?, title: String) -> some View {
        if id == nil {
            Text(LocalizedStringKey(title))
        } else {
            Text(title)
        }
    }

    private var borderColor: Color {
        hasAccess ? SkateTrackSessionStartColors.teal.opacity(0.24) : SkateTrackSessionStartColors.amber.opacity(0.22)
    }
}
