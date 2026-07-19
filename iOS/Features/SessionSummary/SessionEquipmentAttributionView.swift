// [協作區] SessionEquipmentAttributionView.swift
// 用途：在 Session Summary 顯示本次滑行使用裝備的歸屬快照。
// 委派至：SessionSummaryView；不反向導航到 Equipment Manager。

import SwiftUI

struct SessionEquipmentAttributionView: View {
    let session: SessionData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                icon

                VStack(alignment: .leading, spacing: 6) {
                    Text("summary.gear.title")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .textCase(.uppercase)

                    Text(titleText)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(detailText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                Text(LocalizedStringKey(statusKey))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("session-equipment-attribution")
    }

    private var icon: some View {
        Image(systemName: snapshot?.equipmentType.iconName ?? "questionmark.circle")
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(accentColor)
            .frame(width: 42, height: 42)
            .background(accentColor.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var snapshot: EquipmentSessionSnapshot? {
        session.equipmentSnapshot
    }

    private var titleText: String {
        snapshot?.displayName ?? NSLocalizedString("summary.gear.unsynced.title", comment: "")
    }

    private var detailText: String {
        guard let snapshot else {
            return NSLocalizedString("summary.gear.unsynced.subtitle", comment: "")
        }
        let mode = NSLocalizedString(snapshot.sportMode.modeLocalizationKey, comment: "")
        let power = NSLocalizedString(snapshot.powerType.localizationKey, comment: "")
        let format = NSLocalizedString("summary.gear.detailFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, mode, power)
    }

    private var statusKey: String {
        snapshot == nil ? "summary.gear.unsynced.badge" : "summary.gear.archived.badge"
    }

    private var accentColor: Color {
        switch snapshot?.sportMode ?? session.sportMode {
        case .skateboard:
            return (snapshot?.powerType ?? session.powerType) == .electric
                ? SkateTrackSessionStartColors.amber
                : SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        case .snow:
            return SkateTrackSessionStartColors.ice
        }
    }
}
