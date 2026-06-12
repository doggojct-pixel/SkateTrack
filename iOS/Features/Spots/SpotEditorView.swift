// [協作區] SpotEditorView.swift
// 用途：新增 / 編輯本機 Spot，不要求定位權限，使用者可手動輸入座標。
// 委派至：SpotsViewModel.save(_:) 保存資料。

import Foundation
import SwiftUI

struct SpotEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let existingSpot: SpotProfile?
    let onSave: (SpotProfile) async -> Bool

    @State private var name: String
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var radiusText: String
    @State private var activityFamily: SpotActivityFamily
    @State private var surfaceRatingRaw: Int
    @State private var safetyRatingRaw: Int
    @State private var crowdLevel: SpotCrowdLevel
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var showsValidationError = false

    init(
        spot: SpotProfile? = nil,
        onSave: @escaping (SpotProfile) async -> Bool
    ) {
        self.existingSpot = spot
        self.onSave = onSave
        _name = State(initialValue: spot?.name ?? "")
        _latitudeText = State(initialValue: spot?.coordinate.map { String(format: "%.6f", $0.latitude) } ?? "")
        _longitudeText = State(initialValue: spot?.coordinate.map { String(format: "%.6f", $0.longitude) } ?? "")
        _radiusText = State(initialValue: String(Int(spot?.radiusMeters ?? 120)))
        _activityFamily = State(initialValue: spot?.activityFamily ?? .mixed)
        _surfaceRatingRaw = State(initialValue: spot?.surfaceRating?.rawValue ?? 0)
        _safetyRatingRaw = State(initialValue: spot?.safetyRating ?? 0)
        _crowdLevel = State(initialValue: spot?.crowdLevel ?? .unknown)
        _notes = State(initialValue: spot?.notes ?? "")
        _isFavorite = State(initialValue: spot?.isFavorite ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("spots.form.section.identity") {
                    TextField("spots.form.name", text: $name)
                    Picker("spots.form.activity", selection: $activityFamily) {
                        ForEach(SpotActivityFamily.allCases) { family in
                            Text(LocalizedStringKey(family.localizationKey)).tag(family)
                        }
                    }
                    Toggle("spots.favorite", isOn: $isFavorite)
                }

                Section("spots.form.section.location") {
                    TextField("spots.form.latitude", text: $latitudeText)
                        .keyboardType(.decimalPad)
                    TextField("spots.form.longitude", text: $longitudeText)
                        .keyboardType(.decimalPad)
                    TextField("spots.form.radius", text: $radiusText)
                        .keyboardType(.numberPad)
                    Text("spots.form.location.hint")
                        .font(.caption)
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                }

                Section("spots.form.section.conditions") {
                    Picker("spots.form.surface", selection: $surfaceRatingRaw) {
                        Text("spots.form.unset").tag(0)
                        ForEach(SurfaceRating.allCases) { rating in
                            Text(LocalizedStringKey(rating.localizationKey)).tag(rating.rawValue)
                        }
                    }
                    Picker("spots.form.safety", selection: $safetyRatingRaw) {
                        Text("spots.form.unset").tag(0)
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating)/5").tag(rating)
                        }
                    }
                    Picker("spots.form.crowd", selection: $crowdLevel) {
                        ForEach(SpotCrowdLevel.allCases) { level in
                            Text(LocalizedStringKey(level.localizationKey)).tag(level)
                        }
                    }
                }

                Section("spots.form.section.notes") {
                    TextField("spots.form.notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if showsValidationError {
                    Section {
                        Text("spots.form.error.invalid")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SkateTrackSessionStartColors.accent2)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
            .navigationTitle(existingSpot == nil ? "spots.add" : "spots.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("gear.detail.back") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("spots.save") { Task { await save() } }
                        .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() async {
        guard let spot = makeSpot() else {
            showsValidationError = true
            return
        }
        let didSave = await onSave(spot)
        if didSave {
            dismiss()
        } else {
            showsValidationError = true
        }
    }

    private func makeSpot() -> SpotProfile? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        let coordinate = makeCoordinate()
        let radius = Double(radiusText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 120
        return SpotProfile(
            id: existingSpot?.id ?? UUID(),
            name: trimmedName,
            coordinate: coordinate,
            radiusMeters: radius,
            activityFamily: activityFamily,
            surfaceRating: SurfaceRating(rawValue: surfaceRatingRaw),
            safetyRating: safetyRatingRaw > 0 ? safetyRatingRaw : nil,
            crowdLevel: crowdLevel,
            notes: notes,
            isFavorite: isFavorite,
            photoAssetIdentifiers: existingSpot?.photoAssetIdentifiers ?? [],
            visitCount: existingSpot?.visitCount ?? 0,
            lastVisitedAt: existingSpot?.lastVisitedAt,
            preferredSportModes: existingSpot?.preferredSportModes ?? [],
            createdAt: existingSpot?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }

    private func makeCoordinate() -> GeoCoordinate? {
        let trimmedLatitude = latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLongitude = longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLatitude.isEmpty || !trimmedLongitude.isEmpty else { return nil }
        guard let latitude = Double(trimmedLatitude), let longitude = Double(trimmedLongitude) else { return nil }
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }
}
