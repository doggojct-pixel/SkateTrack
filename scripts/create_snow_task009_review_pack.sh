#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature"
UPLOAD_DIR="/Users/doggo/Documents/App軟體區/upload"
PACK_DIR="$UPLOAD_DIR/SnowTask009_ReviewPack"
ZIP_PATH="$UPLOAD_DIR/SnowTask009_ReviewPack.zip"

if [ ! -e "$REPO/.git" ]; then
  echo "[snow-task-009-review] ERROR: repo not found: $REPO" >&2
  exit 1
fi

mkdir -p "$UPLOAD_DIR"
rm -rf "$PACK_DIR" "$ZIP_PATH"
mkdir -p "$PACK_DIR" "$PACK_DIR/fixtures" "$PACK_DIR/docs" "$PACK_DIR/scripts" "$PACK_DIR/tests"
cd "$REPO"

{
  echo "# SnowTask009 Claude Review Context"
  echo
  echo "Task: Snow-Task-009 QA Fixtures + Manual Test Matrix"
  echo "Base: 1659722 Add Snow backup compatibility and health export boundary"
  echo "Branch: feature/snow-mode"
  echo
  echo "## Scope"
  echo
  echo "Task 009 adds deterministic JSON fixtures, regression tests, a manual QA matrix update, a regression verify gate, and this review pack generator."
  echo
  echo "## Non-goals"
  echo
  echo "- No runtime Snow classifier change."
  echo "- No run-boundary detector change."
  echo "- No real HealthKit export or HealthKit imports."
  echo "- No WatchBridge / WatchConnectivity production integration."
  echo "- No package or backup schema bump beyond verifying the existing v2 compatibility from Snow-Task-008a/008b."
  echo "- No .skatetrack fixture committed to source control."
  echo
  echo "## Expected review focus"
  echo
  echo "Please verify that the fixture strategy covers 001-008b regression surfaces without expanding runtime behavior, and that the manual QA matrix is practical before Phase 1c wrap-up."
} > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md"

{
  echo "# Safety Scan Summary"
  echo
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Git status"
  git status --short
  echo
  echo "## Changed files vs HEAD"
  git diff --name-only HEAD
  echo
  echo "## Forbidden binary fixture scan"
  if find Tests/Fixtures -name '*.skatetrack' -print | grep -q .; then
    echo "FAIL: .skatetrack fixture found"
    find Tests/Fixtures -name '*.skatetrack' -print
    exit 1
  else
    echo "PASS: no .skatetrack fixtures under Tests/Fixtures"
  fi
  echo
  echo "## Runtime integration token scan"
  if grep -R "import HealthKit\|HKWorkout\|HKQuantitySample\|HKHealthStore\|import WatchConnectivity\|WCSession\|SnowPrototype\|MacSnowPrototype" Shared iOS watchOS macOS Tests --include='*.swift' >/tmp/snow_task009_scan.txt 2>/dev/null; then
    echo "FAIL: forbidden runtime/prototype token found"
    cat /tmp/snow_task009_scan.txt
    exit 1
  else
    echo "PASS: no forbidden runtime/prototype tokens in Swift production/test paths"
  fi
} > "$PACK_DIR/SAFETY_SCAN_SUMMARY.md"

git status --short > "$PACK_DIR/GIT_STATUS_SHORT.txt"
git log --oneline -12 > "$PACK_DIR/GIT_LOG_ONELINE_12.txt"
git diff --stat HEAD > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_009_ONLY.txt"
git diff --name-only HEAD > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_009_ONLY.txt"
git diff HEAD -- \
  Tests/Fixtures/Snow \
  Tests/iOSTests/SnowQAFixtureRegressionTests.swift \
  scripts/generate_snow_qa_fixtures.py \
  scripts/verify_snow_regression.py \
  scripts/create_snow_task009_review_pack.sh \
  docs/DOCUMENTATION_INDEX.md \
  docs/history/DEV_LOG.md \
  docs/process/PHASE_1C_SNOW_AGENT_STATE.md \
  docs/reference/FILE_STRUCTURE.md \
  docs/release/KNOWN_LIMITATIONS_PRE_ADP.md \
  docs/release/MANUAL_QA_MATRIX_PRE_ADP.md \
  SkateTrack.xcodeproj/project.pbxproj > "$PACK_DIR/GIT_DIFF_SNOW_TASK_009_ONLY.patch" || true

{
  echo "===== verify_snow_regression.py ====="
  python3 scripts/verify_snow_regression.py
  echo
  echo "===== cumulative verify ====="
  python3 scripts/verify_snow_backup_compatibility.py
  python3 scripts/verify_snow_package_compatibility.py
  python3 scripts/verify_snow_macos_viewer.py
  python3 scripts/verify_snow_watch_ui.py
  python3 scripts/verify_snow_iphone_ui.py
  python3 scripts/verify_snow_run_boundary.py
  python3 scripts/verify_snow_classifier.py
  python3 scripts/verify_snow_schema.py
  python3 scripts/verify_snow_sport_enum.py
} > "$PACK_DIR/VERIFY_OUTPUT.txt"

cp -R Tests/Fixtures/Snow "$PACK_DIR/fixtures/"
cp Tests/iOSTests/SnowQAFixtureRegressionTests.swift "$PACK_DIR/tests/"
cp scripts/generate_snow_qa_fixtures.py "$PACK_DIR/scripts/"
cp scripts/verify_snow_regression.py "$PACK_DIR/scripts/"
cp scripts/create_snow_task009_review_pack.sh "$PACK_DIR/scripts/"
cp docs/release/MANUAL_QA_MATRIX_PRE_ADP.md "$PACK_DIR/docs/"
cp docs/release/KNOWN_LIMITATIONS_PRE_ADP.md "$PACK_DIR/docs/"
cp docs/history/DEV_LOG.md "$PACK_DIR/docs/"
cp docs/process/PHASE_1C_SNOW_AGENT_STATE.md "$PACK_DIR/docs/"
cp docs/reference/FILE_STRUCTURE.md "$PACK_DIR/docs/"
cp docs/DOCUMENTATION_INDEX.md "$PACK_DIR/docs/"

cd "$UPLOAD_DIR"
zip -qr "$ZIP_PATH" SnowTask009_ReviewPack

echo "[snow-task-009-review] Review pack created: $ZIP_PATH"
