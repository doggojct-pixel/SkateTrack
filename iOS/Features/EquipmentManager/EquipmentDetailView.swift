// [協作區] EquipmentDetailView.swift
// 用途：呈現單一裝備詳細資料、保養資訊、輪子 / 培林里程 reset 與刪除確認。
// 委派至：EquipmentListView 管理資料流，WearReminderEngine 提供磨耗結果。

import SwiftUI

struct EquipmentDetailView: View {
    let equipment: EquipmentProfile
    let report: EquipmentWearReport
    let canManage: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onResetWheels: () -> Void
    let onResetBearings: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                detailHeader

                EquipmentCardView(
                    equipment: equipment,
                    report: report,
                    showsDisclosure: false
                )

                detailSection(titleKey: "gear.detail.maintenance") {
                    ForEach(report.readings) { reading in
                        maintenanceRow(reading)
                    }
                }

                detailSection(titleKey: "gear.detail.profile") {
                    infoRow("gear.form.type", valueKey: equipment.displayTypeLocalizationKey)
                    infoRow("gear.form.mode", valueKey: equipment.sportMode.modeLocalizationKey)
                    infoRow("gear.form.power", valueKey: equipment.powerType.localizationKey)
                    if let wheelDiameter = equipment.wheelDiameterMillimeters {
                        infoRow("gear.form.wheelDiameter", value: String(format: "%.0f mm", wheelDiameter))
                    }
                    if let wheelHardness = equipment.wheelHardness {
                        infoRow("gear.form.wheelHardness", value: wheelHardness)
                    }
                    if let bearingABEC = equipment.bearingABEC {
                        infoRow("gear.form.bearingABEC", value: bearingABEC)
                    }
                    if let brakeType = equipment.brakeType {
                        infoRow("gear.form.brakeType", value: brakeType)
                    }
                    if let notes = equipment.notes {
                        infoRow("gear.form.notes", value: notes)
                    }
                }

                if canManage {
                    actionSection
                }
            }
            .padding(.top, 58)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            Text("gear.delete.confirm.title"),
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("gear.delete.confirm.action", role: .destructive) {
                onDelete()
            }
            Button("general.cancel", role: .cancel) { }
        } message: {
            Text("gear.delete.confirm.message")
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("equipment-detail-view")
    }


    private var detailHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(SkateTrackSessionStartColors.card.opacity(0.86))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("gear.detail.back"))
            .accessibilityIdentifier("equipment-detail-back-button")

            VStack(alignment: .leading, spacing: 2) {
                Text("gear.detail.title")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(equipment.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if canManage {
                Button("gear.edit") {
                    onEdit()
                }
                .font(.callout.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(SkateTrackSessionStartColors.card.opacity(0.86))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
                )
                .buttonStyle(.plain)
                .accessibilityIdentifier("equipment-detail-edit-button")
            }
        }
        .accessibilityIdentifier("equipment-detail-header")
    }

    private var actionSection: some View {
        detailSection(titleKey: "gear.detail.actions") {
            Button {
                onResetWheels()
            } label: {
                actionLabel("gear.reset.wheels", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)

            Button {
                onResetBearings()
            } label: {
                actionLabel("gear.reset.bearings", systemImage: "arrow.counterclockwise.circle")
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                isDeleteConfirmationPresented = true
            } label: {
                actionLabel("gear.delete", systemImage: "trash")
                    .foregroundStyle(SkateTrackSessionStartColors.accent2)
            }
            .buttonStyle(.plain)
        }
    }

    private func detailSection<Content: View>(
        titleKey: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)

            VStack(spacing: 10) {
                content()
            }
            .padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
            )
        }
    }

    private func maintenanceRow(_ reading: EquipmentWearReading) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(LocalizedStringKey(reading.component.titleLocalizationKey))
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(progressLabel(reading))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }

            ProgressView(value: reading.progress)
                .tint(statusColor(reading.status))
                .accessibilityIdentifier("equipment-detail-progress-\(reading.component.rawValue)")
        }
    }

    private func infoRow(_ titleKey: String, valueKey: String) -> some View {
        infoRow(titleKey, value: NSLocalizedString(valueKey, comment: ""))
    }

    private func infoRow(_ titleKey: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            Spacer(minLength: 16)
            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(_ titleKey: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(LocalizedStringKey(titleKey))
            Spacer()
        }
        .font(.callout.weight(.bold))
        .foregroundStyle(SkateTrackSessionStartColors.teal)
        .padding(.vertical, 4)
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
}

#Preview("Equipment Detail") {
    NavigationStack {
        EquipmentDetailView(
            equipment: EquipmentManagerViewModel.sampleEquipment[1],
            report: WearReminderEngine.report(for: EquipmentManagerViewModel.sampleEquipment[1]),
            canManage: true,
            onEdit: {},
            onDelete: {},
            onResetWheels: {},
            onResetBearings: {}
        )
    }
}
