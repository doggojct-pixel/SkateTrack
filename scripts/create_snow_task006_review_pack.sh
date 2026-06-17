#!/usr/bin/env bash
set -euo pipefail

TARGET="/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature"
EXPECTED_BRANCH="feature/snow-mode"
WATCH_DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)"
IOS_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
PACK_DIR="SnowTask006_ReviewPack"

if [[ "$(pwd)" != "$TARGET" ]]; then
  echo "[snow-task-006-review] ERROR: run from $TARGET" >&2
  exit 1
fi

GIT_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$GIT_ROOT" != "$TARGET" ]]; then
  echo "[snow-task-006-review] ERROR: git root mismatch: $GIT_ROOT" >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "$EXPECTED_BRANCH" ]]; then
  echo "[snow-task-006-review] ERROR: branch mismatch: $BRANCH" >&2
  exit 1
fi

rm -rf "$PACK_DIR" "${PACK_DIR}.zip"
mkdir -p "$PACK_DIR/SOURCE_FILES"

echo "[snow-task-006-review] Capturing diff metadata..."
git diff --stat > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_006_ONLY.txt"
git diff --name-only > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_006_ONLY.txt"

# Safety checks required by the Snow-Task-006a handoff.
git diff --name-only | grep -E '^Shared/WatchBridge/' > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_REFERENCES.txt" || true
git diff --name-only | grep -E '^Shared/Models/MotionSample\.swift$' > "$PACK_DIR/SAFETY_CHECK_MOTIONSAMPLE_MODIFIED_IN_TASK006.txt" || true
git diff --name-only | grep -E '^Shared/Models/SnowSegmentClassifier\.swift$' > "$PACK_DIR/SAFETY_CHECK_SNOWSEGMENTCLASSIFIER_MODIFIED_IN_TASK006.txt" || true
git diff --name-only | grep -E '^Shared/Models/RunBoundaryDetector\.swift$' > "$PACK_DIR/SAFETY_CHECK_RUNBOUNDARYDETECTOR_MODIFIED_IN_TASK006.txt" || true
git diff --name-only | grep -E '^Shared/Models/(SnowSegment|SnowRun|SnowDistanceBreakdown|SnowVerticalMetrics|SnowSessionState)\.swift$' > "$PACK_DIR/SAFETY_CHECK_SNOW_TASK002_TYPES_MODIFIED_IN_TASK006.txt" || true
git diff --name-only | grep -E '\.skatetrack$' > "$PACK_DIR/SAFETY_CHECK_SKATETRACK_FILES.txt" || true

WATCH_SCOPE=(
  Shared/Models/WatchSnowSessionSnapshot.swift
  watchOS/Core/Snow
  watchOS/Features/Snow
)

{
  git grep -n 'SnowPrototype' -- "${WATCH_SCOPE[@]}" ':!scripts/verify_snow_watch_ui.py' || true
} > "$PACK_DIR/SAFETY_CHECK_SNOWPROTOTYPE_REFERENCES.txt"

