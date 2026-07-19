#!/usr/bin/env bash
set -euo pipefail

TARGET="/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature"
EXPECTED_BRANCH="feature/snow-mode"
MACOS_DESTINATION="platform=macOS"
IOS_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
WATCH_DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)"
PACK_DIR="SnowTask007_ReviewPack"

if [[ "$(pwd)" != "$TARGET" ]]; then
  echo "[snow-task-007-review] ERROR: run from $TARGET" >&2
  exit 1
fi

GIT_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$GIT_ROOT" != "$TARGET" ]]; then
  echo "[snow-task-007-review] ERROR: git root mismatch: $GIT_ROOT" >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "$EXPECTED_BRANCH" ]]; then
  echo "[snow-task-007-review] ERROR: branch mismatch: $BRANCH" >&2
  exit 1
fi

rm -rf "$PACK_DIR" "${PACK_DIR}.zip"
mkdir -p "$PACK_DIR/SOURCE_FILES"

echo "[snow-task-007-review] Capturing diff metadata..."
git diff --stat > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_007_ONLY.txt"
git diff --name-only > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_007_ONLY.txt"

# Safety checks required by the Snow-Task-007 handoff.
git diff --name-only | grep -E '^Shared/Models/SkateTrackPackage(Manifest|Payload)\.swift$' > "$PACK_DIR/SAFETY_CHECK_PACKAGE_SCHEMA_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^Shared/Export/SkateTrackPackage(Reader|Writer)\.swift$' > "$PACK_DIR/SAFETY_CHECK_PACKAGE_READER_WRITER_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^Shared/Models/BackupPackage(Manifest|Payload)\.swift$' > "$PACK_DIR/SAFETY_CHECK_BACKUP_SCHEMA_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^Shared/Persistence/' > "$PACK_DIR/SAFETY_CHECK_PERSISTENCE_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^iOS/' > "$PACK_DIR/SAFETY_CHECK_IOS_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^watchOS/' > "$PACK_DIR/SAFETY_CHECK_WATCHOS_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^Shared/WatchBridge/' > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '^Shared/Models/(MotionSample|SnowSegment|SnowRun|SnowDistanceBreakdown|SnowVerticalMetrics|SnowSessionState)\.swift$' > "$PACK_DIR/SAFETY_CHECK_SNOW_VALUE_TYPES_MODIFIED_IN_TASK007.txt" || true
git diff --name-only | grep -E '\.skatetrack$' > "$PACK_DIR/SAFETY_CHECK_SKATETRACK_FILES.txt" || true

MAC_SNOW_SCOPE=(
  macOS/Core/Snow
  macOS/Features/Snow
  macOS/App/MacRootView.swift
)

{
  git grep -n 'SnowPrototype\|MacSnowPrototype\|MockSnowSessionProvider' -- "${MAC_SNOW_SCOPE[@]}" ':!scripts/verify_snow_macos_viewer.py' || true
} > "$PACK_DIR/SAFETY_CHECK_SNOWPROTOTYPE_REFERENCES.txt"

