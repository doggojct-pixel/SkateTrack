#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/doggo/Documents/App軟體區/SkateTrack-SnowFeature"
UPLOAD_DIR="/Users/doggo/Documents/App軟體區/upload"
PACK_DIR="$UPLOAD_DIR/SnowTask010_ReviewPack"
ZIP_PATH="$UPLOAD_DIR/SnowTask010_ReviewPack.zip"

if [ ! -e "$REPO/.git" ]; then
  echo "[snow-task-010-review] ERROR: repo not found at $REPO" >&2
  exit 1
fi

mkdir -p "$UPLOAD_DIR"
rm -rf "$PACK_DIR" "$ZIP_PATH"
mkdir -p "$PACK_DIR/SOURCE_FILES/scripts" "$PACK_DIR/SOURCE_FILES/docs/process" "$PACK_DIR/SOURCE_FILES/docs/release" "$PACK_DIR/SOURCE_FILES/docs/reference" "$PACK_DIR/SOURCE_FILES/docs/history" "$PACK_DIR/SOURCE_FILES/docs/root"

cd "$REPO"

cat > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md" <<'EOF'
# Snow-Task-010 Claude Review Context

This is Snow-Task-010 final closure only.

Please review in Traditional Chinese.

Review focus:

- No runtime feature behavior was added.
- No package or backup schema version was bumped.
- No HealthKit production export was implemented.
- No WatchBridge / WatchConnectivity production wiring was implemented.
- Snow-Task-006b remains deferred until mainline Task-040+ alignment.
- Snow Mode Phase 1c is ready for human / Claude review as a feature branch, not yet App Store production release.
- Deferred items and manual QA requirements are clearly documented.
EOF

cat > "$PACK_DIR/PHASE1C_COMPLETION_SUMMARY.md" <<'EOF'
# Phase 1c Snow Mode Completion Summary

Snow-Task-010 closes the Phase 1c Snow Mode feature branch by adding:

- `docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md`
- `scripts/verify_snow_phase1c_completion.py`
- `scripts/create_snow_task010_review_pack.sh`
- Final documentation alignment across agent state, dev log, file structure, known limitations, manual QA, and documentation index.

Snow-Task-010 intentionally does not add runtime functionality. It is a review-readiness and handoff gate.
EOF

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
  echo "## Verify Snow Phase 1c Completion"
  python3 scripts/verify_snow_phase1c_completion.py
  echo
  echo "## Forbidden binary fixture scan"
  if find Tests -name '*.skatetrack' -print | grep -q .; then
    echo "FAIL: .skatetrack fixture found"
    find Tests -name '*.skatetrack' -print
    exit 1
  else
    echo "PASS: no .skatetrack fixtures under Tests"
  fi
  echo
  echo "## Runtime / prototype token scan"
  if grep -R "import HealthKit\|HKWorkout\|HKQuantitySample\|HKHealthStore\|import WatchConnectivity\|WCSession\|SnowPrototype\|MacSnowPrototype" Shared iOS watchOS macOS Tests --include='*.swift' >/tmp/snow_task010_scan.txt 2>/dev/null; then
    echo "FAIL: forbidden runtime/prototype token found"
    cat /tmp/snow_task010_scan.txt
    exit 1
  else
    echo "PASS: no forbidden runtime/prototype tokens in Swift production/test paths"
  fi
} > "$PACK_DIR/SAFETY_SCAN_SUMMARY.md"

git status --short > "$PACK_DIR/GIT_STATUS_SHORT.txt"
git log --oneline -20 > "$PACK_DIR/GIT_LOG_ONELINE_20.txt"
git diff --stat HEAD > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_010_ONLY.txt"
git diff --name-only HEAD > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_010_ONLY.txt"
git diff HEAD -- \
  docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md \
  docs/process/PHASE_1C_SNOW_AGENT_STATE.md \
  docs/history/DEV_LOG.md \
  docs/reference/FILE_STRUCTURE.md \
  docs/release/KNOWN_LIMITATIONS_PRE_ADP.md \
  docs/release/MANUAL_QA_MATRIX_PRE_ADP.md \
  docs/DOCUMENTATION_INDEX.md \
  scripts/verify_snow_phase1c_completion.py \
  scripts/create_snow_task010_review_pack.sh > "$PACK_DIR/GIT_DIFF_SNOW_TASK_010_ONLY.patch" || true

{
  echo "===== verify_snow_phase1c_completion.py ====="
  python3 scripts/verify_snow_phase1c_completion.py
  echo
  echo "===== cumulative verify ====="
  python3 scripts/verify_snow_regression.py
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

cp scripts/verify_snow_phase1c_completion.py "$PACK_DIR/SOURCE_FILES/scripts/"
cp scripts/create_snow_task010_review_pack.sh "$PACK_DIR/SOURCE_FILES/scripts/"
cp docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md "$PACK_DIR/SOURCE_FILES/docs/process/"
cp docs/process/PHASE_1C_SNOW_AGENT_STATE.md "$PACK_DIR/SOURCE_FILES/docs/process/"
cp docs/release/MANUAL_QA_MATRIX_PRE_ADP.md "$PACK_DIR/SOURCE_FILES/docs/release/"
cp docs/release/KNOWN_LIMITATIONS_PRE_ADP.md "$PACK_DIR/SOURCE_FILES/docs/release/"
cp docs/reference/FILE_STRUCTURE.md "$PACK_DIR/SOURCE_FILES/docs/reference/"
cp docs/history/DEV_LOG.md "$PACK_DIR/SOURCE_FILES/docs/history/"
cp docs/DOCUMENTATION_INDEX.md "$PACK_DIR/SOURCE_FILES/docs/root/"

cd "$UPLOAD_DIR"
zip -qr "$ZIP_PATH" SnowTask010_ReviewPack

echo "[snow-task-010-review] Review pack created: $ZIP_PATH"
