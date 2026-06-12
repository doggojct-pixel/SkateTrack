// [協作區] AuthSession.swift
// 用途：描述 Task-025a 帳號登入狀態與 provider 來源，不包含 OAuth token 或外部服務 secret。
// 委派至：iOS/Core/Account providers 與 useAccount hook 負責刷新、模擬與呈現狀態。

import Foundation

enum AuthProviderKind: String, Codable, Equatable, Sendable {
    case none
    case localSimulation
    case googleDisabled

    var localizationKey: String {
        switch self {
        case .none:
            return "account.provider.none"
        case .localSimulation:
            return "account.provider.local_simulation"
        case .googleDisabled:
            return "account.provider.google_disabled"
        }
    }
}

enum AuthSessionState: String, Codable, Equatable, Sendable {
    case signedOut
    case signedIn
    case unavailable

    var localizationKey: String {
        switch self {
        case .signedOut:
            return "account.status.signed_out"
        case .signedIn:
            return "account.status.local_simulation_signed_in"
        case .unavailable:
            return "account.status.google_unavailable"
        }
    }
}

struct AuthAccountProfile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let providerKind: AuthProviderKind
    var displayName: String
    var email: String?
    var avatarURL: URL?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        providerKind: AuthProviderKind,
        displayName: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.providerKind = providerKind
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

struct AuthSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var state: AuthSessionState
    var providerKind: AuthProviderKind
    var account: AuthAccountProfile?
    var refreshedAt: Date
    var statusMessageKey: String

    init(
        id: UUID = UUID(),
        state: AuthSessionState,
        providerKind: AuthProviderKind,
        account: AuthAccountProfile? = nil,
        refreshedAt: Date = Date(),
        statusMessageKey: String? = nil
    ) {
        self.id = id
        self.state = state
        self.providerKind = providerKind
        self.account = account
        self.refreshedAt = refreshedAt
        self.statusMessageKey = statusMessageKey ?? state.localizationKey
    }

    var isSignedIn: Bool {
        state == .signedIn && account != nil
    }

    static func signedOut(providerKind: AuthProviderKind = .none) -> AuthSession {
        AuthSession(
            state: .signedOut,
            providerKind: providerKind,
            statusMessageKey: "account.status.signed_out"
        )
    }

    static func localSimulationSignedIn(now: Date = Date()) -> AuthSession {
        let profile = AuthAccountProfile(
            providerKind: .localSimulation,
            displayName: "SkateTrack Local Rider",
            email: "local-rider@skatetrack.local",
            createdAt: now
        )
        return AuthSession(
            state: .signedIn,
            providerKind: .localSimulation,
            account: profile,
            refreshedAt: now,
            statusMessageKey: "account.status.local_simulation_signed_in"
        )
    }

    static func googleUnavailable(now: Date = Date()) -> AuthSession {
        AuthSession(
            state: .unavailable,
            providerKind: .googleDisabled,
            refreshedAt: now,
            statusMessageKey: "account.status.google_unavailable"
        )
    }
}
