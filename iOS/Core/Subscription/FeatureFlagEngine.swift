// [自主區] FeatureFlagEngine.swift
// 用途：集中判斷免費與訂閱功能存取權，是 iOS 訂閱門禁的唯一真實來源。
// 委派至：Task-016 接入 StoreKit 權利；目前以 Phase 1a stub 和 DEBUG override 支援開發測試。

import Combine
import Foundation

enum SubscriptionEntitlementState: String, Codable, Sendable {
    case unknown
    case free
    case subscriber

    var isSubscriber: Bool {
        self == .subscriber
    }
}

@MainActor
final class FeatureFlagEngine: ObservableObject {
    static let shared = FeatureFlagEngine()

    @Published private(set) var entitlementState: SubscriptionEntitlementState

    #if DEBUG
    @Published private(set) var debugSubscriptionOverride: Bool?
    #endif

    private init(entitlementState: SubscriptionEntitlementState = .free) {
        self.entitlementState = entitlementState
    }

    var isSubscriber: Bool {
        #if DEBUG
        if let debugSubscriptionOverride {
            return debugSubscriptionOverride
        }
        #endif

        return entitlementState.isSubscriber
    }

    func refreshEntitlements() {
        entitlementState = .free
    }

    func hasAccess(to feature: GatedFeature) -> Bool {
        isSubscriber
    }

    func hasAccess(to feature: FreeFeature) -> Bool {
        true
    }

    #if DEBUG
    func setDebugSubscriptionOverride(_ isEnabled: Bool) {
        debugSubscriptionOverride = isEnabled
    }

    func clearDebugSubscriptionOverride() {
        debugSubscriptionOverride = nil
    }
    #endif
}
