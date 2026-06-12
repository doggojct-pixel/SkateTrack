// [協作區] SessionSpotPickerView.swift
// 用途：在 Session Start Flow 提供本次使用場地選擇，不進入場地 CRUD 詳情以避免 root UI 疊層。
// 委派至：SessionStartView 傳入本機 SpotProfile 清單與 selectedSpotID。

import SwiftUI

struct SessionSpotPickerView: View {
    let spots: [SpotProfile]
    @Binding var selectedSpotID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if spots.isEmpty {
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
                .stroke(SkateTrackSessionStartColors.teal.opacity(0.22), lineWidth: 1)
        )
        .accessibilityIdentifier("session-spot-picker")
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(SkateTrackSessionStartColors.teal.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("spots.session.title")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                Text(subtitleKey)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Text("spots.session.optional")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(SkateTrackSessionStartColors.border.opacity(0.16))
                .clipShape(Capsule())
        }
    }

    private var subtitleKey: LocalizedStringKey {
        spots.isEmpty ? "spots.session.empty.subtitle" : "spots.session.subtitle"
    }

    private var emptyContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "map.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            Text("spots.session.empty.title")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy3.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("session-spot-empty")
    }

    private var selectionContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                selectionChip(
                    id: nil,
                    title: NSLocalizedString("spots.session.none", comment: ""),
                    subtitle: NSLocalizedString("spots.session.none.subtitle", comment: ""),
                    isFavorite: false
                )

                ForEach(spots) { spot in
                    selectionChip(
                        id: spot.id,
                        title: spot.name.isEmpty ? NSLocalizedString("spots.untitled", comment: "") : spot.name,
                        subtitle: subtitle(for: spot),
                        isFavorite: spot.isFavorite
                    )
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityIdentifier("session-spot-selection-scroll")
    }

    private func subtitle(for spot: SpotProfile) -> String {
        let activity = NSLocalizedString(spot.activityFamily.localizationKey, comment: "")
        let visitsFormat = NSLocalizedString("spots.session.visitCountFormat", comment: "")
        let visits = String(format: visitsFormat, locale: .autoupdatingCurrent, spot.visitCount)
        return "\(activity) · \(visits)"
    }

    private func selectionChip(
        id: UUID?,
        title: String,
        subtitle: String,
        isFavorite: Bool
    ) -> some View {
        let isSelected = selectedSpotID == id
        return Button {
            selectedSpotID = id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: isFavorite ? "star.fill" : "mappin.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                    Spacer(minLength: 8)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(isSelected ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(verbatim: subtitle)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 142, alignment: .leading)
            .padding(12)
            .background(isSelected ? SkateTrackSessionStartColors.teal.opacity(0.18) : SkateTrackSessionStartColors.navy3.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? SkateTrackSessionStartColors.teal.opacity(0.58) : SkateTrackSessionStartColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id == nil ? "session-spot-none" : "session-spot-option")
    }
}
