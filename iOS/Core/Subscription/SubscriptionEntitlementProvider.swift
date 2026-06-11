// [自主區] SubscriptionEntitlementProvider.swift
// 用途：定義訂閱權限來源的可替換協定，讓 Debug/local simulation 與未來 StoreKit 2 provider 使用同一個邊界。
// 委派至：SubscriptionEntitlementStore 呼叫 provider 取得最新 entitlement snapshot。

import Foundation

@MainActor
protocol SubscriptionEntitlementProviding: AnyObject {
    var source: SubscriptionEntitlementSource { get }
    func currentEntitlement() async -> SubscriptionEntitlementSnapshot
}
