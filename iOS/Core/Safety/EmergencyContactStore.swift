// [自主區] iOS/Core/Safety/EmergencyContactStore.swift
// 用途：提供 Phase 1a 本機緊急聯絡人儲存，不接通訊錄權限或背景自動發送訊息。
// 委派至：EmergencyContactsSettingsView、SOSEventDispatcher、Task-015 persistence。

import Combine
import Foundation

final class EmergencyContactStore: ObservableObject {
    static let shared = EmergencyContactStore()

    @Published private(set) var contacts: [EmergencyContact]

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "skateTrack.emergencyContacts.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.contacts = Self.loadContacts(from: userDefaults, key: storageKey, decoder: JSONDecoder())
    }

    var usableContacts: [EmergencyContact] {
        contacts.filter(\.isUsableForSOS)
    }

    var hasUsableContacts: Bool {
        !usableContacts.isEmpty
    }

    var primaryContact: EmergencyContact? {
        usableContacts.first(where: \.isPrimary) ?? usableContacts.first
    }

    func saveContact(_ contact: EmergencyContact) {
        let normalizedContact = normalizePrimary(contact)
        if let index = contacts.firstIndex(where: { $0.id == normalizedContact.id }) {
            contacts[index] = normalizedContact
        } else {
            contacts.append(normalizedContact)
        }
        enforcePrimaryContactIfNeeded()
        persist()
    }

    func removeContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        enforcePrimaryContactIfNeeded()
        persist()
    }

    func replaceContacts(_ nextContacts: [EmergencyContact]) {
        contacts = nextContacts.filter(\.isUsableForSOS)
        enforcePrimaryContactIfNeeded()
        persist()
    }

    func clearContacts() {
        contacts.removeAll()
        persist()
    }

    private func normalizePrimary(_ contact: EmergencyContact) -> EmergencyContact {
        let normalized = contact
        if normalized.isPrimary {
            contacts = contacts.map { existing in
                var mutable = existing
                mutable.isPrimary = existing.id == normalized.id
                return mutable
            }
        }
        return normalized
    }

    private func enforcePrimaryContactIfNeeded() {
        guard !contacts.isEmpty else { return }
        let primaryCount = contacts.filter(\.isPrimary).count
        if primaryCount == 0 {
            contacts[0].isPrimary = true
        } else if primaryCount > 1 {
            var didKeepPrimary = false
            contacts = contacts.map { contact in
                var mutable = contact
                if mutable.isPrimary && !didKeepPrimary {
                    didKeepPrimary = true
                } else {
                    mutable.isPrimary = false
                }
                return mutable
            }
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(contacts)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save emergency contacts: \(error)")
        }
    }

    private static func loadContacts(
        from userDefaults: UserDefaults,
        key: String,
        decoder: JSONDecoder
    ) -> [EmergencyContact] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            return try decoder.decode([EmergencyContact].self, from: data)
        } catch {
            return []
        }
    }
}
