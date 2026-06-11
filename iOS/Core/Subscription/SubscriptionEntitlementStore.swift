// [自主區] SubscriptionEntitlementStore.swift
// 用途：保存與刷新目前訂閱權限快照，是 FeatureFlagEngine 與 StoreKit provider 之間的狀態邊界。
// 委派至：SubscriptionEntitlementProviding 取得權限；Task-016a 預設使用 LocalSubscriptionEntitlementProvider。

import Combine
import Foundation

@MainActor
final class SubscriptionEntitlementStore: ObservableObject {
    static let shared = SubscriptionEntitlementStore()

    @Published private(set) var snapshot: SubscriptionEntitlementSnapshot

    private let provider: SubscriptionEntitlementProviding
    private let cache: UserDefaults
    private let cacheKey = "com.skatetrack.subscription.entitlement.snapshot.v1"

    init(
        provider: SubscriptionEntitlementProviding? = nil,
        cache: UserDefaults = .standard,
        initialSnapshot: SubscriptionEntitlementSnapshot? = nil
    ) {
        self.provider = provider ?? LocalSubscriptionEntitlementProvider()
        self.cache = cache
        self.snapshot = initialSnapshot ?? Self.loadSnapshot(from: cache, key: cacheKey) ?? .notConfigured
    }

    func refresh() async {
        let nextSnapshot = await provider.currentEntitlement()
        apply(nextSnapshot)
    }

    func apply(_ nextSnapshot: SubscriptionEntitlementSnapshot) {
        snapshot = nextSnapshot
        persist(nextSnapshot)
    }

    func clearCachedSnapshot() {
        cache.removeObject(forKey: cacheKey)
        snapshot = .notConfigured
    }

    private func persist(_ nextSnapshot: SubscriptionEntitlementSnapshot) {
        guard nextSnapshot.source.shouldPersist else { return }

        do {
            let data = try JSONEncoder().encode(nextSnapshot)
            cache.set(data, forKey: cacheKey)
        } catch {
            cache.removeObject(forKey: cacheKey)
        }
    }

    private static func loadSnapshot(from cache: UserDefaults, key: String) -> SubscriptionEntitlementSnapshot? {
        guard let data = cache.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SubscriptionEntitlementSnapshot.self, from: data)
    }
}
