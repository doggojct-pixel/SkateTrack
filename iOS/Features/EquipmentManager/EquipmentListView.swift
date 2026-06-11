// [協作區] EquipmentListView.swift
// 用途：呈現 iOS Screen 07 裝備管理主畫面，包含示範卡、訂閱門禁、裝備 CRUD 入口。
// 委派至：useEquipmentManager 管理資料狀態，EquipmentCardView / Detail / Edit 呈現細節。

import SwiftUI

struct EquipmentListView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @StateObject private var equipmentManager: EquipmentManagerViewModel
    @State private var editSheet: EquipmentEditSheet?
    @State private var paywallFeature: GatedFeature?
    @State private var navigationPath: [UUID] = []
    private let isDetailPresented: Binding<Bool>

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        isDetailPresented: Binding<Bool> = .constant(false)
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.isDetailPresented = isDetailPresented
        _equipmentManager = StateObject(
            wrappedValue: useEquipmentManager(subscriptionStatus: subscriptionStatus)
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !equipmentManager.hasManagementAccess {
                        lockedBanner
                    }

                    if equipmentManager.isLoading {
                        ProgressView()
                            .tint(SkateTrackSessionStartColors.teal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }

                    if equipmentManager.displayEquipment.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 10) {
                            ForEach(equipmentManager.displayEquipment) { equipment in
                                NavigationLink(value: equipment.id) {
                                    EquipmentCardView(
                                        equipment: equipment,
                                        report: equipmentManager.wearReport(for: equipment)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .accessibilityIdentifier("equipment-list-cards")
                    }

                    addGearButton
                }
                .padding(.top, 58)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(background.ignoresSafeArea())
            .navigationDestination(for: UUID.self) { equipmentID in
                if let equipment = equipmentManager.displayEquipment.first(where: { $0.id == equipmentID }) {
                    EquipmentDetailView(
                        equipment: equipment,
                        report: equipmentManager.wearReport(for: equipment),
                        canManage: equipmentManager.hasManagementAccess,
                        onEdit: { editSheet = .edit(equipment) },
                        onDelete: {
                            Task {
                                await equipmentManager.delete(equipment)
                                navigationPath.removeAll()
                            }
                        },
                        onResetWheels: { Task { await equipmentManager.resetWheelMileage(for: equipment) } },
                        onResetBearings: { Task { await equipmentManager.resetBearingMileage(for: equipment) } }
                    )
                } else {
                    Text("gear.empty.title")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SkateTrackSessionStartColors.navy)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isDetailPresented.wrappedValue = !navigationPath.isEmpty
        }
        .onChange(of: navigationPath) { _, newPath in
            isDetailPresented.wrappedValue = !newPath.isEmpty
        }
        .task { await equipmentManager.refresh() }
        .onChange(of: subscriptionStatus.isSubscriber) { _, _ in
            Task { await equipmentManager.refresh() }
        }
        .sheet(item: $editSheet) { sheet in
            EditEquipmentView(equipment: sheet.equipment) { equipment in
                Task { await equipmentManager.save(equipment) }
            }
        }
        .sheet(item: $paywallFeature) { feature in
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: feature
            )
        }
        .accessibilityIdentifier("equipment-list-view")
    }

    private var background: some View {
        ZStack {
            SkateTrackSessionStartColors.navy2
            RadialGradient(
                colors: [SkateTrackSessionStartColors.accent.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 430
            )
            RadialGradient(
                colors: [SkateTrackSessionStartColors.purple.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 460
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("gear.eyebrow")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)

                    Text("gear.title")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(LocalizedStringKey(equipmentManager.hasManagementAccess ? "gear.pro.badge" : "gear.locked.badge"))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(equipmentManager.hasManagementAccess ? SkateTrackSessionStartColors.green : SkateTrackSessionStartColors.amber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background((equipmentManager.hasManagementAccess ? SkateTrackSessionStartColors.green : SkateTrackSessionStartColors.amber).opacity(0.14))
                    .clipShape(Capsule())
            }

            Text(LocalizedStringKey(equipmentManager.hasManagementAccess ? "gear.subtitle.unlocked" : "gear.subtitle.locked"))
                .font(.callout)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("equipment-list-header")
    }

    private var lockedBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                Text("gear.locked.title")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
            }

            Text("gear.locked.subtitle")
                .font(.footnote)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

            Button {
                paywallFeature = .equipmentManager
            } label: {
                Text("gear.locked.cta")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SkateTrackSessionStartColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SkateTrackSessionStartColors.amber.opacity(0.25), lineWidth: 1)
        )
        .accessibilityIdentifier("equipment-locked-banner")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundStyle(SkateTrackSessionStartColors.teal)
            Text("gear.empty.title")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text("gear.empty.subtitle")
                .font(.footnote)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(SkateTrackSessionStartColors.border)
        )
    }

    private var addGearButton: some View {
        Button {
            if equipmentManager.canAddEquipment {
                editSheet = .add
            } else {
                paywallFeature = .equipmentManager
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("gear.addNew")
            }
            .font(.callout.weight(.heavy))
            .foregroundStyle(SkateTrackSessionStartColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(SkateTrackSessionStartColors.accent.opacity(0.48))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("equipment-add-gear-button")
    }
}

private enum EquipmentEditSheet: Identifiable {
    case add
    case edit(EquipmentProfile)

    var id: String {
        switch self {
        case .add:
            return "add"
        case let .edit(equipment):
            return equipment.id.uuidString
        }
    }

    var equipment: EquipmentProfile? {
        switch self {
        case .add:
            return nil
        case let .edit(equipment):
            return equipment
        }
    }
}

#Preview("Equipment List") {
    EquipmentListView(subscriptionStatus: useSubscriptionStatus())
}
