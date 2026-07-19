// [協作區] EditEquipmentView.swift
// 用途：新增 / 編輯裝備表單，集中處理裝備類型、模式、里程與保養欄位輸入。
// 委派至：EquipmentListView 儲存資料，EquipmentRepository 實際寫入本機資料庫。

import SwiftUI
import UIKit

struct EditEquipmentView: View {
    let equipment: EquipmentProfile?
    let onSave: (EquipmentProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var equipmentType: EquipmentType
    @State private var selectedBoardMode: BoardMode
    @State private var selectedInlineMode: InlineMode
    @State private var powerType: PowerType
    @State private var hasPurchaseDate: Bool
    @State private var purchaseDate: Date
    @State private var totalDistanceKm: String
    @State private var wheelSetMileageKm: String
    @State private var bearingSetMileageKm: String
    @State private var wheelDiameterMillimeters: String
    @State private var wheelHardness: String
    @State private var bearingABEC: String
    @State private var brakeType: String
    @State private var notes: String
    @State private var errorKey: String?

    init(
        equipment: EquipmentProfile? = nil,
        onSave: @escaping (EquipmentProfile) -> Void
    ) {
        self.equipment = equipment
        self.onSave = onSave

        let resolvedType = equipment?.equipmentType ?? .skateboard
        let boardMode: BoardMode
        let inlineMode: InlineMode
        switch equipment?.sportMode ?? resolvedType.defaultSportMode {
        case let .skateboard(mode):
            boardMode = mode
            inlineMode = .urbanFreestyle
        case let .inline(mode):
            boardMode = .streetPark
            inlineMode = mode
        case .snow:
            // Snow gear editing is deferred; keep the existing gear editor on safe defaults.
            boardMode = .streetPark
            inlineMode = .urbanFreestyle
        }

        _name = State(initialValue: equipment?.name ?? "")
        _equipmentType = State(initialValue: resolvedType)
        _selectedBoardMode = State(initialValue: boardMode)
        _selectedInlineMode = State(initialValue: inlineMode)
        _powerType = State(initialValue: equipment?.powerType ?? .humanPowered)
        _hasPurchaseDate = State(initialValue: equipment?.purchaseDate != nil)
        _purchaseDate = State(initialValue: equipment?.purchaseDate ?? Date())
        _totalDistanceKm = State(initialValue: Self.numberString(equipment?.totalDistanceKm ?? 0))
        _wheelSetMileageKm = State(initialValue: Self.numberString(equipment?.wheelSetMileageKm ?? 0))
        _bearingSetMileageKm = State(initialValue: Self.numberString(equipment?.bearingSetMileageKm ?? 0))
        _wheelDiameterMillimeters = State(initialValue: Self.optionalNumberString(equipment?.wheelDiameterMillimeters))
        _wheelHardness = State(initialValue: equipment?.wheelHardness ?? "")
        _bearingABEC = State(initialValue: equipment?.bearingABEC ?? "")
        _brakeType = State(initialValue: equipment?.brakeType ?? "")
        _notes = State(initialValue: equipment?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    formSection("gear.form.section.identity") {
                        labeledTextField("gear.form.name", text: $name, accessibilityID: "equipment-form-name")
                        typePicker
                        modePicker
                        if equipmentType == .skateboard {
                            powerPicker
                        }
                    }

                    formSection("gear.form.section.mileage") {
                        labeledTextField("gear.totalMileage", text: $totalDistanceKm, keyboard: .decimalPad)
                        labeledTextField("gear.wheelSet", text: $wheelSetMileageKm, keyboard: .decimalPad)
                        labeledTextField("gear.bearings", text: $bearingSetMileageKm, keyboard: .decimalPad)
                    }

                    formSection("gear.form.section.setup") {
                        Toggle(LocalizedStringKey("gear.form.purchaseDate.enabled"), isOn: $hasPurchaseDate)
                            .tint(SkateTrackSessionStartColors.teal)
                        if hasPurchaseDate {
                            DatePicker(
                                "gear.form.purchaseDate",
                                selection: $purchaseDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                        }
                        labeledTextField("gear.form.wheelDiameter", text: $wheelDiameterMillimeters, keyboard: .decimalPad)
                        labeledTextField("gear.form.wheelHardness", text: $wheelHardness)
                        labeledTextField("gear.form.bearingABEC", text: $bearingABEC)
                        if equipmentType == .inlineSkates {
                            labeledTextField("gear.form.brakeType", text: $brakeType)
                        }
                    }

                    formSection("gear.form.section.notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 96)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(SkateTrackSessionStartColors.navy3.opacity(0.86))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("equipment-form-notes")
                    }

                    if let errorKey {
                        Text(LocalizedStringKey(errorKey))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SkateTrackSessionStartColors.accent2)
                    }
                }
                .padding(20)
                .padding(.bottom, 28)
            }
            .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
            .navigationTitle(Text(LocalizedStringKey(equipment == nil ? "gear.form.add.title" : "gear.form.edit.title")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("general.save") { save() }
                        .font(.callout.weight(.bold))
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: equipmentType) { _, newType in
                if newType == .inlineSkates {
                    powerType = .humanPowered
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("edit-equipment-view")
    }

    private var typePicker: some View {
        Picker("gear.form.type", selection: $equipmentType) {
            ForEach(EquipmentType.allCases) { type in
                Text(LocalizedStringKey(type.localizationKey)).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("equipment-form-type")
    }

    @ViewBuilder
    private var modePicker: some View {
        switch equipmentType {
        case .skateboard:
            Picker("gear.form.mode", selection: $selectedBoardMode) {
                ForEach(BoardMode.allCases, id: \.self) { mode in
                    Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
                }
            }
        case .inlineSkates:
            Picker("gear.form.mode", selection: $selectedInlineMode) {
                ForEach(InlineMode.allCases, id: \.self) { mode in
                    Text(LocalizedStringKey(mode.localizationKey)).tag(mode)
                }
            }
        }
    }

    private var powerPicker: some View {
        Picker("gear.form.power", selection: $powerType) {
            ForEach(PowerType.allCases, id: \.self) { type in
                if type.isValid(for: sportMode) {
                    Text(LocalizedStringKey(type.localizationKey)).tag(type)
                }
            }
        }
    }

    private var sportMode: SportMode {
        switch equipmentType {
        case .skateboard:
            return .skateboard(selectedBoardMode)
        case .inlineSkates:
            return .inline(selectedInlineMode)
        }
    }

    private func formSection<Content: View>(
        _ titleKey: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
            )
        }
    }

    private func labeledTextField(
        _ titleKey: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        accessibilityID: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            TextField(LocalizedStringKey(titleKey), text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .padding(11)
                .background(SkateTrackSessionStartColors.navy3.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier(accessibilityID ?? "equipment-form-field")
        }
    }

    private func save() {
        do {
            let profile = try EquipmentProfile(
                id: equipment?.id ?? UUID(),
                name: name,
                equipmentType: equipmentType,
                sportMode: sportMode,
                powerType: equipmentType == .inlineSkates ? .humanPowered : powerType,
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                totalDistanceKm: try parseDouble(totalDistanceKm),
                wheelSetMileageKm: try parseDouble(wheelSetMileageKm),
                bearingSetMileageKm: try parseDouble(bearingSetMileageKm),
                wheelDiameterMillimeters: try parseOptionalDouble(wheelDiameterMillimeters),
                wheelHardness: wheelHardness,
                bearingABEC: bearingABEC,
                brakeType: equipmentType == .inlineSkates ? brakeType : nil,
                truckTightnessNote: equipment?.truckTightnessNote,
                riserPadNote: equipment?.riserPadNote,
                bootType: equipment?.bootType,
                frameLengthMillimeters: equipment?.frameLengthMillimeters,
                lastMaintenanceDate: equipment?.lastMaintenanceDate,
                photoLocalIdentifier: equipment?.photoLocalIdentifier,
                notes: notes,
                createdAt: equipment?.createdAt ?? Date(),
                updatedAt: Date()
            )
            onSave(profile)
            dismiss()
        } catch {
            errorKey = "gear.form.error.invalid"
        }
    }

    private func parseDouble(_ value: String) throws -> Double {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false, let number = Double(normalized), number >= 0 else {
            throw EquipmentFormError.invalidNumber
        }
        return number
    }

    private func parseOptionalDouble(_ value: String) throws -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return try parseDouble(trimmed)
    }

    private static func numberString(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private static func optionalNumberString(_ value: Double?) -> String {
        guard let value else { return "" }
        return numberString(value)
    }
}

private enum EquipmentFormError: Error {
    case invalidNumber
}

#Preview("Add Equipment") {
    EditEquipmentView { _ in }
}
