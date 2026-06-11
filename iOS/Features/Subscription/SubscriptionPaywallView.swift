// [協作區] SubscriptionPaywallView.swift
// 用途：呈現 Task-016b 付費牆 UI 與 DEBUG/local entitlement 模擬流程。
// 委派至：useSubscriptionStatus / FeatureFlagEngine 處理權限，真實 StoreKit 付款留給 Task-016c。

import SwiftUI

struct SubscriptionPaywallView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel

    let lockedFeature: GatedFeature?

    @Environment(\.dismiss) private var dismiss
    @State private var actionState: SubscriptionPaywallActionState = .idle

    private var accentColor: Color {
        featureAccentColor ?? SkateTrackSessionStartColors.teal
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection
                        entitlementStatusCard
                        SubscriberBenefitsListView(accentColor: accentColor)
                        primaryActionSection
                        RestorePurchaseButton(subscriptionStatus: subscriptionStatus, accentColor: accentColor)
                        legalNotice
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(Text("subscription.paywall.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("general.done") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("subscription-paywall-view")
        .onChange(of: subscriptionStatus.isSubscriber) { _, isSubscriber in
            if isSubscriber {
                actionState = .success
            }
        }
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
                colors: [accentColor.opacity(0.34), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("subscription.paywall.eyebrow")
                .tracking(2)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(accentColor)
                .textCase(.uppercase)

            Text("subscription.paywall.title")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(heroSubtitleKey))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("subscription-paywall-hero")
    }

    private var entitlementStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("subscription.paywall.current_status")
                    .tracking(1.5)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
                Spacer()
                Text(LocalizedStringKey(subscriptionStatus.isSubscriber ? "subscription.subscriber" : "subscription.free"))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(subscriptionStatus.isSubscriber ? accentColor : SkateTrackSessionStartColors.textSecondary)
            }

            Text(LocalizedStringKey(subscriptionStatus.entitlementSourceDescriptionKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

            Text(LocalizedStringKey(subscriptionStatus.entitlementStatusMessageKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("subscription-paywall-status")
    }

    private var primaryActionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: handlePrimaryAction) {
                HStack(spacing: 10) {
                    if actionState == .processing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: primaryActionIconName)
                    }

                    Text(LocalizedStringKey(primaryActionTitleKey))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(primaryActionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(primaryActionDisabled)
            .accessibilityIdentifier("subscription-paywall-primary-action")

            Text(LocalizedStringKey(actionState.messageKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(actionState == .success ? accentColor : SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("subscription-paywall-action-message")

            #if DEBUG
            debugSimulationControls
            #endif
        }
    }

    #if DEBUG
    private var debugSimulationControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("subscription.paywall.debug_controls.title")
                .tracking(1.5)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                debugStateButton("subscription.paywall.debug_success", state: .success) {
                    subscriptionStatus.setDebugSubscriptionOverride(true)
                }
                debugStateButton("subscription.paywall.debug_cancelled", state: .cancelled)
                debugStateButton("subscription.paywall.debug_failed", state: .failed)
            }
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("subscription-paywall-debug-controls")
    }

    private func debugStateButton(
        _ titleKey: String,
        state: SubscriptionPaywallActionState,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            actionState = state
            action?()
        } label: {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .foregroundStyle(state == .success ? .white : SkateTrackSessionStartColors.textSecondary)
                .background(state == .success ? accentColor.opacity(0.70) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    #endif

    private var legalNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("subscription.paywall.deferred_notice")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Text("subscription.paywall.terms_privacy_placeholder")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("subscription-paywall-legal-notice")
    }

    private var primaryActionTitleKey: String {
        if subscriptionStatus.isSubscriber {
            return "subscription.paywall.cta.already_unlocked"
        }

        #if DEBUG
        return "subscription.paywall.cta.debug_unlock"
        #else
        return "subscription.paywall.cta.deferred"
        #endif
    }

    private var primaryActionIconName: String {
        if subscriptionStatus.isSubscriber || actionState == .success {
            return "checkmark.seal.fill"
        }
        return "lock.open.fill"
    }

    private var primaryActionDisabled: Bool {
        #if DEBUG
        return actionState == .processing || subscriptionStatus.isSubscriber
        #else
        return true
        #endif
    }

    private var primaryActionBackground: LinearGradient {
        let colors: [Color]
        if primaryActionDisabled && !subscriptionStatus.isSubscriber {
            colors = [Color.gray.opacity(0.54), Color.gray.opacity(0.38)]
        } else {
            colors = [accentColor, accentColor.opacity(0.72)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func handlePrimaryAction() {
        #if DEBUG
        actionState = .processing
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            subscriptionStatus.setDebugSubscriptionOverride(true)
            actionState = .success
        }
        #else
        actionState = .failed
        #endif
    }

    private var heroSubtitleKey: String {
        if lockedFeature != nil {
            return "subscription.paywall.subtitle.locked_feature"
        }
        return "subscription.paywall.subtitle.general"
    }

    private var featureAccentColor: Color? {
        guard let lockedFeature else { return nil }
        switch lockedFeature {
        case .inlineFitnessMode:
            return SkateTrackSessionStartColors.teal
        case .inlineAggressiveMode:
            return SkateTrackSessionStartColors.accent
        case .inlineSlalomMode:
            return SkateTrackSessionStartColors.blueCold
        default:
            return SkateTrackSessionStartColors.purple
        }
    }
}

enum SubscriptionPaywallActionState: Equatable {
    case idle
    case processing
    case success
    case cancelled
    case failed

    var messageKey: String {
        switch self {
        case .idle:
            return "subscription.paywall.state.idle"
        case .processing:
            return "subscription.paywall.state.processing"
        case .success:
            return "subscription.paywall.state.success"
        case .cancelled:
            return "subscription.paywall.state.cancelled"
        case .failed:
            return "subscription.paywall.state.failed"
        }
    }
}

#Preview("Paywall") {
    SubscriptionPaywallView(
        subscriptionStatus: useSubscriptionStatus(),
        lockedFeature: .inlineFitnessMode
    )
}
