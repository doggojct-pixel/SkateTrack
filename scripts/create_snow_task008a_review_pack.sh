#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPLOAD_DIR="/Users/doggo/Documents/App軟體區/upload"
PACK_DIR="$UPLOAD_DIR/SnowTask008a_ReviewPack"
ZIP_PATH="$UPLOAD_DIR/SnowTask008a_ReviewPack.zip"

log() { echo "[snow-task-008a-review] $1"; }
fail() { echo "[snow-task-008a-review] ERROR: $1" >&2; exit 1; }

mkdir -p "$UPLOAD_DIR"
rm -rf "$PACK_DIR" "$ZIP_PATH"
mkdir -p "$PACK_DIR/SOURCE_FILES"
cd "$ROOT"

log "Collecting git state..."
git status --short > "$PACK_DIR/GIT_STATUS_SHORT.txt"
git diff --stat > "$PACK_DIR/GIT_DIFF_STAT_SNOW_TASK_008A_ONLY.txt"
git diff --name-only > "$PACK_DIR/GIT_DIFF_NAME_ONLY_SNOW_TASK_008A_ONLY.txt"
git log --oneline -12 > "$PACK_DIR/GIT_LOG_ONELINE_12.txt"

log "Running verify scripts..."
{
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
  python3 - <<'PY'
from pathlib import Path
root = Path('.').resolve()
text = (root/'Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift').read_text(encoding='utf-8')
required = [
    'testDecodeSchemaVersion1PackageWithoutSnowFieldsSucceeds',
    'testDecodeSchemaVersion2PackageWithoutSnowPayloadSucceeds',
    'testDecodeUnknownSchemaVersionFails',
]
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit('missing old package decode tests: ' + ', '.join(missing))
print('PASS: schema 1 legacy package decode and schema 2 nil snowPayload tests are present.')
PY
} > "$PACK_DIR/SAFETY_CHECK_OLD_PACKAGE_DECODE.txt" 2>&1

{
  python3 - <<'PY'
from pathlib import Path
root = Path('.').resolve()
text = (root/'Shared/Models/SkateTrackPackageSnowPayload.swift').read_text(encoding='utf-8')
required = ['snow-sports-v1', 'snow-segments-v1', 'snow-distance-breakdown-v1', 'snow-lift-exclusion-v1']
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit('missing snow capabilities: ' + ', '.join(missing))
print('PASS: Snow package capability keys are present.')
PY
} > "$PACK_DIR/SAFETY_CHECK_SNOW_CAPABILITIES.txt" 2>&1

{
  python3 - <<'PY'
from pathlib import Path
root = Path('.').resolve()
text = (root/'Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift').read_text(encoding='utf-8')
required = ['testDecodeSchemaVersion2PackageWithSnowPayloadSucceeds', 'testExportProviderIncludesSnowPayloadForSnowSessionWithRepositoryState']
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit('missing snow payload round-trip/provider tests: ' + ', '.join(missing))
print('PASS: Snow payload decode and export provider inclusion tests are present.')
PY
} > "$PACK_DIR/SAFETY_CHECK_SNOW_PAYLOAD_ROUNDTRIP.txt" 2>&1

{
  if grep -R "SnowPrototype\|MacSnowPrototype" Shared iOS macOS Tests --include='*.swift' >/tmp/snow008a_prototype_hits.txt 2>/dev/null; then
    cat /tmp/snow008a_prototype_hits.txt
    exit 1
  fi
  echo "PASS: No SnowPrototype / MacSnowPrototype references found in production Swift scan paths."
} > "$PACK_DIR/SAFETY_CHECK_SNOWPROTOTYPE_REFERENCES.txt" 2>&1

{
  if grep -R "WCSession\|WatchConnectivity" Shared/Models Shared/Export iOS/Core/Export macOS/Core/Snow macOS/Features/Import Tests/iOSTests --include='*.swift' >/tmp/snow008a_watch_hits.txt 2>/dev/null; then
    cat /tmp/snow008a_watch_hits.txt
    exit 1
  fi
  echo "PASS: No WatchBridge / WatchConnectivity scope added in 008a package compatibility paths."
} > "$PACK_DIR/SAFETY_CHECK_WATCHBRIDGE_REFERENCES.txt" 2>&1

{
  if grep -R "import HealthKit" Shared --include='*.swift' >/tmp/snow008a_healthkit_hits.txt 2>/dev/null; then
    cat /tmp/snow008a_healthkit_hits.txt
    exit 1
  fi
  echo "PASS: No import HealthKit in Shared/."
} > "$PACK_DIR/SAFETY_CHECK_HEALTHKIT_IN_SHARED.txt" 2>&1

{
  if find . -path './.git' -prune -o -name '*.skatetrack' -print | grep . >/tmp/snow008a_skatetrack_hits.txt; then
    cat /tmp/snow008a_skatetrack_hits.txt
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
  Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift \
  scripts/verify_snow_package_compatibility.py \
  scripts/verify_snow_macos_viewer.py \
  scripts/create_snow_task008a_review_pack.sh \
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
# Snow-Task-008a Claude Review Context

Snow-Task-008a adds official optional Snow package payload compatibility for `.skatetrack` exports and imports.

## Baseline

- Previous task: Snow-Task-007 read-only macOS Snow viewer.
- Snow-Task-007 introduced `MacSnowSessionAnalysis`, `MacSnowAnalysisAvailability`, and `packageSchemaPending` for imported `.skatetrack` packages without official Snow payload.
- Snow-Task-008a fills that package payload gap only.

## Implemented scope

- Package schema bumped from version 1 to version 2.
- Reader supports schema versions 1 and 2.
- `capabilities: [String]?` is optional so schema 1 packages decode without error.
- `SkateTrackPackageSnowPayload` is a new production type, not a prototype type.
- `SkateTrackPackageSession.snowPayload` is optional.
- Non-Snow exports keep `snowPayload == nil`.
- Snow exports only include `snowPayload` when real `SnowSessionState` is available from `SnowSessionRepositoryProtocol`.
- Snow session with no repository Snow state uses `snowPayload == nil`; no empty placeholder payload is fabricated.
- macOS imported Snow packages call `MacSnowSessionAnalysisMapper.makeAvailabilityFromPackage(...)`.
- Valid package payload maps into `MacSnowRootView` with source `.importedPackage`.
- Missing payload maps to `packageSchemaPending`.
- `snowPayload.sessionID` mismatch maps to `unavailable(reason: "snowPayloadSessionMismatch")`.

## Explicitly deferred to 008b

- Backup schema compatibility.
- `SnowHealthExporter` / disabled / mock provider boundary.
- Production HealthKit export.

## Safety boundaries

- No WatchBridge / WatchConnectivity changes.
- No watchOS Snow UI changes.
- No iOS Snow live HUD changes.
- No classifier or run-boundary logic changes.
- No `SnowPrototype*` production namespace introduced.
- No `.skatetrack` fixture files committed.
- No `import HealthKit` in `Shared/`.

## Review focus

Please verify:

1. Old schema-1 packages remain decodable.
2. Schema-2 packages with nil `snowPayload` remain valid and map to `packageSchemaPending`.
3. Schema-2 packages with Snow payload round-trip into package-backed macOS Snow analysis.
4. iOS export provider only emits Snow payload from real repository state.
5. Non-Snow package behavior is unchanged.
6. 008b backup / Health work has not leaked into 008a.
MD

log "Creating zip..."
(
  cd "$UPLOAD_DIR"
  zip -qr "$ZIP_PATH" "SnowTask008a_ReviewPack"
)

log "Review pack created: $ZIP_PATH"
