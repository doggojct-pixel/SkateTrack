// [協作區] SessionSpotAttributionView.swift
// 用途：在 Session Summary 呈現本次滑行所選場地的 archived snapshot 或 legacy spotID 狀態。
// 委派至：SessionSummaryView；不直接讀取 SpotRepository，避免 Summary UI 依賴可變 SpotProfile。

import SwiftUI

struct SessionSpotAttributionView: View {
    let session: SessionData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(SkateTrackSessionStartColors.teal.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("summary.spot.title")
                    .font(.caption.weight(.black))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)

                Text(displayName)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(detailLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("session-summary-spot-attribution")
    }

    private var displayName: String {
        guard let snapshot = session.spotSnapshot else {
            return NSLocalizedString("summary.spot.unsynced", comment: "")
        }
        return snapshot.displayName
    }

    private var detailLine: String {
        guard let snapshot = session.spotSnapshot else {
            return NSLocalizedString("summary.spot.legacy.description", comment: "")
        }
        let activity = NSLocalizedString(snapshot.activityFamily.localizationKey, comment: "")
        let format = NSLocalizedString("summary.spot.detailFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, activity, Int(snapshot.radiusMeters))
    }
}
