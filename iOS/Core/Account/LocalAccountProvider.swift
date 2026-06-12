// [自主區] LocalAccountProvider.swift
// 用途：提供 DEBUG-only 本機帳號登入模擬，讓 UI / sync 前置流程可在沒有 Google OAuth credentials 時開發。
// 委派至：useAccount 控制 DEBUG 操作；Release builds 不啟用本機假登入。

import Foundation

@MainActor
final class LocalAccountProvider: AuthProvider, @unchecked Sendable {
    static let shared = LocalAccountProvider()

    let providerKind: AuthProviderKind = .localSimulation
    let providerDisplayNameKey = "account.provider.local_simulation"
    let isProductionProviderAvailable = false

    private let cache: UserDefaults
    private let cacheKey = "com.skatetrack.account.localSimulation.session.v1"

    init(cache: UserDefaults = .standard) {
        self.cache = cache
    }

    func currentSession() async -> AuthSession {
        #if DEBUG
        return loadCachedSession() ?? .signedOut(providerKind: providerKind)
        #else
        return .signedOut(providerKind: providerKind)
        #endif
    }

    func signIn() async throws -> AuthSession {
        #if DEBUG
        let session = AuthSession.localSimulationSignedIn()
        save(session)
        return session
        #else
        throw AuthProviderError.providerUnavailable(
            messageKey: "account.auth.error.local_simulation_release_unavailable"
        )
        #endif
    }

    func signOut() async -> AuthSession {
        cache.removeObject(forKey: cacheKey)
        return .signedOut(providerKind: providerKind)
    }

    private func save(_ session: AuthSession) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(session)
            cache.set(data, forKey: cacheKey)
        } catch {
            cache.removeObject(forKey: cacheKey)
        }
    }

    private func loadCachedSession() -> AuthSession? {
        guard let data = cache.data(forKey: cacheKey) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AuthSession.self, from: data)
        } catch {
            cache.removeObject(forKey: cacheKey)
            return nil
        }
    }
}
