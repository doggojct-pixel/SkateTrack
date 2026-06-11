// [自主區] LocalSubscriptionEntitlementProvider.swift
// 用途：在尚未具備 Apple Developer Program / App Store Connect 設定前，提供安全的本機免費權限模擬來源。
// 委派至：未來 AppStoreSubscriptionProvider 取代此 provider 後，FeatureFlagEngine 與 UI 不需要重寫。

import Foundation

@MainActor
final class LocalSubscriptionEntitlementProvider: SubscriptionEntitlementProviding {
    let source: SubscriptionEntitlementSource = .localSimulation

    func currentEntitlement() async -> SubscriptionEntitlementSnapshot {
        .localFreeSimulation
    }
}
