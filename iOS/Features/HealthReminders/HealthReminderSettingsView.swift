// [協作區] HealthReminderSettingsView.swift
// 用途：呈現 Task-019a 健康提醒設定與 Pro 鎖定狀態；不排程通知、不讀取真實天氣。
// 委派至：useHealthReminders 保存設定；SubscriptionPaywallView 處理升級導流。

import SwiftUI

struct HealthReminderSettingsEntryCardView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let onOpen: () -> Void

    private var hasAccess: Bool {
        subscriptionStatus.hasAccess(to: .healthReminders)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Image(systemName: hasAccess ? "heart.text.square.fill" : "lock.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(hasAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                    .frame(width: 38, height: 38)
                    .background((hasAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple).opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text("health.reminders.entry.title")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(LocalizedStringKey(hasAccess ? "health.reminders.entry.enabled_badge" : "health.reminders.entry.pro_badge"))
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(hasAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background((hasAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple).opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Text(LocalizedStringKey(hasAccess ? "health.reminders.entry.subtitle.unlocked" : "health.reminders.entry.subtitle.locked"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkateTrackSessionStartColors.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke((hasAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple).opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("health-reminders-entry-card")
    }
}

struct HealthReminderSettingsView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @StateObject private var viewModel: HealthReminderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPaywallPresented = false

    init(subscriptionStatus: SubscriptionStatusViewModel) {
        self.subscriptionStatus = subscriptionStatus
        _viewModel = StateObject(wrappedValue: useHealthReminders(subscriptionStatus: subscriptionStatus))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        accessStatusCard

                        if viewModel.canEditSettings {
                            editableRules
                            resetButton
                        } else {
                            lockedState
                            readOnlyRulesPreview
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(Text("health.reminders.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("general.done") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isPaywallPresented) {
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: .healthReminders
            )
        }
        .onChange(of: subscriptionStatus.isSubscriber) { _, _ in
            viewModel.syncAccess()
        }
        .accessibilityIdentifier("health-reminder-settings-view")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.28), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 430
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("health.reminders.eyebrow")
                .tracking(2)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .textCase(.uppercase)

            Text("health.reminders.title")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("health.reminders.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accessStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.canEditSettings ? "checkmark.seal.fill" : "lock.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(viewModel.canEditSettings ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                .frame(width: 34, height: 34)
                .background((viewModel.canEditSettings ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple).opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(viewModel.canEditSettings ? "health.reminders.access.unlocked.title" : "health.reminders.access.locked.title"))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(viewModel.canEditSettings ? "health.reminders.access.unlocked.subtitle" : "health.reminders.access.locked.subtitle"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
    }

    private var editableRules: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("health.reminders.settings.section_title")
                .tracking(1.4)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            ForEach(HealthReminderKind.allCases) { kind in
                HealthReminderRuleCard(
                    kind: kind,
                    rule: viewModel.rule(for: kind),
                    isEditable: viewModel.canEditSettings,
                    onToggle: { viewModel.setEnabled($0, for: kind) },
                    onIntervalChange: { viewModel.setIntervalMinutes($0, for: kind) },
                    onThresholdChange: { viewModel.setThreshold($0, for: kind) }
                )
            }
        }
    }

    private var readOnlyRulesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("health.reminders.preview.section_title")
                .tracking(1.4)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            ForEach(HealthReminderKind.allCases) { kind in
                HealthReminderRuleCard(
                    kind: kind,
                    rule: HealthReminderRule.defaultRule(for: kind),
                    isEditable: false,
                    onToggle: { _ in },
                    onIntervalChange: { _ in },
                    onThresholdChange: { _ in }
                )
            }
        }
    }

    private var lockedState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("health.reminders.locked.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("health.reminders.locked.subtitle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                isPaywallPresented = true
            } label: {
                HStack(spacing: 8) {
                    Text("health.reminders.locked.cta")
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(.white)
                .background(SkateTrackSessionStartColors.purple.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("health-reminders-open-paywall")

            Text("health.reminders.locked.deferred_notice")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SkateTrackSessionStartColors.purple.opacity(0.34), lineWidth: 1)
        )
    }

    private var resetButton: some View {
        Button {
            viewModel.resetToDefaults()
        } label: {
            Text("health.reminders.reset")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SkateTrackSessionStartColors.card.opacity(0.70))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("health-reminders-reset")
    }
}

private struct HealthReminderRuleCard: View {
    let kind: HealthReminderKind
    let rule: HealthReminderRule
    let isEditable: Bool
    let onToggle: (Bool) -> Void
    let onIntervalChange: (Int) -> Void
    let onThresholdChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind.systemImageName)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(rule.isEnabled ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textTertiary)
                    .frame(width: 34, height: 34)
                    .background((rule.isEnabled ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textTertiary).opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey(kind.titleKey))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(LocalizedStringKey(kind.subtitleKey))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Toggle("", isOn: Binding(get: { rule.isEnabled }, set: onToggle))
                    .labelsHidden()
                    .disabled(!isEditable)
                    .tint(SkateTrackSessionStartColors.teal)
            }

            if rule.isEnabled {
                controlRow
            }
        }
        .padding(15)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(rule.isEnabled ? SkateTrackSessionStartColors.teal.opacity(0.28) : SkateTrackSessionStartColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("health-reminder-rule-\(kind.rawValue)")
    }

    @ViewBuilder
    private var controlRow: some View {
        switch kind {
        case .hydration, .rest, .cooldownStretch:
            Stepper(
                value: Binding(
                    get: { rule.intervalMinutes ?? kind.defaultIntervalMinutes ?? 20 },
                    set: onIntervalChange
                ),
                in: 1...180,
                step: 1
            ) {
                settingLabel(
                    titleKey: "health.reminders.interval.label",
                    value: "\(rule.intervalMinutes ?? kind.defaultIntervalMinutes ?? 20) min"
                )
            }
            .disabled(!isEditable)
        case .heatRisk:
            Stepper(
                value: Binding(
                    get: { rule.threshold ?? kind.defaultThreshold ?? 35 },
                    set: onThresholdChange
                ),
                in: 25...45,
                step: 1
            ) {
                settingLabel(
                    titleKey: "health.reminders.threshold.heat",
                    value: "\(Int(rule.threshold ?? kind.defaultThreshold ?? 35))°C"
                )
            }
            .disabled(!isEditable)
        case .uvRisk:
            Stepper(
                value: Binding(
                    get: { rule.threshold ?? kind.defaultThreshold ?? 6 },
                    set: onThresholdChange
                ),
                in: 1...11,
                step: 1
            ) {
                settingLabel(
                    titleKey: "health.reminders.threshold.uv",
                    value: "UV \(Int(rule.threshold ?? kind.defaultThreshold ?? 6))"
                )
            }
            .disabled(!isEditable)
        }
    }

    private func settingLabel(titleKey: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
        }
    }
}

#Preview("Health Reminders") {
    HealthReminderSettingsView(subscriptionStatus: useSubscriptionStatus())
}
