// [協作區] SessionHistoryCardView.swift
// 用途：呈現單筆歷史 Session 摘要卡，並支援免費版舊紀錄鎖定狀態。
// 委派至：SessionHistoryView 處理卡片點擊與 Paywall 路由。

import SwiftUI

struct SessionHistoryCardView: View {
    let entry: SessionHistoryEntry
    var isSelectionMode = false
    var isSelected = false
    let onTap: () -> Void
    var onToggleSelection: (() -> Void)?

    private var session: SessionData { entry.session }
    private var metrics: SessionSummaryMetrics { SessionSummaryDisplayMetrics.make(session: session, samples: session.motionSamples) }
    private var accentColor: Color {
        switch session.sportMode {
        case .skateboard:
            return session.powerType == .electric ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        }
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .topTrailing) {
                cardContent
                    .blur(radius: entry.isLocked && !isSelectionMode ? 1.4 : 0)
                    .opacity(entry.isLocked && !isSelectionMode ? 0.62 : 1)

                if entry.isLocked && !isSelectionMode {
                    lockedOverlay
                }

                if isSelectionMode {
                    selectionBadge
                }
            }
            .padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(isSelected ? 0.94 : 0.84))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22)
            .stroke(isSelected ? SkateTrackSessionStartColors.teal.opacity(0.9) : SkateTrackSessionStartColors.border, lineWidth: isSelected ? 2 : 1)
    }

    private var selectionBadge: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(isSelected ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textTertiary)
            .padding(2)
            .background(SkateTrackSessionStartColors.navy.opacity(0.72))
            .clipShape(Circle())
            .accessibilityIdentifier(isSelected ? "history-card-selected" : "history-card-not-selected")
    }

    private var accessibilityIdentifier: String {
        if isSelectionMode {
            return isSelected ? "history-session-card-selected" : "history-session-card-selectable"
        }
        return entry.isLocked ? "history-session-card-locked" : "history-session-card-unlocked"
    }

    private func handleTap() {
        if isSelectionMode {
            onToggleSelection?()
        } else {
            onTap()
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(session.sportMode.modeLocalizationKey))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(dateLine)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                }

                Spacer()

                Text(LocalizedStringKey(session.powerType.localizationKey))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Capsule())
            }

            if let gearLine {
                gearSnapshotLine(gearLine)
            }

            if let spotLine {
                spotSnapshotLine(spotLine)
            }

            HStack(spacing: 9) {
                metric(value: distanceText, labelKey: "history.card.distance")
                metric(value: maxSpeedText, labelKey: "history.card.maxSpeed")
                metric(value: durationText, labelKey: "history.card.duration")
            }
        }
    }

    private var lockedOverlay: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill")
            Text("history.card.locked")
        }
        .font(.system(size: 11, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(SkateTrackSessionStartColors.purple.opacity(0.86))
        .clipShape(Capsule())
    }


    private func gearSnapshotLine(_ text: String) -> some View {
        attributionLine(
            text,
            iconName: session.equipmentSnapshot?.equipmentType.iconName ?? "questionmark.circle",
            identifier: "history-card-equipment-snapshot"
        )
    }

    private func spotSnapshotLine(_ text: String) -> some View {
        attributionLine(
            text,
            iconName: "mappin.and.ellipse",
            identifier: "history-card-spot-snapshot"
        )
    }

    private func attributionLine(_ text: String, iconName: String, identifier: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(accentColor)

            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.045))
        .clipShape(Capsule())
        .accessibilityIdentifier(identifier)
    }

    private func metric(value: String, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(LocalizedStringKey(labelKey))
                .tracking(0.8)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }


    private var gearLine: String? {
        if let snapshot = session.equipmentSnapshot {
            let mode = NSLocalizedString(snapshot.sportMode.modeLocalizationKey, comment: "")
            let power = NSLocalizedString(snapshot.powerType.localizationKey, comment: "")
            let format = NSLocalizedString("history.gear.lineFormat", comment: "")
            return String(format: format, locale: .autoupdatingCurrent, snapshot.displayName, mode, power)
        }
        return session.equipmentID == nil ? nil : NSLocalizedString("history.gear.unsynced", comment: "")
    }

    private var spotLine: String? {
        if let snapshot = session.spotSnapshot {
            let activity = NSLocalizedString(snapshot.activityFamily.localizationKey, comment: "")
            let format = NSLocalizedString("history.spot.lineFormat", comment: "")
            return String(format: format, locale: .autoupdatingCurrent, snapshot.displayName, activity)
        }
        return session.spotID == nil ? nil : NSLocalizedString("history.spot.unsynced", comment: "")
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.startDate)
    }

    private var distanceText: String {
        UnitFormatter.distance(meters: metrics.distanceKilometers * 1_000, maximumFractionDigits: 2)
    }

    private var maxSpeedText: String {
        String(format: "%.1f km/h", metrics.maxSpeedKilometersPerHour)
    }

    private var durationText: String {
        guard let duration = session.durationSeconds else { return NSLocalizedString("general.value.unavailable", comment: "") }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? NSLocalizedString("general.value.unavailable", comment: "")
    }
}
