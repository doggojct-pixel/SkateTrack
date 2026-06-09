// [協作區] Shared/Protocols/SyncProvider.swift
// 用途：定義 session 跨裝置與雲端同步提供者的最小介面。
// 委派至：AirDrop import、Google Drive sync、iCloud optional sync 與 macOS session browser。

import Foundation

protocol SyncProvider: AnyObject {
    func uploadSession(_ session: SessionData) async throws
    func fetchAllSessions() async throws -> [SessionData]
    func deleteSession(id: UUID) async throws
}
