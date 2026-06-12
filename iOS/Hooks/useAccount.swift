// [協作區 — 邊界適配層] useAccount.swift
// 用途：向 SwiftUI 暴露 Task-025a 帳號狀態，隱藏 local / disabled provider 與 token placeholder 細節。
// 委派至：iOS/Core/Account providers；未來 AccountSettingsView 不直接碰 Google SDK 或 token storage。

import Combine
import SwiftUI

@MainActor
final class AccountViewModel: ObservableObject {
    @Published private(set) var session: AuthSession
    @Published private(set) var googleSession: AuthSession
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessageKey: String?

    private let localProvider: AuthProvider
    private let googleProvider: GoogleSignInProviding
    private let tokenStore: AuthTokenStoring

    init() {
        let defaultLocalProvider = LocalAccountProvider.shared
        let defaultGoogleProvider = DisabledGoogleAuthProvider.shared
        let defaultTokenStore = AuthTokenStore.shared

        self.localProvider = defaultLocalProvider
        self.googleProvider = defaultGoogleProvider
        self.tokenStore = defaultTokenStore
        self.session = .signedOut(providerKind: defaultLocalProvider.providerKind)
        self.googleSession = .googleUnavailable()
    }

    init(
        localProvider: AuthProvider,
        googleProvider: GoogleSignInProviding,
        tokenStore: AuthTokenStoring
    ) {
        self.localProvider = localProvider
        self.googleProvider = googleProvider
        self.tokenStore = tokenStore
        self.session = .signedOut(providerKind: localProvider.providerKind)
        self.googleSession = .googleUnavailable()
    }

    var isSignedIn: Bool {
        session.isSignedIn
    }

    var statusMessageKey: String {
        errorMessageKey ?? session.statusMessageKey
    }

    var googleProviderDisplayNameKey: String {
        googleProvider.providerDisplayNameKey
    }

    var googleUnavailableMessageKey: String {
        googleSession.statusMessageKey
    }

    func refresh() {
        Task { @MainActor in
            await refreshCurrentSession()
        }
    }

    func requestGoogleSignIn() {
        Task { @MainActor in
            await attemptGoogleSignIn()
        }
    }

    func signOut() {
        Task { @MainActor in
            isLoading = true
            session = await localProvider.signOut()
            tokenStore.clearPlaceholderSession(providerKind: localProvider.providerKind)
            isLoading = false
        }
    }

    #if DEBUG
    func signInWithLocalSimulation() {
        Task { @MainActor in
            await attemptLocalSimulationSignIn()
        }
    }
    #endif

    private func refreshCurrentSession() async {
        isLoading = true
        errorMessageKey = nil
        session = await localProvider.currentSession()
        googleSession = await googleProvider.currentSession()
        if session.isSignedIn {
            tokenStore.markPlaceholderSession(providerKind: session.providerKind)
        }
        isLoading = false
    }

    private func attemptGoogleSignIn() async {
        isLoading = true
        errorMessageKey = nil
        do {
            session = try await googleProvider.signIn()
        } catch let error as AuthProviderError {
            googleSession = await googleProvider.currentSession()
            errorMessageKey = error.localizationKey
        } catch {
            errorMessageKey = "account.auth.error.generic"
        }
        isLoading = false
    }

    #if DEBUG
    private func attemptLocalSimulationSignIn() async {
        isLoading = true
        errorMessageKey = nil
        do {
            session = try await localProvider.signIn()
            tokenStore.markPlaceholderSession(providerKind: session.providerKind)
        } catch let error as AuthProviderError {
            errorMessageKey = error.localizationKey
        } catch {
            errorMessageKey = "account.auth.error.generic"
        }
        isLoading = false
    }
    #endif
}

@MainActor
func useAccount() -> AccountViewModel {
    AccountViewModel()
}
