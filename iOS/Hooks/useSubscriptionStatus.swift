// [協作區 — 邊界適配層] useSubscriptionStatus.swift
// 用途：向 SwiftUI Views 暴露訂閱狀態與功能門禁 API，隱藏自主區 FeatureFlagEngine 細節。
// 委派至：iOS/Core/Subscription/FeatureFlagEngine.swift 執行實際存取權判斷。

import Combine
import SwiftUI

@MainActor
final class SubscriptionStatusViewModel: ObservableObject {
    @Published private(set) var isSubscriber: Bool
    @Published private(set) var entitlementState: SubscriptionEntitlementState
    @Published private(set) var entitlementSourceDescriptionKey: String
    @Published private(set) var entitlementStatusMessageKey: String

    #if DEBUG
    @Published private(set) var debugSubscriptionOverride: Bool?
    #endif

    private let engine: FeatureFlagEngine
    private var cancellables = Set<AnyCancellable>()

    init(engine: FeatureFlagEngine) {
        self.engine = engine
        self.isSubscriber = engine.isSubscriber
        self.entitlementState = engine.entitlementState
        self.entitlementSourceDescriptionKey = engine.entitlementSourceDescriptionKey
        self.entitlementStatusMessageKey = engine.entitlementStatusMessageKey

        #if DEBUG
        self.debugSubscriptionOverride = engine.debugSubscriptionOverride
        #endif

        engine.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.syncFromEngine()
                }
            }
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(engine: FeatureFlagEngine.shared)
    }

    func hasAccess(to feature: GatedFeature) -> Bool {
        engine.hasAccess(to: feature)
    }

    func hasAccess(to feature: FreeFeature) -> Bool {
        engine.hasAccess(to: feature)
    }

    var productionPurchaseAvailable: Bool {
        false
    }

    func refreshEntitlements() {
        engine.refreshEntitlements()
        syncFromEngine()
    }

    func requestRestorePurchases() {
        refreshEntitlements()
    }

    private func syncFromEngine() {
        isSubscriber = engine.isSubscriber
        entitlementState = engine.entitlementState
        entitlementSourceDescriptionKey = engine.entitlementSourceDescriptionKey
        entitlementStatusMessageKey = engine.entitlementStatusMessageKey

        #if DEBUG
        debugSubscriptionOverride = engine.debugSubscriptionOverride
        #endif
    }

    #if DEBUG
    var debugSubscriptionOverrideEnabled: Bool {
        debugSubscriptionOverride == true
    }

    var debugSubscriptionOverrideActive: Bool {
        debugSubscriptionOverride != nil
    }

    func setDebugSubscriptionOverride(_ isEnabled: Bool) {
        engine.setDebugSubscriptionOverride(isEnabled)
        syncFromEngine()
    }

    func clearDebugSubscriptionOverride() {
        engine.clearDebugSubscriptionOverride()
        syncFromEngine()
    }
    #endif
}

@MainActor
func useSubscriptionStatus() -> SubscriptionStatusViewModel {
    SubscriptionStatusViewModel(engine: FeatureFlagEngine.shared)
}

#if DEBUG
struct SubscriptionDebugPanel: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("debug.subscription.title")
                .font(.caption.bold())

            Toggle(
                "debug.subscription.override_subscriber",
                isOn: Binding(
                    get: { subscriptionStatus.debugSubscriptionOverrideEnabled },
                    set: { subscriptionStatus.setDebugSubscriptionOverride($0) }
                )
            )
            .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(subscriptionStatus.isSubscriber ? "subscription.subscriber" : "subscription.free"))
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)

                Text(LocalizedStringKey(subscriptionStatus.entitlementSourceDescriptionKey))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(LocalizedStringKey(subscriptionStatus.entitlementStatusMessageKey))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if subscriptionStatus.debugSubscriptionOverrideActive {
                Button("debug.subscription.clear_override") {
                    subscriptionStatus.clearDebugSubscriptionOverride()
                }
                .font(.caption.bold())
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("subscription-debug-panel")
    }
}
#endif
