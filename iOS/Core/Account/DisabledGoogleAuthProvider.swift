// [自主區] DisabledGoogleAuthProvider.swift
// 用途：在沒有 Google OAuth client ID / URL scheme / production credentials 時，提供明確的不可用帳號 provider。
// 委派至：useAccount 與未來 AccountSettingsView 呈現 blocked state；不 import Google SDK、不啟動 OAuth flow。

import Foundation

@MainActor
final class DisabledGoogleAuthProvider: GoogleSignInProviding, @unchecked Sendable {
    static let shared = DisabledGoogleAuthProvider()

    let providerKind: AuthProviderKind = .googleDisabled
    let providerDisplayNameKey = "account.provider.google_disabled"
    let requiredConfigurationDescriptionKey = "account.google.deferred.subtitle"
    let isProductionProviderAvailable = false

    func currentSession() async -> AuthSession {
        .googleUnavailable()
    }

    func signIn() async throws -> AuthSession {
        throw AuthProviderError.providerUnavailable(
            messageKey: "account.auth.error.google_unconfigured"
        )
    }

    func signOut() async -> AuthSession {
        .googleUnavailable()
    }
}