{
  git grep -n -E 'WatchConnectivity|WCSession|WatchBridge|WatchSessionCoordinator' -- "${MAC_SNOW_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_REFERENCES.txt"

{
  git grep -n -E 'CoreLocation|CLLocation|CLLocationManager' -- "${MAC_SNOW_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_CORELOCATION_REFERENCES.txt"

{
  git grep -n -E 'HealthKit|HKHealthStore|WeatherKit|CloudKit|CKContainer' -- "${MAC_SNOW_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_HEALTHKIT_WEATHERKIT_CLOUDKIT_REFERENCES.txt"

{
  grep -n 'struct MacSnowSessionAnalysis' macOS/Core/Snow/MacSnowSessionAnalysis.swift || true
  grep -n 'class MacSnowSessionAnalysis' macOS/Core/Snow/MacSnowSessionAnalysis.swift || true
} > "$PACK_DIR/SAFETY_CHECK_ANALYSIS_STRUCT.txt"

{
  grep -n '#if DEBUG' macOS/Core/Snow/MacSnowMockAnalysisProvider.swift || true
  grep -n '#if DEBUG' macOS/App/MacRootView.swift || true
  grep -n 'MacSnowDebugPreviewContainer' macOS/App/MacRootView.swift || true
} > "$PACK_DIR/SAFETY_CHECK_DEBUG_MOCK_GATING.txt"

cat > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md" <<'MD'
# Snow-Task-007 Review Context

MacSnowSessionAnalysis is a struct (not a class).

## Branch and scope

- Worktree: `/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature`
- Branch: `feature/snow-mode`
- Baseline before Snow-Task-007: `1e68805 Add mock-backed Watch Snow UI`
- Task: Snow-Task-007 — read-only macOS Snow viewer

## Completed

Snow-Task-007 adds a production-safe macOS Snow analysis surface:

- `MacSnowSessionAnalysis` is a struct, not a class.
- `MacSnowAnalysisViewModel` is the observable UI holder.
- `MacSnowAnalysisAvailability` includes `packageSchemaPending` for imported `.skatetrack` packages missing official Snow payload fields.
- `MacSnowAnalysisSource` distinguishes DEBUG mock, repository-backed, and imported package sources.
- `MacSnowMockAnalysisProvider` is DEBUG-only.
- Release builds may show full viewer for repository-backed Snow sessions, but must show `packageSchemaPending` for imported packages without official Snow payload.
- Route + Elevation is a lightweight SwiftUI visualization and includes a limited altitude data indicator when `startAltitudeMeters` / `endAltitudeMeters` are nil.
- The viewer body follows `SkateTrack_SnowMode_UI_v1.1.1_Pack` visual direction while the temporary macOS shell remains outside this task's scope.
- `MacRootView` exposes a DEBUG-only Snow Analysis Preview for manual QA.

## Explicit 007 boundary

Snow-Task-007 does not implement official `.skatetrack` Snow package compatibility.

Snow-Task-007 must not modify or introduce:

- `Shared/Models/SkateTrackPackageManifest.swift`
- `Shared/Models/SkateTrackPackagePayload.swift`
- `Shared/Export/SkateTrackPackageReader.swift`
- `Shared/Export/SkateTrackPackageWriter.swift`
- backup / restore / import / export flow changes
- iOS source changes
- watchOS source changes
- `Shared/WatchBridge/*`
- `MotionSample`, `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, `SnowVerticalMetrics`, or `SnowSessionState` modifications
- `.skatetrack` sample files
- HealthKit / WeatherKit / CloudKit
- manual correction persistence

## Deferred items

- Official `.skatetrack` Snow package payload support: Snow-Task-008.
- Package reader / writer / manifest / payload compatibility: Snow-Task-008.
- Full MapKit segment-region fitting and true absolute-altitude profile: later data / map task.
- Manual correction persistence: later UX / persistence task.
- Outer macOS shell redesign toward `SkateTrack_macOS_UI_v2`: later main macOS UI integration task.
- Real WatchBridge wiring remains Snow-Task-006b after mainline Task-040.

## Expected verification

Review:

- `VERIFY_OUTPUT.txt`
- `MACOS_BUILD_OUTPUT.txt`
- `IOS_TARGETED_TEST_OUTPUT.txt`
- `IOS_REGRESSION_BUILD_OUTPUT.txt`
- `WATCHOS_REGRESSION_BUILD_OUTPUT.txt`
- safety check files
- copied source files under `SOURCE_FILES/`

Snow-Task-007 verification token: read-only macOS Snow viewer complete without package schema scope creep.
MD

cat > "$PACK_DIR/MANUAL_QA_RESULT.md" <<'MD'
# Snow-Task-007 Manual QA Result

Manual QA expected before commit:

- `SkateTrack-macOS` runs successfully.
- DEBUG sidebar exposes Snow Analysis Preview.
- Snow Analysis Preview opens with mock Snow session data.
- Viewer uses SnowMode visual direction: deep snow-night panels, ice cyan route / downhill emphasis, amber lift / transport emphasis, and readable low-confidence states.
- Dashboard, Route + Elevation, Segment Timeline, Segment Inspector, and Distance Inspector are readable.
- The current outer macOS shell is temporary; future `SkateTrack_macOS_UI_v2` integration may adjust the surrounding layout.

User visual QA during implementation accepted the Step 4 SnowMode visual alignment as sufficient for Snow-Task-007.
MD

# Include source files for deeper review.
mkdir -p "$PACK_DIR/SOURCE_FILES/macOS/Core" "$PACK_DIR/SOURCE_FILES/macOS/Features" "$PACK_DIR/SOURCE_FILES/macOS/App" "$PACK_DIR/SOURCE_FILES/scripts" "$PACK_DIR/SOURCE_FILES/docs/process" "$PACK_DIR/SOURCE_FILES/docs/release" "$PACK_DIR/SOURCE_FILES/docs/reference"
cp -R macOS/Core/Snow "$PACK_DIR/SOURCE_FILES/macOS/Core/"
cp -R macOS/Features/Snow "$PACK_DIR/SOURCE_FILES/macOS/Features/"
cp macOS/App/MacRootView.swift "$PACK_DIR/SOURCE_FILES/macOS/App/"
cp scripts/verify_snow_macos_viewer.py "$PACK_DIR/SOURCE_FILES/scripts/"
cp docs/process/PHASE_1C_SNOW_AGENT_STATE.md "$PACK_DIR/SOURCE_FILES/docs/process/"
cp docs/release/KNOWN_LIMITATIONS_PRE_ADP.md "$PACK_DIR/SOURCE_FILES/docs/release/"
cp docs/release/MANUAL_QA_MATRIX_PRE_ADP.md "$PACK_DIR/SOURCE_FILES/docs/release/"
cp docs/reference/FILE_STRUCTURE.md "$PACK_DIR/SOURCE_FILES/docs/reference/"

VERIFY_OUTPUT="$PACK_DIR/VERIFY_OUTPUT.txt"
MACOS_BUILD_OUTPUT="$PACK_DIR/MACOS_BUILD_OUTPUT.txt"
IOS_TARGETED_TEST_OUTPUT="$PACK_DIR/IOS_TARGETED_TEST_OUTPUT.txt"
IOS_REGRESSION_BUILD_OUTPUT="$PACK_DIR/IOS_REGRESSION_BUILD_OUTPUT.txt"
WATCHOS_REGRESSION_BUILD_OUTPUT="$PACK_DIR/WATCHOS_REGRESSION_BUILD_OUTPUT.txt"
: > "$VERIFY_OUTPUT"
: > "$MACOS_BUILD_OUTPUT"
: > "$IOS_TARGETED_TEST_OUTPUT"
: > "$IOS_REGRESSION_BUILD_OUTPUT"
: > "$WATCHOS_REGRESSION_BUILD_OUTPUT"

run_and_log() {
  local output_file="$1"
  shift
  echo "\n===== $* =====" | tee -a "$output_file"
  "$@" 2>&1 | tee -a "$output_file"
}

echo "[snow-task-007-review] Running verify scripts..."
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_macos_viewer.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_watch_ui.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_iphone_ui.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_run_boundary.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_classifier.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_schema.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_sport_enum.py

echo "[snow-task-007-review] Running macOS build..."
run_and_log "$MACOS_BUILD_OUTPUT" xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-macOS \
  -destination "$MACOS_DESTINATION"

echo "[snow-task-007-review] Running targeted iOS regression tests..."
run_and_log "$IOS_TARGETED_TEST_OUTPUT" xcodebuild test \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination "$IOS_DESTINATION" \
  -only-testing:SkateTrack-iOSTests/SnowLiveSessionConfigTests \
  -only-testing:SkateTrack-iOSTests/SnowLiveHUDStateMapperTests \
  -only-testing:SkateTrack-iOSTests/SessionRecordingCoordinatorTests

echo "[snow-task-007-review] Running iOS regression build..."
run_and_log "$IOS_REGRESSION_BUILD_OUTPUT" xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination "$IOS_DESTINATION"

echo "[snow-task-007-review] Running watchOS regression build..."
run_and_log "$WATCHOS_REGRESSION_BUILD_OUTPUT" xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-watchOS \
  -destination "$WATCH_DESTINATION"

zip -qr "${PACK_DIR}.zip" "$PACK_DIR"

echo "[snow-task-007-review] Review pack created: ${PACK_DIR}.zip"
