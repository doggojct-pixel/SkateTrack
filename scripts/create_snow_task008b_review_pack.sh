#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPLOAD_DIR="/Users/doggo/Documents/App軟體區/upload"
PACK_DIR="$UPLOAD_DIR/SnowTask008b_ReviewPack"
ZIP_PATH="$UPLOAD_DIR/SnowTask008b_ReviewPack.zip"

log() { echo "[snow-task-008b-review] $1"; }
fail() { echo "[snow-task-008b-review] ERROR: $1" >&2; exit 1; }

mkdir -p "$UPLOAD_DIR"
rm -rf "$PACK_DIR" "$ZIP_PATH"
mkdir -p "$PACK_DIR/SOURCE_FILES"
cd "$ROOT"

log "Collecting git state..."
git status --short > "$PACK_DIR/GIT_STATUS_SHORT.txt"
git diff --stat > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_008B_ONLY.txt"
git diff --name-only > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_008B_ONLY.txt"
git log --oneline -12 > "$PACK_DIR/GIT_LOG_ONELINE_12.txt"

log "Running verify scripts..."
{
  echo "===== verify_snow_backup_compatibility.py ====="
  python3 scripts/verify_snow_backup_compatibility.py
  echo
  echo "===== verify_snow_package_compatibility.py ====="
  python3 scripts/verify_snow_package_compatibility.py
  echo
  echo "===== cumulative Snow verify ====="
  python3 scripts/verify_snow_macos_viewer.py
  python3 scripts/verify_snow_watch_ui.py
  python3 scripts/verify_snow_iphone_ui.py
  python3 scripts/verify_snow_run_boundary.py
  python3 scripts/verify_snow_classifier.py
  python3 scripts/verify_snow_schema.py
  python3 scripts/verify_snow_sport_enum.py
} > "$PACK_DIR/VERIFY_OUTPUT.txt" 2>&1

log "Writing safety checks..."
{
  python3 - <<'CHECKPY'
from pathlib import Path
root = Path('.').resolve()
text = (root/'Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift').read_text(encoding='utf-8')
required = [
    'testDecodeBackupSchemaVersion1WithoutSnowSessionsSucceeds',
    'testEncodeBackupSchemaVersion2IncludesEmptySnowSessionsArray',
    'testDecodeBackupSchemaVersion2WithSnowSessionsSucceeds',
    'testDecodeBackupUnknownSchemaVersionFails',
]
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit('missing backup compatibility tests: ' + ', '.join(missing))
print('PASS: Legacy and schema 2 Snow backup compatibility tests are present.')
CHECKPY
} > "$PACK_DIR/SAFETY_CHECK_BACKUP_LEGACY_DECODE.txt" 2>&1

{
  python3 - <<'CHECKPY'
from pathlib import Path
root = Path('.').resolve()
health_files = [
    root/'iOS/Core/Health/SnowHealthExporting.swift',
    root/'iOS/Core/Health/DisabledSnowHealthExporter.swift',
    root/'iOS/Core/Health/MockSnowHealthExporter.swift',
]
for path in health_files:
    if not path.exists():
        raise SystemExit(f'missing Health boundary file: {path.relative_to(root)}')
text = '\n'.join(path.read_text(encoding='utf-8') for path in health_files)
required = [
    'protocol SnowHealthExporting',
    'struct SnowHealthExportRequest',
    'struct SnowHealthExportResult',
    'enum SnowHealthExportStatus',
    'struct DisabledSnowHealthExporter',
    'status: .unavailable',
    '#if DEBUG',
    'struct MockSnowHealthExporter',
]
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit('missing Health boundary tokens: ' + ', '.join(missing))
for forbidden in ['import HealthKit', 'HKHealthStore', 'HKWorkout', 'HKQuantitySample']:
    if forbidden in text:
        raise SystemExit(f'forbidden HealthKit implementation token found: {forbidden}')
print('PASS: iOS Health provider boundary is present, disabled/mock only, and does not instantiate HealthKit objects.')
CHECKPY
} > "$PACK_DIR/SAFETY_CHECK_HEALTH_PROVIDER_BOUNDARY.txt" 2>&1

{
  if grep -R "import HealthKit" Shared --include='*.swift' >/tmp/snow008b_healthkit_shared_hits.txt 2>/dev/null; then
    cat /tmp/snow008b_healthkit_shared_hits.txt
    exit 1
  fi
  echo "PASS: No import HealthKit in Shared/."
} > "$PACK_DIR/SAFETY_CHECK_HEALTHKIT_IN_SHARED.txt" 2>&1

{
  if grep -R "SnowPrototype\|MacSnowPrototype" Shared iOS macOS Tests --include='*.swift' >/tmp/snow008b_prototype_hits.txt 2>/dev/null; then
    cat /tmp/snow008b_prototype_hits.txt
    exit 1
  fi
  echo "PASS: No SnowPrototype / MacSnowPrototype references found in production Swift scan paths."
} > "$PACK_DIR/SAFETY_CHECK_SNOWPROTOTYPE_REFERENCES.txt" 2>&1

{
  if grep -R "WCSession\|WatchConnectivity" Shared/Models Shared/Export iOS/Core/Sync iOS/Core/Health iOS/Core/Export macOS/Core/Snow macOS/Features/Import Tests/iOSTests --include='*.swift' >/tmp/snow008b_watch_hits.txt 2>/dev/null; then
    cat /tmp/snow008b_watch_hits.txt
    exit 1
  fi
  echo "PASS: No WatchBridge / WatchConnectivity scope added in 008b compatibility paths."
} > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_REFERENCES.txt" 2>&1

