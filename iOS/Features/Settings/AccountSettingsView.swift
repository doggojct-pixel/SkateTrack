// [協作區] AccountSettingsView.swift
// 用途：呈現 Task-025b 帳號設定頁基礎 UI，顯示本機優先、DEBUG 模擬與 Google 登入延後狀態。
// 委派至：useAccount / AccountViewModel；此 View 不直接碰 Google SDK、OAuth token、Drive scope 或 Keychain policy。

import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var viewModel: AccountViewModel

    @MainActor
    init(viewModel: AccountViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? useAccount())
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                            .padding(.top, proxy.safeAreaInsets.top + 24)
                        statusCard
                        googleDeferredCard
                        #if DEBUG
                        debugSimulationCard
                        #endif
                        localFirstCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(34, proxy.safeAreaInsets.bottom + 28))
                }
                .refreshable { viewModel.refresh() }
            }
        }
        .onAppear { viewModel.refresh() }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("account-settings-view")
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
                colors: [SkateTrackSessionStartColors.teal.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 430
            )
            RadialGradient(
                colors: [SkateTrackSessionStartColors.purple.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 360
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("account.eyebrow")
                .tracking(2)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .textCase(.uppercase)

            Text("account.title")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("account.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle(
                titleKey: "account.status.card.title",
                subtitleKey: viewModel.statusMessageKey,
                iconName: "person.crop.circle"
            )

            Divider().overlay(SkateTrackSessionStartColors.border)

            statusRow(
                titleKey: "account.status.provider",
                valueKey: viewModel.session.providerKind.localizationKey
            )
            statusRow(
                titleKey: "account.status.state",
                valueKey: viewModel.session.state.localizationKey
            )

            if let account = viewModel.session.account {
                infoRow(titleKey: "account.status.profile", value: account.displayName)
                infoRow(
                    titleKey: "account.status.email",
                    value: account.email ?? localizedFallbackEmail
                )
            } else {
                statusRow(
                    titleKey: "account.status.profile",
                    valueKey: "account.status.placeholder_profile"
                )
            }

            Button {
                viewModel.refresh()
            } label: {
                actionLabel(titleKey: "account.status.refresh", iconName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("account-refresh-button")
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("account-status-card")
    }

    private var googleDeferredCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                titleKey: "account.google.deferred.title",
                subtitleKey: "account.google.deferred.subtitle",
                iconName: "g.circle"
            )

            statusRow(
                titleKey: "account.google.provider",
                valueKey: viewModel.googleProviderDisplayNameKey
            )
            statusRow(
                titleKey: "account.google.state",
                valueKey: viewModel.googleUnavailableMessageKey
            )

            Text("account.google.drive_deferred")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.requestGoogleSignIn()
            } label: {
                actionLabel(titleKey: "account.google.action_unavailable", iconName: "lock.shield")
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("account-google-unavailable-button")
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("account-google-deferred-card")
    }

    #if DEBUG
    private var debugSimulationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                titleKey: "account.debug.card.title",
                subtitleKey: "account.debug.card.subtitle",
                iconName: "ladybug"
            )

            Button {
                if viewModel.isSignedIn {
                    viewModel.signOut()
                } else {
                    viewModel.signInWithLocalSimulation()
                }
            } label: {
                actionLabel(
                    titleKey: viewModel.isSignedIn ? "account.debug.sign_out_local" : "account.debug.sign_in_local",
                    iconName: viewModel.isSignedIn ? "rectangle.portrait.and.arrow.right" : "person.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("account-local-simulation-button")
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("account-debug-simulation-card")
    }
    #endif

    private var localFirstCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(
                titleKey: "account.privacy.title",
                subtitleKey: "account.privacy.local_first",
                iconName: "externaldrive.badge.checkmark"
            )

            Text("account.provider_boundary.note")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("account-local-first-card")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(SkateTrackSessionStartColors.card.opacity(0.84))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
            )
    }

    private func cardTitle(titleKey: String, subtitleKey: String, iconName: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .frame(width: 34, height: 34)
                .background(SkateTrackSessionStartColors.teal.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(subtitleKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statusRow(titleKey: String, valueKey: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer(minLength: 14)
            Text(LocalizedStringKey(valueKey))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private func infoRow(titleKey: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer(minLength: 14)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(titleKey: String, iconName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
            Text(LocalizedStringKey(titleKey))
            Spacer(minLength: 0)
            if viewModel.isLoading {
                ProgressView()
                    .tint(SkateTrackSessionStartColors.teal)
            }
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(SkateTrackSessionStartColors.teal)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.teal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SkateTrackSessionStartColors.teal.opacity(0.28), lineWidth: 1)
        )
    }

    private var localizedFallbackEmail: String {
        String(localized: "account.status.no_email")
    }
}

#Preview("Account Settings") {
    AccountSettingsView()
}
