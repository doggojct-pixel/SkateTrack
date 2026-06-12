#!/usr/bin/env python3
"""Task-021a Spot Management Foundation verification."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"Missing required file: {path}")
    return file_path.read_text(encoding="utf-8")

def assert_contains(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"{label} missing required token: {token}")

def assert_not_contains(text: str, token: str, label: str) -> None:
    if token in text:
        fail(f"{label} must not contain forbidden token: {token}")

required_files = [
    "Shared/Models/SpotProfile.swift",
    "Shared/Models/SpotVisit.swift",
    "iOS/Core/Spots/SpotRepository.swift",
    "iOS/Hooks/useSpots.swift",
    "iOS/Features/Spots/SpotListView.swift",
    "iOS/Features/Spots/SpotCardView.swift",
    "iOS/Features/Spots/SpotMapView.swift",
    "iOS/Features/Spots/SpotDetailView.swift",
    "iOS/Features/Spots/SpotEditorView.swift",
    "iOS/Features/Spots/SpotFavoriteLimitBanner.swift",
    "iOS/Features/SessionRecording/SessionStartSupportTypes.swift",
]
for required in required_files:
    read(required)

spot_model = read("Shared/Models/SpotProfile.swift")
for token in [
    "enum SpotActivityFamily",
    "enum SpotCrowdLevel",
    "var radiusMeters: Double",
    "var activityFamily: SpotActivityFamily",
    "var safetyRating: Int?",
    "var crowdLevel: SpotCrowdLevel",
    "var isFavorite: Bool",
    "var createdAt: Date",
    "var updatedAt: Date",
]:
    assert_contains(spot_model, token, "SpotProfile.swift")

spot_visit = read("Shared/Models/SpotVisit.swift")
for token in ["struct SpotVisit", "var spotID: UUID", "var sessionID: UUID", "var confidence: Double"]:
    assert_contains(spot_visit, token, "SpotVisit.swift")

repository = read("iOS/Core/Spots/SpotRepository.swift")
for token in [
    "protocol SpotRepositoryProtocol",
    "final class SpotRepository",
    "func fetchSpots() async throws -> [SpotProfile]",
    "func fetchNearbySpots(center: GeoCoordinate, radiusMeters: Double)",
    "func saveSpot(_ spot: SpotProfile)",
    "func deleteSpot(id: UUID)",
    "func setFavorite(_ isFavorite: Bool, for id: UUID)",
    "NSSortDescriptor(key: \"isFavorite\"",
    "distanceMeters(from origin: GeoCoordinate, to destination: GeoCoordinate)",
]:
    assert_contains(repository, token, "SpotRepository.swift")
assert_not_contains(repository, "import SwiftUI", "SpotRepository.swift")

hook = read("iOS/Hooks/useSpots.swift")
for token in [
    "final class SpotsViewModel",
    "static let freeFavoriteLimit = 3",
    "subscriptionStatus.hasAccess(to: .spotManagement)",
    "paywallFeature = .spotManagement",
    "func toggleFavorite(_ spot: SpotProfile)",
    "func useSpots(",
]:
    assert_contains(hook, token, "useSpots.swift")

for ui_file in [
    "iOS/Features/Spots/SpotListView.swift",
    "iOS/Features/Spots/SpotCardView.swift",
    "iOS/Features/Spots/SpotMapView.swift",
    "iOS/Features/Spots/SpotDetailView.swift",
    "iOS/Features/Spots/SpotEditorView.swift",
    "iOS/Features/Spots/SpotFavoriteLimitBanner.swift",
]:
    ui_text = read(ui_file)
    assert_not_contains(ui_text, "import CoreData", ui_file)
    assert_not_contains(ui_text, "WeatherKit", ui_file)
    assert_not_contains(ui_text, "Google", ui_file)
    assert_not_contains(ui_text, "LocalizedStringKey(verbatim:", ui_file)

map_text = read("iOS/Features/Spots/SpotMapView.swift")
assert_contains(map_text, "import MapKit", "SpotMapView.swift")
assert_contains(map_text, "Map(", "SpotMapView.swift")
assert_not_contains(map_text, "CLLocationManager", "SpotMapView.swift")

root_text = read("iOS/App/RootNavigationView.swift")
for token in ["case spots", "SpotListView(", "isSpotDetailPresented", "root-nav-\\(screen.rawValue)"]:
    assert_contains(root_text, token, "RootNavigationView.swift")

persistence_text = read("Shared/Persistence/PersistenceController.swift")
model_text = read("Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents")
for token in ["radiusMeters", "activityFamilyRaw", "safetyRating", "crowdLevelRaw", "isFavorite", "createdAt", "updatedAt"]:
    assert_contains(persistence_text, token, "PersistenceController.swift")
    assert_contains(model_text, token, "Core Data model contents")

pbx = read("SkateTrack.xcodeproj/project.pbxproj")
for token in [
    "SpotVisit.swift in Sources",
    "SessionStartSupportTypes.swift in Sources",
    "SpotRepository.swift in Sources",
    "useSpots.swift in Sources",
    "SpotListView.swift in Sources",
    "SpotMapView.swift in Sources",
    "SpotDetailView.swift in Sources",
    "SpotEditorView.swift in Sources",
    "SpotFavoriteLimitBanner.swift in Sources",
    "iOS/Core/Spots",
    "iOS/Features/Spots",
]:
    assert_contains(pbx, token, "project.pbxproj")

for locale_path in [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
]:
    strings = read(locale_path)
    for key in [
        "spots.title",
        "spots.map",
        "spots.add",
        "spots.edit",
        "spots.favorite.limit",
        "spots.private.default",
        "spots.form.location.hint",
        "spots.form.error.invalid",
    ]:
        assert_contains(strings, f'"{key}"', locale_path)

session_start_lines = len(read("iOS/Features/SessionRecording/SessionStartView.swift").splitlines())
if session_start_lines >= 500:
    fail(f"SessionStartView.swift should stay below 500 lines after split, found {session_start_lines}")

for swift_file in required_files:
    line_count = len(read(swift_file).splitlines())
    if line_count > 500:
        fail(f"{swift_file} exceeds 500 lines: {line_count}")

adr_0001 = read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
assert_contains(adr_0001, "Task-021a", "ADR-0001")
adr_0002 = read("docs/decisions/ADR-0002-developer-account-dependent-services.md")
assert_contains(adr_0002, "Provider Boundary", "ADR-0002")
assert_contains(adr_0002, "Task-021a", "ADR-0002")

for docs_path in ["docs/DEV_LOG.md", "docs/FILE_STRUCTURE.md"]:
    assert_contains(read(docs_path), "Task-021a", docs_path)

print("Task-021a Spot Management verification passed.")
