// [自主區] FeatureFlagEngine.swift
// 用途：集中判斷免費與訂閱功能存取權，是 iOS 訂閱門禁的唯一真實來源。
// 委派至：SubscriptionEntitlementStore 取得可替換權限快照；DEBUG override 僅存在於 DEBUG builds。

import Combine
import Foundation

@MainActor
final class FeatureFlagEngine: ObservableObject {
    static let shared = FeatureFlagEngine()

    @Published private(set) var entitlementSnapshot: SubscriptionEntitlementSnapshot

    #if DEBUG
    @Published private(set) var debugSubscriptionOverride: Bool?
    private let debugEntitlementProvider: DebugSubscriptionEntitlementProvider
    #endif

    private let entitlementStore: SubscriptionEntitlementStore
    private var cancellables = Set<AnyCancellable>()

    init(entitlementStore: SubscriptionEntitlementStore? = nil) {
        // Avoid chaining two @MainActor static singleton initializers during app/test launch.
        // FeatureFlagEngine remains the single app-facing source of truth; tests can still inject a store.
        let resolvedEntitlementStore = entitlementStore ?? SubscriptionEntitlementStore()

        self.entitlementStore = resolvedEntitlementStore
        self.entitlementSnapshot = resolvedEntitlementStore.snapshot

        #if DEBUG
        self.debugEntitlementProvider = DebugSubscriptionEntitlementProvider()
        #endif

        resolvedEntitlementStore.$snapshot
            .sink { [weak self] snapshot in
                Task { @MainActor [weak self] in
                    self?.entitlementSnapshot = snapshot
                }
            }
            .store(in: &cancellables)

        refreshEntitlements()
    }

    var effectiveEntitlementSnapshot: SubscriptionEntitlementSnapshot {
        #if DEBUG
        if let debugSubscriptionOverride {
            return debugEntitlementProvider.snapshot(for: debugSubscriptionOverride)
        }
        #endif

        return entitlementSnapshot
    }

    var entitlementState: SubscriptionEntitlementState {
        effectiveEntitlementSnapshot.state
    }

    var isSubscriber: Bool {
        effectiveEntitlementSnapshot.isSubscriber
    }

    var entitlementSourceDescriptionKey: String {
        effectiveEntitlementSnapshot.source.localizedDescriptionKey
    }

    var entitlementStatusMessageKey: String {
        effectiveEntitlementSnapshot.statusMessageKey
    }

    func refreshEntitlements() {
        Task { @MainActor [entitlementStore] in
            await entitlementStore.refresh()
        }
    }

    func hasAccess(to feature: GatedFeature) -> Bool {
        isSubscriber
    }

    func hasAccess(to feature: FreeFeature) -> Bool {
        true
    }

    #if DEBUG
    var isDebugSubscriptionOverrideActive: Bool {
        debugSubscriptionOverride != nil
    }

    func setDebugSubscriptionOverride(_ isEnabled: Bool) {
        debugEntitlementProvider.setOverride(isEnabled)
        debugSubscriptionOverride = isEnabled
    }

    func clearDebugSubscriptionOverride() {
        debugEntitlementProvider.setOverride(nil)
        debugSubscriptionOverride = nil
    }
    #endif
}
