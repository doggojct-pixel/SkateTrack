// [自主區] DebugSubscriptionEntitlementProvider.swift
// 用途：提供 DEBUG-only 訂閱權限覆寫快照，避免 View 直接硬寫假訂閱狀態。
// 委派至：FeatureFlagEngine 在 DEBUG builds 中套用；Release builds 透過 #if DEBUG 完全排除。

#if DEBUG
import Foundation

@MainActor
final class DebugSubscriptionEntitlementProvider: SubscriptionEntitlementProviding {
    let source: SubscriptionEntitlementSource = .debugOverride
    private(set) var overrideValue: Bool?

    func setOverride(_ isSubscriber: Bool?) {
        overrideValue = isSubscriber
    }

    func currentEntitlement() async -> SubscriptionEntitlementSnapshot {
        guard let overrideValue else {
            return SubscriptionEntitlementSnapshot(
                state: .unknown,
                source: .debugOverride,
                statusMessageKey: "subscription.entitlement.status.debug_override_inactive"
            )
        }

        return snapshot(for: overrideValue)
    }

    func snapshot(for isSubscriber: Bool) -> SubscriptionEntitlementSnapshot {
        SubscriptionEntitlementSnapshot(
            state: isSubscriber ? .subscriber : .free,
            source: .debugOverride,
            statusMessageKey: isSubscriber
                ? "subscription.entitlement.status.debug_subscriber"
                : "subscription.entitlement.status.debug_free"
        )
    }
}
#endif
