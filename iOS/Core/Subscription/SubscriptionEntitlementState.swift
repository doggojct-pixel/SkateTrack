// [自主區] SubscriptionEntitlementState.swift
// 用途：集中描述訂閱權限狀態、來源與狀態快照，供 FeatureFlagEngine 與未來 StoreKit provider 共用。
// 委派至：SubscriptionEntitlementStore 保存與刷新，目前 Task-016a 使用本機模擬來源，未來可替換為 AppStoreSubscriptionProvider。

import Foundation

enum SubscriptionEntitlementState: String, Codable, Equatable, Sendable {
    case unknown
    case free
    case subscriber
    case failed

    var isSubscriber: Bool {
        self == .subscriber
    }

    var localizedStatusKey: String {
        switch self {
        case .unknown:
            return "subscription.entitlement.status.unknown"
        case .free:
            return "subscription.entitlement.status.free"
        case .subscriber:
            return "subscription.entitlement.status.subscriber"
        case .failed:
            return "subscription.entitlement.status.failed"
        }
    }
}

enum SubscriptionEntitlementSource: String, Codable, Equatable, Sendable {
    case notConfigured
    case localSimulation
    case debugOverride
    case appStoreDeferred

    var localizedDescriptionKey: String {
        switch self {
        case .notConfigured:
            return "subscription.entitlement.source.not_configured"
        case .localSimulation:
            return "subscription.entitlement.source.local_simulation"
        case .debugOverride:
            return "subscription.entitlement.source.debug_override"
        case .appStoreDeferred:
            return "subscription.entitlement.source.app_store_deferred"
        }
    }

    var shouldPersist: Bool {
        switch self {
        case .debugOverride:
            return false
        case .notConfigured, .localSimulation, .appStoreDeferred:
            return true
        }
    }
}

struct SubscriptionEntitlementSnapshot: Codable, Equatable, Sendable {
    let state: SubscriptionEntitlementState
    let source: SubscriptionEntitlementSource
    let refreshedAt: Date
    let statusMessageKey: String

    init(
        state: SubscriptionEntitlementState,
        source: SubscriptionEntitlementSource,
        refreshedAt: Date = Date(),
        statusMessageKey: String? = nil
    ) {
        self.state = state
        self.source = source
        self.refreshedAt = refreshedAt
        self.statusMessageKey = statusMessageKey ?? state.localizedStatusKey
    }

    var isSubscriber: Bool {
        state.isSubscriber
    }

    static var notConfigured: SubscriptionEntitlementSnapshot {
        SubscriptionEntitlementSnapshot(
            state: .unknown,
            source: .notConfigured,
            statusMessageKey: "subscription.entitlement.status.not_configured"
        )
    }

    static var localFreeSimulation: SubscriptionEntitlementSnapshot {
        SubscriptionEntitlementSnapshot(
            state: .free,
            source: .localSimulation,
            statusMessageKey: "subscription.entitlement.status.local_simulation_free"
        )
    }

    static var appStoreDeferred: SubscriptionEntitlementSnapshot {
        SubscriptionEntitlementSnapshot(
            state: .free,
            source: .appStoreDeferred,
            statusMessageKey: "subscription.entitlement.status.app_store_deferred"
        )
    }
}
