// [自主區] PurchaseProductCatalog.swift
// 用途：集中定義未來 StoreKit 2 訂閱商品 ID，避免價格與 product identifier 散落在 View 或 FeatureFlagEngine。
// 委派至：Task-016c AppStoreSubscriptionProvider 與 App Store Connect 商品設定對齊。

import Foundation

enum PurchaseProductCatalog {
    static let monthlySubscriptionProductID = "com.skatetrack.subscription.monthly"
    static let yearlySubscriptionProductID = "com.skatetrack.subscription.yearly"

    static let activeProductIdentifiers: [String] = [
        monthlySubscriptionProductID
    ]

    static let reservedProductIdentifiers: [String] = [
        yearlySubscriptionProductID
    ]
}
