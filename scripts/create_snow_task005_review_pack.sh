#!/usr/bin/env bash
set -euo pipefail

TARGET="/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature"
EXPECTED_BRANCH="feature/snow-mode"
PACK_DIR="SnowTask005_ReviewPack"

if [[ "$(pwd)" != "$TARGET" ]]; then
  echo "[snow-task-005-review] ERROR: run from $TARGET" >&2
  exit 1
fi

GIT_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$GIT_ROOT" != "$TARGET" ]]; then
  echo "[snow-task-005-review] ERROR: git root mismatch: $GIT_ROOT" >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "$EXPECTED_BRANCH" ]]; then
  echo "[snow-task-005-review] ERROR: branch mismatch: $BRANCH" >&2
  exit 1
fi

rm -rf "$PACK_DIR"
mkdir -p "$PACK_DIR"

echo "[snow-task-005-review] Capturing diff metadata..."
git diff --stat > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_005_ONLY.txt"
git diff --name-only > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_005_ONLY.txt"

# Safety checks required by the Snow-Task-005 handoff.
git diff --name-only | grep -E '^Shared/Models/RunBoundaryDetector\.swift$' > "$PACK_DIR/SAFETY_CHECK_RUNBOUNDARYDETECTOR_MODIFIED.txt" || true
git diff --name-only | grep -E '^Shared/Models/SnowSegmentClassifier\.swift$' > "$PACK_DIR/SAFETY_CHECK_SNOWSEGMENTCLASSIFIER_MODIFIED.txt" || true
git diff --name-only | grep -E '^Shared/Models/(SnowSegment|SnowRun|SnowDistanceBreakdown|SnowVerticalMetrics|SnowSessionState)\.swift$' > "$PACK_DIR/SAFETY_CHECK_SNOW_TASK002_TYPES_MODIFIED_IN_TASK005.txt" || true
git diff --name-only | grep -E '^Shared/Models/MotionSample\.swift$' > "$PACK_DIR/SAFETY_CHECK_MOTIONSAMPLE_MODIFIED_IN_TASK005.txt" || true
git diff --name-only | grep -E '^Shared/WatchBridge/' > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_REFERENCES.txt" || true
git diff --name-only | grep -E '\.skatetrack$' > "$PACK_DIR/SAFETY_CHECK_SKATETRACK_FILES.txt" || true

# Search production code only; docs may intentionally mention SnowPrototype as a forbidden boundary.
{
  git grep -n 'SnowPrototype' -- Shared iOS watchOS macOS Tests scripts ':!scripts/create_snow_task005_review_pack.sh' || true
} > "$PACK_DIR/SAFETY_CHECK_SNOWPROTOTYPE_REFERENCES.txt"

cat > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md" <<'MD'
# Snow-Task-005 Review Context

## Branch and scope

- Worktree: `/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature`
- Branch: `feature/snow-mode`
- Baseline before Snow-Task-005: `c0aeec8 Add Snow run boundary detector`
- Task: Snow-Task-005 — iPhone Snow UI production wiring

## Completed

Snow-Task-005 adds the iPhone Snow UI production boundary after Snow-Task-004:

- `SnowLiveSessionConfig`
- `SnowLiveSessionState`
- `SnowClassificationWindowBuffer`
- `SnowLiveSessionCoordinator`
- `SnowLiveHUDState`
- `SnowLiveHUDStateMapper`
- `useSnowLiveSession`
- `SnowHUDView` four-state UI: downhill, lift / gondola, waiting, low confidence
- `SnowDaySummaryView`
- `SnowSegmentTimelineView`
- `SnowDistanceInspectorView`
- `scripts/verify_snow_iphone_ui.py`

`SessionRecordingCoordinator` remains the lifecycle owner and only forwards `MotionSample` values into Snow live processing for `.snow(...)` sessions.

`useSnowSession` remains repository-backed for persisted Snow history.

## lowConfidence policy

`lowConfidence` is config-driven:

```text
SnowLiveSessionConfig.productionV0.lowConfidenceThreshold
= SnowClassifierConfig.productionV0.mediumConfidenceThreshold
```

Snow HUD views and mappers must not hardcode confidence literals.

## Explicit non-goals

Snow-Task-005 must not modify:

- `Shared/Models/RunBoundaryDetector.swift`
- `Shared/Models/SnowSegmentClassifier.swift`
- `Shared/Models/SnowClassifierConfig.swift`
- `Shared/Models/MotionSample.swift`
- Snow-Task-002 value types: `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, `SnowVerticalMetrics`, `SnowSessionState`
- `Shared/WatchBridge/*`

Snow-Task-005 must not introduce `SnowPrototype*` production namespace and must not add `.skatetrack` sample files.

## Deferred items

- Manual correction persistence for `SnowSegment.manualOverride`
- WatchBridge real-data wiring and Watch low-confidence payload mapping until Snow-Task-006b after mainline Task-040
- True altitude confidence scoring until a later approved `MotionSample` metadata extension
- Live provisional segment timeline before `RunBoundaryEvent.runEnded`

## Expected verification

Review `VERIFY_OUTPUT.txt` for:

- `python3 scripts/verify_snow_iphone_ui.py`
- `python3 scripts/verify_snow_run_boundary.py`
- `python3 scripts/verify_snow_classifier.py`
- `python3 scripts/verify_snow_schema.py`
- `python3 scripts/verify_snow_sport_enum.py`
- targeted iOS XCTest for Snow live config / HUD mapper / session coordinator
- iOS simulator build for `SkateTrack-iOS` on `iPhone 17 Pro`

Snow-Task-005 verification token: production iPhone Snow UI wired to live Snow boundary without classifier/schema/WatchBridge scope creep.
MD

VERIFY_OUTPUT="$PACK_DIR/VERIFY_OUTPUT.txt"
: > "$VERIFY_OUTPUT"

run_and_log() {
  echo "\n===== $* =====" | tee -a "$VERIFY_OUTPUT"
  "$@" 2>&1 | tee -a "$VERIFY_OUTPUT"
}

echo "[snow-task-005-review] Running verify scripts, targeted XCTest, and iOS build..."
run_and_log python3 scripts/verify_snow_iphone_ui.py
run_and_log python3 scripts/verify_snow_run_boundary.py
run_and_log python3 scripts/verify_snow_classifier.py
run_and_log python3 scripts/verify_snow_schema.py
run_and_log python3 scripts/verify_snow_sport_enum.py
run_and_log xcodebuild test \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SkateTrack-iOSTests/SnowLiveSessionConfigTests \
  -only-testing:SkateTrack-iOSTests/SnowLiveHUDStateMapperTests \
  -only-testing:SkateTrack-iOSTests/SessionRecordingCoordinatorTests
run_and_log xcodebuild build \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

zip -qr "${PACK_DIR}.zip" "$PACK_DIR"

echo "[snow-task-005-review] Review pack created: ${PACK_DIR}.zip"
