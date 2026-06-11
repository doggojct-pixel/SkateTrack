// [協作區] Shared/Models/EmergencyContact.swift
// 用途：定義緊急聯絡人資料，供 SOS dispatcher、Fall Alert UI 與後續持久化使用。
// 委派至：EmergencyContactStore、SOSEventDispatcher、Task-015 persistence。

import Foundation

enum EmergencyContactRelationship: String, Codable, Sendable, CaseIterable, Equatable {
    case family
    case partner
    case friend
    case coach
    case other

    var localizationKey: String {
        switch self {
        case .family: return "safety.contacts.relationship.family"
        case .partner: return "safety.contacts.relationship.partner"
        case .friend: return "safety.contacts.relationship.friend"
        case .coach: return "safety.contacts.relationship.coach"
        case .other: return "safety.contacts.relationship.other"
        }
    }
}

struct EmergencyContact: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var displayName: String
    var phoneNumber: String
    var relationship: EmergencyContactRelationship
    var note: String
    var isPrimary: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        phoneNumber: String,
        relationship: EmergencyContactRelationship = .family,
        note: String = "",
        isPrimary: Bool = false
    ) {
        self.id = id
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.relationship = relationship
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isPrimary = isPrimary
    }

    var isUsableForSOS: Bool {
        !displayName.isEmpty && !phoneNumber.isEmpty
    }

    var sanitizedPhoneNumber: String {
        phoneNumber.filter { character in
            character.isNumber || character == "+"
        }
    }
}