{
  git grep -n -E 'WatchConnectivity|WCSession' -- "${WATCH_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_WATCHCONNECTIVITY_REFERENCES.txt"

{
  git grep -n -E 'WatchSessionCoordinator|WatchBridgeSnowSessionProvider|Shared/WatchBridge' -- "${WATCH_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_TRANSPORT_REFERENCES.txt"

{
  git grep -n 'SessionRecordingCoordinator' -- "${WATCH_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_SESSIONRECORDING_REFERENCES.txt"

{
  git grep -n -E 'CoreLocation|CLLocation|SensorFusionEngine' -- "${WATCH_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_CORELOCATION_REFERENCES.txt"

{
  git grep -n -E 'import HealthKit|HKHealthStore|EmergencyContact|SOSTriggerEvent' -- "${WATCH_SCOPE[@]}" || true
} > "$PACK_DIR/SAFETY_CHECK_HEALTHKIT_SOS_REFERENCES.txt"

{
  grep -n '#if DEBUG' watchOS/Core/Snow/WatchSnowMockSessionProvider.swift || true
  grep -n '#if DEBUG' watchOS/Features/Snow/WatchSnowMockGalleryView.swift || true
  grep -n 'WatchSnowUnavailableView' watchOS/Features/Snow/WatchSnowRootView.swift || true
} > "$PACK_DIR/SAFETY_CHECK_MOCK_PROVIDER_RELEASE_GATING.txt"

cat > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md" <<'MD'
# Snow-Task-006a Review Context

## Branch and scope

- Worktree: `/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature`
- Branch: `feature/snow-mode`
- Baseline before Snow-Task-006a: `4ab2489 Add iPhone Snow live HUD`
- Task: Snow-Task-006a — mock-backed Watch Snow UI

## Completed

Snow-Task-006a adds the watchOS Snow UI production surface without real WatchBridge wiring:

- `WatchSnowSessionSnapshot` is the production-safe equivalent of the Addendum's `SnowPrototypeSession` field contract.
- `WatchSnowSessionDataSource` defines the Watch Snow UI data boundary.
- `WatchSnowMockScenario` and DEBUG-only `WatchSnowMockSessionProvider` provide simulator QA scenarios.
- `WatchSnowHapticIntent`, `WatchSnowHapticIntentObserver`, and `WatchSnowHapticEngine` provide local haptic intent boundaries.
- `WatchSnowRootView` routes DEBUG builds to the mock gallery and Release builds to a neutral unavailable fallback.
- `watchOS/Features/Snow/` contains the mock-backed Watch Snow UI screens: live, carousel, lift / gondola, waiting, low confidence, fall alert, summary, controls, metric chip, style, formatter, root, gallery, and unavailable fallback.
- `scripts/verify_snow_watch_ui.py` verifies data contract, UI files, localization, project membership, DEBUG gating, Release fallback, and 006b deferral guardrails.

## Explicit 006a boundary

This is Snow-Task-006a only.

The Watch Snow UI is mock-backed. There is no real iPhone-to-Watch Snow data wiring in this task.

Snow-Task-006a must not modify or introduce:

- `Shared/WatchBridge/*`
- `WatchConnectivity` / `WCSession`
- `WatchSessionCoordinator`
- `WatchBridgeSnowSessionProvider`
- real `MetricUpdateMessage` snow extensions
- `SessionRecordingCoordinator`
- `useSessionRecording`
- `useSnowLiveSession`
- `SnowLiveSessionCoordinator`
- `MotionSample`
- `RunBoundaryDetector`
- `SnowSegmentClassifier`
- Snow-Task-002 value types
- `.skatetrack` sample files
- HealthKit / real SOS / emergency contact integration
- signing / entitlements / production complication data

## Naming decision

The Addendum and prototype used `SnowPrototypeSession`. Production 006a intentionally uses `WatchSnowSessionSnapshot` instead to avoid a `SnowPrototype*` production namespace.

Future 006b should map real WatchBridge Snow payloads into `WatchSnowSessionSnapshot` while leaving the Watch Snow views unchanged.

## 006b remains deferred

Snow-Task-006b remains deferred until:

1. Mainline `develop` includes completed Phase 1b Task-040 Watch integration.
2. `feature/snow-mode` has rebased or merged onto post-Task-040 `develop`.
3. The final WatchBridge message shape is reviewed against `WatchSnowSessionSnapshot`.
4. Any naming drift is reconciled inside a future adapter, not by rewriting Watch Snow views.

## Expected verification

Review:

- `VERIFY_OUTPUT.txt`
- `WATCH_BUILD_OUTPUT.txt`
- `IOS_TARGETED_TEST_OUTPUT.txt`
- `IOS_REGRESSION_BUILD_OUTPUT.txt`
- safety check files
- copied source files under `SOURCE_FILES/`

Snow-Task-006a verification token: mock-backed Watch Snow UI complete without WatchBridge real-data wiring.
MD

# Include source files for deeper review.
mkdir -p "$PACK_DIR/SOURCE_FILES/Shared/Models" "$PACK_DIR/SOURCE_FILES/watchOS/Core" "$PACK_DIR/SOURCE_FILES/watchOS/Features" "$PACK_DIR/SOURCE_FILES/scripts"
cp Shared/Models/WatchSnowSessionSnapshot.swift "$PACK_DIR/SOURCE_FILES/Shared/Models/"
cp -R watchOS/Core/Snow "$PACK_DIR/SOURCE_FILES/watchOS/Core/"
cp -R watchOS/Features/Snow "$PACK_DIR/SOURCE_FILES/watchOS/Features/"
cp scripts/verify_snow_watch_ui.py "$PACK_DIR/SOURCE_FILES/scripts/"

VERIFY_OUTPUT="$PACK_DIR/VERIFY_OUTPUT.txt"
WATCH_BUILD_OUTPUT="$PACK_DIR/WATCH_BUILD_OUTPUT.txt"
IOS_TARGETED_TEST_OUTPUT="$PACK_DIR/IOS_TARGETED_TEST_OUTPUT.txt"
IOS_REGRESSION_BUILD_OUTPUT="$PACK_DIR/IOS_REGRESSION_BUILD_OUTPUT.txt"
: > "$VERIFY_OUTPUT"
: > "$WATCH_BUILD_OUTPUT"
: > "$IOS_TARGETED_TEST_OUTPUT"
: > "$IOS_REGRESSION_BUILD_OUTPUT"

run_and_log() {
  local output_file="$1"
  shift
  echo "\n===== $* =====" | tee -a "$output_file"
  "$@" 2>&1 | tee -a "$output_file"
}

echo "[snow-task-006-review] Running verify scripts..."
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_watch_ui.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_iphone_ui.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_run_boundary.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_classifier.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_schema.py
run_and_log "$VERIFY_OUTPUT" python3 scripts/verify_snow_sport_enum.py

echo "[snow-task-006-review] Running watchOS build..."
run_and_log "$WATCH_BUILD_OUTPUT" xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-watchOS \
  -destination "$WATCH_DESTINATION"

echo "[snow-task-006-review] Running targeted iOS regression tests..."
run_and_log "$IOS_TARGETED_TEST_OUTPUT" xcodebuild test \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination "$IOS_DESTINATION" \
  -only-testing:SkateTrack-iOSTests/SnowLiveSessionConfigTests \
  -only-testing:SkateTrack-iOSTests/SnowLiveHUDStateMapperTests \
  -only-testing:SkateTrack-iOSTests/SessionRecordingCoordinatorTests

echo "[snow-task-006-review] Running iOS regression build..."
run_and_log "$IOS_REGRESSION_BUILD_OUTPUT" xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination "$IOS_DESTINATION"

zip -qr "${PACK_DIR}.zip" "$PACK_DIR"

echo "[snow-task-006-review] Review pack created: ${PACK_DIR}.zip"
