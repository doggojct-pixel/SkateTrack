// [自主區] AuthTokenStore.swift
// 用途：保留未來 OAuth token 儲存邊界；Task-025a 僅記錄非敏感 provider metadata，不保存真 token。
// 委派至：未來正式 Google integration 在 credentials / Keychain policy 完成後替換實作。

import Foundation

protocol AuthTokenStoring: AnyObject, Sendable {
    func markPlaceholderSession(providerKind: AuthProviderKind)
    func clearPlaceholderSession(providerKind: AuthProviderKind)
    func hasProductionToken(for providerKind: AuthProviderKind) -> Bool
}

final class AuthTokenStore: AuthTokenStoring, @unchecked Sendable {
    static let shared = AuthTokenStore()

    private let cache: UserDefaults
    private let placeholderPrefix = "com.skatetrack.account.placeholderProvider."

    init(cache: UserDefaults = .standard) {
        self.cache = cache
    }

    func markPlaceholderSession(providerKind: AuthProviderKind) {
        cache.set(Date().timeIntervalSince1970, forKey: placeholderKey(for: providerKind))
    }

    func clearPlaceholderSession(providerKind: AuthProviderKind) {
        cache.removeObject(forKey: placeholderKey(for: providerKind))
    }

    func hasProductionToken(for providerKind: AuthProviderKind) -> Bool {
        false
    }

    private func placeholderKey(for providerKind: AuthProviderKind) -> String {
        placeholderPrefix + providerKind.rawValue
    }
}
