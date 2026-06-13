#!/usr/bin/env python3
"""Verify Task-021b Spot Session Association + Visit Tracking Foundation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SpotSessionSnapshot.swift",
    "Shared/Models/SpotVisit.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SessionEntityMapper.swift",
    "Shared/Persistence/SessionRepository.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "iOS/Core/Spots/SpotRepository.swift",
    "iOS/Core/Spots/SpotVisitTracker.swift",
    "iOS/Hooks/useSessionRecording.swift",
    "iOS/Features/SessionRecording/SessionStartView.swift",
    "iOS/Features/SessionRecording/SessionSpotPickerView.swift",
    "iOS/Features/SessionHistory/SessionHistoryCardView.swift",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SessionSpotAttributionView.swift",
]

LOCALIZATION_KEYS = [
    "spots.session.title",
    "spots.session.subtitle",
    "spots.session.optional",
    "spots.session.empty.title",
    "spots.session.empty.subtitle",
    "spots.session.none",
    "spots.session.none.subtitle",
    "spots.session.visitCountFormat",
    "spots.lastVisited",
    "spots.lastVisited.never",
    "spots.error.visitTrackingFailed",
    "history.spot.lineFormat",
    "history.spot.unsynced",
    "summary.spot.title",
    "summary.spot.unsynced",
    "summary.spot.legacy.description",
    "summary.spot.detailFormat",
]

PROJECT_TOKENS = [
    "SpotSessionSnapshot.swift in Sources",
    "SpotVisitTracker.swift in Sources",
    "SessionSpotPickerView.swift in Sources",
    "SessionSpotAttributionView.swift in Sources",
    "SessionRecordingCoordinator+CompletionEffects.swift in Sources",
]

FORBIDDEN_TOKENS = [
    "WeatherKit",
    "GIDSignIn",
    "GoogleSignIn",
    "GoogleAPIClient",
    "DriveService",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
    "DEVELOPMENT_TEAM =",
    "CODE_SIGN_ENTITLEMENTS =",
    "PROVISIONING_PROFILE",
]


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def assert_contains(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing `{token}` in {label}")


def assert_not_contains(text: str, token: str, label: str) -> None:
    if token in text:
        fail(f"Forbidden `{token}` found in {label}")


def extract_keys(path: str) -> set[str]:
    return set(re.findall(r'^"([^"]+)"\s*=', read(path), flags=re.MULTILINE))


for relative in REQUIRED_FILES:
    text = read(relative)
    line_count = len(text.splitlines())
    if line_count > 500:
        fail(f"{relative} exceeds 500-line limit: {line_count}")

spot_snapshot = read("Shared/Models/SpotSessionSnapshot.swift")
for token in [
    "struct SpotSessionSnapshot",
    "let spotID: UUID",
    "let name: String",
    "let activityFamily: SpotActivityFamily",
    "let coordinate: GeoCoordinate?",
    "let radiusMeters: Double",
    "init(spot: SpotProfile",
    "var displayName: String",
]:
    assert_contains(spot_snapshot, token, "SpotSessionSnapshot.swift")

session_data = read("Shared/Models/SessionData.swift")
for token in [
    "let spotSnapshot: SpotSessionSnapshot?",
    "spotSnapshot: SpotSessionSnapshot? = nil",
    "case spotSnapshot",
    "decodeIfPresent(SpotSessionSnapshot.self, forKey: .spotSnapshot)",
]:
    assert_contains(session_data, token, "SessionData.swift")

mapper = read("Shared/Persistence/SessionEntityMapper.swift")
for token in [
    "spotSnapshotData",
    "session.spotSnapshot.map",
    "decode(SpotSessionSnapshot.self",
    "spotSnapshot:",
]:
    assert_contains(mapper, token, "SessionEntityMapper.swift")

persistence = read("Shared/Persistence/PersistenceController.swift")
model = read("Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents")
for token in [
    "spotSnapshotData",
    "binaryAttribute(\"spotSnapshotData\", optional: true)",
    "makePersistedSpotVisitEntity",
    "PersistedSpotVisit",
]:
    assert_contains(persistence, token, "PersistenceController.swift")
for token in [
    "spotSnapshotData",
    "PersistedSpotVisit",
    "spotID",
    "sessionID",
    "visitedAt",
    "distanceKilometers",
    "confidence",
]:
    assert_contains(model, token, "Core Data model contents")

repository = read("iOS/Core/Spots/SpotRepository.swift")
for token in [
    "func fetchVisits(for spotID: UUID) async throws -> [SpotVisit]",
    "func recordVisit(_ visit: SpotVisit) async throws -> SpotVisit",
    "visitEntityName = \"PersistedSpotVisit\"",
    "request.predicate = NSPredicate(format: \"sessionID == %@\"",
    "spotObject.setValue(existingCount + 1",
    "spotObject.setValue(visit.visitedAt, forKey: \"lastVisitedAt\")",
    "fetchVisitObjects(spotID:",
]:
    assert_contains(repository, token, "SpotRepository.swift")
assert_not_contains(repository, "import SwiftUI", "SpotRepository.swift")

session_repository = read("Shared/Persistence/SessionRepository.swift")
for token in [
    "fetchSpotVisitObjects(sessionID:",
    "refreshSpotVisitSummary(spotID:",
    "spotVisits.forEach(context.delete)",
    "spotObject.setValue(visits.count, forKey: \"visitCount\")",
]:
    assert_contains(session_repository, token, "SessionRepository.swift")

tracker = read("iOS/Core/Spots/SpotVisitTracker.swift")
for token in [
    "protocol SpotVisitTracking",
    "enum SpotVisitTrackingResult",
    "actor SpotVisitTracker",
    "applyVisitIfNeeded(to session: SessionData)",
    "repository.fetchSpot(id: spotID)",
    "repository.recordVisit(visit)",
    "appliedSessionIDs.insert(session.id)",
]:
    assert_contains(tracker, token, "SpotVisitTracker.swift")

coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
completion_effects = read("iOS/Core/SessionRecording/SessionRecordingCoordinator+CompletionEffects.swift")
for token in [
    "let spotVisitTracker: SpotVisitTracking",
    "private var selectedSpotID: UUID?",
    "private var selectedSpotSnapshot: SpotSessionSnapshot?",
    "spotID: UUID? = nil",
    "spotSnapshot: SpotSessionSnapshot? = nil",
    "selectedSpotID = spotID",
    "selectedSpotSnapshot = spotSnapshot",
    "await applySpotVisitIfNeeded(for: savedSession)",
    "spotID: selectedSpotID ?? session.spotID",
    "spotSnapshot: selectedSpotSnapshot ?? session.spotSnapshot",
    "spots.error.visitTrackingFailed",
]:
    assert_contains(coordinator + "\n" + completion_effects, token, "SessionRecordingCoordinator completion path")

hook = read("iOS/Hooks/useSessionRecording.swift")
for token in [
    "selectedSpotID: UUID?",
    "SpotSessionSnapshot?",
    "spotID: spotID",
    "spotSnapshot: spotSnapshot",
]:
    assert_contains(hook, token, "useSessionRecording.swift")

start_view = read("iOS/Features/SessionRecording/SessionStartView.swift")
for token in [
    "@State private var selectedSpotID: UUID?",
    "@StateObject private var spotsManager: SpotsViewModel",
    "SessionSpotPickerView(",
    "clearUnavailableSelectedSpot()",
    "selectedSpotForSession",
    "SpotSessionSnapshot(spot:",
]:
    assert_contains(start_view, token, "SessionStartView.swift")

picker = read("iOS/Features/SessionRecording/SessionSpotPickerView.swift")
for token in [
    "struct SessionSpotPickerView",
    "spots.session.title",
    "spots.session.none",
    "spots.session.empty.title",
    "Text(verbatim: title)",
]:
    assert_contains(picker, token, "SessionSpotPickerView.swift")
for token in ["import CoreData", "WeatherKit", "CLLocationManager", "Google"]:
    assert_not_contains(picker, token, "SessionSpotPickerView.swift")

history = read("iOS/Features/SessionHistory/SessionHistoryCardView.swift")
for token in [
    "history-card-spot-snapshot",
    "session.spotSnapshot",
    "history.spot.lineFormat",
    "history.spot.unsynced",
]:
    assert_contains(history, token, "SessionHistoryCardView.swift")

spot_map = read("iOS/Features/Spots/SpotMapView.swift")
for token in ["Map(position:", "Annotation("]:
    assert_contains(spot_map, token, "SpotMapView.swift")
for token in ["MapAnnotation", "coordinateRegion:"]:
    assert_not_contains(spot_map, token, "SpotMapView.swift")

summary = read("iOS/Features/SessionSummary/SessionSummaryView.swift")
summary_spot = read("iOS/Features/SessionSummary/SessionSpotAttributionView.swift")
for token in [
    "SessionSpotAttributionView(session: content.session)",
    "shouldShowSpotAttribution",
]:
    assert_contains(summary, token, "SessionSummaryView.swift")
for token in [
    "struct SessionSpotAttributionView",
    "summary.spot.title",
    "summary.spot.detailFormat",
    "summary.spot.legacy.description",
    "session-summary-spot-attribution",
]:
    assert_contains(summary_spot, token, "SessionSpotAttributionView.swift")

project = read("SkateTrack.xcodeproj/project.pbxproj")
for token in PROJECT_TOKENS:
    assert_contains(project, token, "project.pbxproj")

for language in ("en", "zh-Hant"):
    keys = extract_keys(f"Shared/Localization/{language}.lproj/Localizable.strings")
    for key in LOCALIZATION_KEYS:
        if key not in keys:
            fail(f"Missing localization key {key} in {language}")

combined = "\n".join(read(relative) for relative in REQUIRED_FILES)
for token in ["WeatherKit", "GIDSignIn", "GoogleSignIn", "Product.products", "Transaction.currentEntitlements", "AppStore.sync"]:
    if token in combined:
        fail(f"Task-021b must not introduce `{token}`")

pbx_changed = project
for token in ["DEVELOPMENT_TEAM =", "CODE_SIGN", "PROVISIONING_PROFILE", "PRODUCT_BUNDLE_IDENTIFIER"]:
    # project may contain baseline PRODUCT_BUNDLE_IDENTIFIER values; this script only ensures no new task files mention signing.
    for relative in REQUIRED_FILES:
        if token in read(relative):
            fail(f"Task-021b source file {relative} must not mention signing token `{token}`")

docs = read("docs/history/DEV_LOG.md") + "\n" + read("docs/reference/FILE_STRUCTURE.md") + "\n" + read("docs/adr/ADR-INDEX.md") + "\n" + read("docs/adr/ADR-INDEX.md")
for token in [
    "Task-021b",
    "SpotSessionSnapshot",
    "SpotVisitTracker",
    "SessionSpotPickerView",
    "SessionSpotAttributionView",
    "spotSnapshotData",
    "PersistedSpotVisit",
    "bulk-delete",
]:
    assert_contains(docs, token, "living docs / ADR")

print("✅ Task-021b spot session association verification passed.")