{
  if find . -path './.git' -prune -o -name '*.skatetrack' -print | grep . >/tmp/snow008b_skatetrack_hits.txt; then
    cat /tmp/snow008b_skatetrack_hits.txt
    exit 1
  fi
  echo "PASS: No .skatetrack fixture files found in repository working tree."
} > "$PACK_DIR/SAFETY_CHECK_SKATETRACK_FILES.txt" 2>&1

log "Copying source files..."
copy_file() {
  local rel="$1"
  local dest="$PACK_DIR/SOURCE_FILES/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$rel" "$dest"
}

for rel in \
  Shared/Models/SkateTrackPackageManifest.swift \
  Shared/Models/SkateTrackPackagePayload.swift \
  Shared/Models/SkateTrackPackageSnowPayload.swift \
  Shared/Export/SkateTrackPackageReader.swift \
  Shared/Export/SkateTrackPackageWriter.swift \
  iOS/Core/Export/SkateTrackPackageExportProvider.swift \
  iOS/Hooks/useSkateTrackPackageExport.swift \
  macOS/Core/Snow/MacSnowSessionAnalysisMapper.swift \
  macOS/Features/Import/MacPackageImportViewModel.swift \
  macOS/Features/Import/MacPackagePreviewView.swift \
  Shared/Models/BackupPackageManifest.swift \
  Shared/Models/BackupPackagePayload.swift \
  Shared/Models/BackupRestorePreview.swift \
  iOS/Core/Sync/BackupPackageEncoder.swift \
  iOS/Core/Sync/BackupPackageDecoder.swift \
  iOS/Core/Health/SnowHealthExporting.swift \
  iOS/Core/Health/DisabledSnowHealthExporter.swift \
  iOS/Core/Health/MockSnowHealthExporter.swift \
  Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift \
  scripts/verify_snow_backup_compatibility.py \
  scripts/verify_snow_package_compatibility.py \
  scripts/verify_snow_macos_viewer.py \
  scripts/create_snow_task008b_review_pack.sh \
  docs/history/DEV_LOG.md \
  docs/process/PHASE_1C_SNOW_AGENT_STATE.md \
  docs/reference/FILE_STRUCTURE.md \
  docs/release/KNOWN_LIMITATIONS_PRE_ADP.md \
  docs/release/MANUAL_QA_MATRIX_PRE_ADP.md \
  docs/DOCUMENTATION_INDEX.md; do
  [ -f "$rel" ] || fail "missing source file for review pack: $rel"
  copy_file "$rel"
done

cat > "$PACK_DIR/CLAUDE_REVIEW_CONTEXT.md" <<'MD'
# Snow-Task-008b Claude Review Context

Snow-Task-008b completes the backup compatibility and iOS Health provider-boundary portion of Snow-Task-008 after 008a package compatibility.

## Baseline

- Previous committed task: Snow-Task-008a package compatibility and import viewer wiring.
- 008a commit: `0d6f5c0 Add Snow package compatibility and import viewer wiring`.
- Snow-Task-008b is intentionally not committed until backup compatibility, Health boundary, docs, verify, and review pack all pass.

## Implemented backup scope

- Backup schema now uses version 2.
- Backup decoder supports schema versions 1 and 2.
- `BackupPackagePayload.snowSessions: [SnowBackupSession]?` is optional.
- Missing `snowSessions` means a legacy backup with no Snow section.
- Empty `snowSessions: []` means a Snow-aware backup with zero Snow sessions.
- New backups encode `snowSessions: []` by default.
- `BackupRestorePreview` exposes optional Snow session count.
- `SnowBackupSession` is the single Snow backup section and converts to / from `SnowSessionState`.

## Implemented Health boundary scope

- `SnowHealthExporting` protocol lives under `iOS/Core/Health/`, not `Shared/`.
- `DisabledSnowHealthExporter` is the production default.
- `DisabledSnowHealthExporter` returns unavailable and does not write to HealthKit.
- `MockSnowHealthExporter` is `#if DEBUG` only.
- No `import HealthKit` exists in `Shared/`.
- No `HKHealthStore`, `HKWorkout`, or `HKQuantitySample` implementation is added in 008b.
- Production HealthKit export remains disabled in Pre-ADP state.

## Safety boundaries

- No WatchBridge / WatchConnectivity changes.
- No watchOS Snow UI changes.
- No iOS Snow live HUD changes.
- No classifier or run-boundary logic changes.
- No core Snow value type changes.
- No `SnowPrototype*` production namespace introduced.
- No `.skatetrack` fixture files committed.
- Snow-Task-006b remains deferred until mainline Task-040.

## Review focus

Please verify:

1. Legacy backups without a `snowSessions` key decode successfully.
2. New schema 2 backups encode an empty `snowSessions` array by default.
3. Schema 2 backups with Snow sessions decode into preview counts and Snow backup DTOs.
4. Health provider boundary is iOS-only, disabled/mock only, and does not import or instantiate HealthKit.
5. 008a package compatibility still passes after 008b changes.
6. macOS / iOS / watchOS regression builds still pass.
MD

log "Creating zip..."
(
  cd "$UPLOAD_DIR"
  zip -qr "$ZIP_PATH" "SnowTask008b_ReviewPack"
)

log "Review pack created: $ZIP_PATH"
