// [協作區] iOS/Features/FallDetection/EmergencyContactsSettingsView.swift
// 用途：提供 Phase 1a 緊急聯絡人設定 UI，不接系統通訊錄或自動背景簡訊。
// 委派至：EmergencyContactStore 與 SOSEventDispatcher。

import SwiftUI
import UIKit

struct EmergencyContactsSettingsView: View {
    @ObservedObject private var store: EmergencyContactStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var note = ""
    @State private var relationship: EmergencyContactRelationship = .family
    @State private var isPrimary = true

    init(store: EmergencyContactStore = .shared) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SkateTrackSessionStartColors.navy.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        contactForm
                        savedContacts
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                }
            }
            .navigationTitle(Text("safety.contacts.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("emergency-contacts-settings-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("safety.contacts.headline")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("safety.contacts.description")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineSpacing(4)
        }
    }

    private var contactForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            formTitle("safety.contacts.addTitle")
            contactTextField("safety.contacts.namePlaceholder", text: $name, systemImage: "person.fill")
            contactTextField("safety.contacts.phonePlaceholder", text: $phone, systemImage: "phone.fill", keyboardType: .phonePad)
            relationshipPicker
            contactTextField("safety.contacts.notePlaceholder", text: $note, systemImage: "note.text")
            Toggle(isOn: $isPrimary) {
                Text("safety.contacts.primaryToggle")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .tint(SkateTrackSessionStartColors.teal)

            Button(action: saveContact) {
                Label("safety.contacts.save", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .background(canSave ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(!canSave)
            .accessibilityIdentifier("emergency-contact-save-button")
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }

    private var relationshipPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("safety.contacts.relationship.title")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Picker("safety.contacts.relationship.title", selection: $relationship) {
                ForEach(EmergencyContactRelationship.allCases, id: \.self) { relationship in
                    Text(LocalizedStringKey(relationship.localizationKey)).tag(relationship)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var savedContacts: some View {
        VStack(alignment: .leading, spacing: 12) {
            formTitle("safety.contacts.savedTitle")
            if store.contacts.isEmpty {
                emptyContactCard
            } else {
                ForEach(store.contacts) { contact in
                    savedContactRow(contact)
                }
            }
        }
    }

    private var emptyContactCard: some View {
        Text("safety.contacts.empty")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SkateTrackSessionStartColors.card.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityIdentifier("emergency-contacts-empty-state")
    }

    private func savedContactRow(_ contact: EmergencyContact) -> some View {
        HStack(spacing: 12) {
            Image(systemName: contact.isPrimary ? "star.circle.fill" : "person.crop.circle.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(contact.isPrimary ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)
            VStack(alignment: .leading, spacing: 3) {
                Text(contact.displayName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(contact.phoneNumber)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                Text(LocalizedStringKey(contact.relationship.localizationKey))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            }
            Spacer()
            Button(role: .destructive) {
                store.removeContact(id: contact.id)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SkateTrackSessionStartColors.accent)
                    .padding(10)
            }
            .accessibilityIdentifier("emergency-contact-delete-button")
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }

    private func formTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            .textCase(.uppercase)
    }

    private func contactTextField(
        _ key: LocalizedStringKey,
        text: Binding<String>,
        systemImage: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .frame(width: 20)
            TextField(key, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .padding(13)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }

    private var cardBackground: some View {
        ZStack {
            SkateTrackSessionStartColors.navy2.opacity(0.94)
            RadialGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 8,
                endRadius: 240
            )
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveContact() {
        guard canSave else { return }
        let contact = EmergencyContact(
            displayName: name,
            phoneNumber: phone,
            relationship: relationship,
            note: note,
            isPrimary: isPrimary || store.contacts.isEmpty
        )
        store.saveContact(contact)
        name = ""
        phone = ""
        note = ""
        relationship = .family
        isPrimary = store.contacts.isEmpty
    }
}

#Preview("Emergency Contacts") {
    EmergencyContactsSettingsView(store: EmergencyContactStore(userDefaults: .standard, storageKey: "preview.emergencyContacts"))
}
