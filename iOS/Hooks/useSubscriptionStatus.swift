// [協作區 — 邊界適配層] useSubscriptionStatus.swift
// 用途：向 SwiftUI Views 暴露訂閱狀態與功能門禁 API，隱藏自主區 FeatureFlagEngine 細節。
// 委派至：iOS/Core/Subscription/FeatureFlagEngine.swift 執行實際存取權判斷。

import Combine
import SwiftUI

@MainActor
final class SubscriptionStatusViewModel: ObservableObject {
    @Published private(set) var isSubscriber: Bool

    private let engine: FeatureFlagEngine
    private var cancellables = Set<AnyCancellable>()

    init(engine: FeatureFlagEngine = .shared) {
        self.engine = engine
        self.isSubscriber = engine.isSubscriber

        engine.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isSubscriber = engine.isSubscriber
                }
            }
            .store(in: &cancellables)
    }

    func hasAccess(to feature: GatedFeature) -> Bool {
        engine.hasAccess(to: feature)
    }

    func hasAccess(to feature: FreeFeature) -> Bool {
        engine.hasAccess(to: feature)
    }

    func refreshEntitlements() {
        engine.refreshEntitlements()
        isSubscriber = engine.isSubscriber
    }

    #if DEBUG
    var debugSubscriptionOverrideEnabled: Bool {
        engine.isSubscriber
    }

    func setDebugSubscriptionOverride(_ isEnabled: Bool) {
        engine.setDebugSubscriptionOverride(isEnabled)
        isSubscriber = engine.isSubscriber
    }

    func clearDebugSubscriptionOverride() {
        engine.clearDebugSubscriptionOverride()
        isSubscriber = engine.isSubscriber
    }
    #endif
}

@MainActor
func useSubscriptionStatus() -> SubscriptionStatusViewModel {
    SubscriptionStatusViewModel()
}

#if DEBUG
struct SubscriptionDebugPanel: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Text(LocalizedStringKey(subscriptionStatus.isSubscriber ? "subscription.subscriber" : "subscription.free"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("subscription-debug-panel")
    }
}
#endif
