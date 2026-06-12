// [自主區] AuthProvider.swift
// 用途：定義 Task-025a 帳號 provider 邊界，讓 local simulation、disabled Google 與未來正式 provider 可替換。
// 委派至：useAccount 向 SwiftUI 暴露狀態；未來 Google provider 必須在 credentials / URL scheme 準備後另開任務加入。

import Foundation

enum AuthProviderError: Error, Equatable {
    case providerUnavailable(messageKey: String)
    case productionCredentialsMissing
    case tokenStorageUnavailable

    var localizationKey: String {
        switch self {
        case .providerUnavailable(let messageKey):
            return messageKey
        case .productionCredentialsMissing:
            return "account.auth.error.production_credentials_missing"
        case .tokenStorageUnavailable:
            return "account.auth.error.token_storage_unavailable"
        }
    }
}

@MainActor
protocol AuthProvider: AnyObject {
    var providerKind: AuthProviderKind { get }
    var providerDisplayNameKey: String { get }
    var isProductionProviderAvailable: Bool { get }

    func currentSession() async -> AuthSession
    func signIn() async throws -> AuthSession
    func signOut() async -> AuthSession
}

@MainActor
protocol GoogleSignInProviding: AuthProvider {
    var requiredConfigurationDescriptionKey: String { get }
}
