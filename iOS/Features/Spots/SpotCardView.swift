// [協作區] SpotCardView.swift
// 用途：以 SkateTrack 深色卡片呈現單一 Spot 摘要與收藏切換。
// 委派至：SpotListView / SpotMapView 處理導覽與資料操作。

import SwiftUI

struct SpotCardView: View {
    let spot: SpotProfile
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(primaryAccent.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(primaryAccent)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    titleText
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    favoriteButton
                }

                HStack(spacing: 8) {
                    chip(spot.activityFamily.localizationKey, color: primaryAccent)
                    if let surfaceRating = spot.surfaceRating {
                        chip(surfaceRating.localizationKey, color: SkateTrackSessionStartColors.teal)
                    }
                    chip(spot.crowdLevel.localizationKey, color: SkateTrackSessionStartColors.amber)
                }

                if let notes = spot.notes, !notes.isEmpty {
                    Text(verbatim: notes)
                        .font(.caption)
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .lineLimit(2)
                } else {
                    Text(LocalizedStringKey(spot.hasCoordinate ? "spots.coordinate.available" : "spots.coordinate.missing"))
                        .font(.caption)
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                }

                HStack(spacing: 12) {
                    metadata(value: "\(spot.visitCount)", label: "spots.visits")
                    metadata(value: Int(spot.radiusMeters).description, label: "spots.radius.meters")
                    if let safetyRating = spot.safetyRating {
                        metadata(value: "\(safetyRating)/5", label: "spots.safety")
                    }
                }
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("spot-card")
    }


    private var titleText: Text {
        if spot.name.isEmpty {
            return Text("spots.untitled")
        }
        return Text(verbatim: spot.name)
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: spot.isFavorite ? "star.fill" : "star")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(spot.isFavorite ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.textTertiary)
                .frame(width: 34, height: 34)
                .background(SkateTrackSessionStartColors.navy3.opacity(0.82))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(spot.isFavorite ? "spot-unfavorite-button" : "spot-favorite-button")
    }

    private var primaryAccent: Color {
        switch spot.activityFamily {
        case .skateboard:
            return SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        case .mixed:
            return SkateTrackSessionStartColors.teal
        }
    }

    private var iconName: String {
        switch spot.activityFamily {
        case .skateboard:
            return "figure.skateboarding"
        case .inline:
            return "figure.walk"
        case .mixed:
            return "mappin.and.ellipse"
        }
    }

    private func chip(_ key: String, color: Color) -> some View {
        Text(LocalizedStringKey(key))
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private func metadata(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
            Text(LocalizedStringKey(label))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
    }
}
