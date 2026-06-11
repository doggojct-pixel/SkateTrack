// [協作區] EquipmentCardView.swift
// 用途：呈現單一裝備卡片、總里程、輪子 / 培林磨耗進度與 OK / CHECK / REPLACE badge。
// 委派至：EquipmentListView、EquipmentDetailView；磨耗公式由 WearReminderEngine 提供。

import SwiftUI

struct EquipmentCardView: View {
    let equipment: EquipmentProfile
    let report: EquipmentWearReport
    var showsDisclosure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                equipmentAvatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(equipment.name)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(typeLine)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                wearBadge(report.overallStatus)

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                }
            }

            HStack(spacing: 8) {
                statBox(
                    value: distanceString(equipment.totalDistanceKm),
                    labelKey: "gear.totalMileage",
                    color: primaryAccent
                )
                statBox(
                    value: distanceString(primaryWearMileage),
                    labelKey: primaryWearLabelKey,
                    color: report.overallStatus == .ok ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.accent
                )
            }

            if let reading = report.primaryReading {
                wearProgress(reading)
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("equipment-card-\(equipment.id.uuidString)")
    }

    private var equipmentAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [primaryAccent.opacity(0.30), primaryAccent.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            equipmentIcon
        }
        .accessibilityHidden(true)
    }


    @ViewBuilder
    private var equipmentIcon: some View {
        switch equipment.equipmentType {
        case .skateboard:
            Image(systemName: equipment.equipmentType.iconName)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(primaryAccent)
                .symbolRenderingMode(.hierarchical)
        case .inlineSkates:
            EquipmentCardInlineSkateGlyphView(color: primaryAccent)
                .frame(width: 28, height: 28)
        }
    }

    private var typeLine: String {
        let sport = NSLocalizedString(equipment.sportMode.modeLocalizationKey, comment: "")
        let power = NSLocalizedString(equipment.powerType.localizationKey, comment: "")
        return "\(sport) · \(power)".uppercased()
    }

    private var primaryAccent: Color {
        switch equipment.equipmentType {
        case .skateboard:
            return SkateTrackSessionStartColors.accent
        case .inlineSkates:
            return SkateTrackSessionStartColors.purple
        }
    }

    private var primaryWearMileage: Double {
        report.primaryReading?.mileageKm ?? equipment.wheelSetMileageKm
    }

    private var primaryWearLabelKey: String {
        report.primaryReading?.component == .bearings ? "gear.bearings" : "gear.wheelSet"
    }

    private func statBox(value: String, labelKey: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(SkateTrackSessionStartColors.navy3.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func wearProgress(_ reading: EquipmentWearReading) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStringKey(reading.component.titleLocalizationKey))
                Spacer()
                Text(progressLabel(reading))
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textTertiary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SkateTrackSessionStartColors.navy3)
                    Capsule()
                        .fill(progressGradient(for: reading.status))
                        .frame(width: max(6, proxy.size.width * reading.progress))
                }
            }
            .frame(height: 7)
        }
        .accessibilityIdentifier("equipment-card-wear-progress")
    }

    private func wearBadge(_ status: EquipmentWearStatus) -> some View {
        Text(LocalizedStringKey(status.badgeLocalizationKey))
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(statusColor(status).opacity(0.32), lineWidth: 1)
            )
            .accessibilityIdentifier("equipment-wear-status-\(status.rawValue)")
    }

    private func progressGradient(for status: EquipmentWearStatus) -> LinearGradient {
        let colors: [Color]
        switch status {
        case .ok:
            colors = [SkateTrackSessionStartColors.teal, SkateTrackSessionStartColors.green]
        case .checkSoon:
            colors = [SkateTrackSessionStartColors.amber, Color.orange]
        case .replaceRecommended:
            colors = [SkateTrackSessionStartColors.accent, SkateTrackSessionStartColors.accent2]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private func statusColor(_ status: EquipmentWearStatus) -> Color {
        switch status {
        case .ok:
            return SkateTrackSessionStartColors.green
        case .checkSoon:
            return SkateTrackSessionStartColors.amber
        case .replaceRecommended:
            return SkateTrackSessionStartColors.accent2
        }
    }

    private func distanceString(_ kilometers: Double) -> String {
        UnitFormatter.distance(meters: kilometers * 1_000, maximumFractionDigits: 0)
    }

    private func progressLabel(_ reading: EquipmentWearReading) -> String {
        let format = NSLocalizedString("gear.progress.km_format", comment: "")
        return String(
            format: format,
            locale: .autoupdatingCurrent,
            Int(reading.mileageKm.rounded()),
            Int(reading.thresholdKm.rounded())
        )
    }
}


private struct EquipmentCardInlineSkateGlyphView: View {
    let color: Color

    var body: some View {
        ZStack {
            Image(systemName: "figure.walk")
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .offset(x: 0, y: -4)

            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(color.opacity(0.75))
                .frame(width: 20, height: 3)
                .rotationEffect(.degrees(-8))
                .offset(x: 1, y: 9)

            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { _ in
                    Circle()
                        .fill(color)
                        .frame(width: 3.5, height: 3.5)
                }
            }
            .offset(x: 1, y: 13)
        }
        .foregroundStyle(color)
        .accessibilityHidden(true)
    }
}

#Preview("Equipment Card") {
    EquipmentCardView(
        equipment: EquipmentManagerViewModel.sampleEquipment[0],
        report: WearReminderEngine.report(for: EquipmentManagerViewModel.sampleEquipment[0])
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
}
