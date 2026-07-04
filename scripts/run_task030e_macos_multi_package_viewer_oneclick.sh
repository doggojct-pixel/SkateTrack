#!/usr/bin/env bash
set +e

REPO="${1:-/Users/doggo/Documents/App軟體區/SkateTrack}"
UPLOAD_DIR="/Users/doggo/Documents/App軟體區/upload"
TS=$(date +"%Y%m%d_%H%M%S")
RUN_NAME="task030e_macos_multi_package_viewer_oneclick_${TS}"
RUN_DIR="${UPLOAD_DIR}/${RUN_NAME}"
ZIP_PATH="${UPLOAD_DIR}/${RUN_NAME}.zip"
POSTPACK_LOG="${UPLOAD_DIR}/${RUN_NAME}_postpack.log"
SUMMARY_LOG="${RUN_DIR}/summary.log"

mkdir -p "${UPLOAD_DIR}"
rm -rf "${RUN_DIR}"
mkdir -p "${RUN_DIR}"

{
  echo "===== Task-030e macOS multi-package viewer one-click verification ====="
  echo "對齊 Build Plan: SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2"
  echo "對齊子任務: task-030e-MacViewer-013 — Manual QA Gate"
  echo "未實作: 014 final merge gate, Task-031-prep shared activity visualization pipeline, package merge, duplicate deletion, winner selection, local-history import, route correction, road matching, snap-to-road, route reconstruction, location permission, user-location display, route geometry mutation, trusted metrics mutation, package schema change, Core Data write"
  echo "REPO=${REPO}"
  echo "UPLOAD_DIR=${UPLOAD_DIR}"
  echo "RUN_DIR=${RUN_DIR}"
  echo "ZIP_PATH=${ZIP_PATH}"
  echo

  if [ ! -d "${REPO}/.git" ]; then
    echo "REPO_CHECK=FAILED_not_a_git_repo"
    FAILURE_COUNT=1
  else
    cd "${REPO}"
    CD_EXIT=$?
    echo "CD_EXIT=${CD_EXIT}"
    FAILURE_COUNT=0

    echo
    echo "===== git context ====="
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
    echo "CURRENT_BRANCH=${CURRENT_BRANCH}"
    echo "HEAD_COMMIT=${HEAD_COMMIT}"
    git status -sb
    if [ "${CD_EXIT}" != "0" ]; then FAILURE_COUNT=$((FAILURE_COUNT + 1)); fi

    run_python_verifier() {
      SCRIPT_PATH="$1"
      LABEL=$(basename "${SCRIPT_PATH}" .py)
      LOG_FILE="${RUN_DIR}/${LABEL}.log"
      echo
      echo "===== ${LABEL} ====="
      if [ -f "${SCRIPT_PATH}" ]; then
        python3 "${SCRIPT_PATH}" > "${LOG_FILE}" 2>&1
        EXIT_CODE=$?
      else
        echo "Missing verifier: ${SCRIPT_PATH}" > "${LOG_FILE}"
        EXIT_CODE=99
      fi
      cat "${LOG_FILE}"
      echo "${LABEL}_EXIT=${EXIT_CODE}"
      if [ "${EXIT_CODE}" != "0" ]; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
      fi
    }

    run_python_verifier "scripts/verify_task030e_macos_multi_package_viewer.py"
    run_python_verifier "scripts/verify_task030e_documentation_sync.py"
    run_python_verifier "scripts/verify_task030e_manual_qa_gate.py"
    run_python_verifier "scripts/verify_task030e_localization_accessibility.py"
    run_python_verifier "scripts/verify_task030e_duplicate_acknowledgement.py"
    run_python_verifier "scripts/verify_task030e_duplicate_attention.py"
    run_python_verifier "scripts/verify_task030e_elevation_profile.py"
    run_python_verifier "scripts/verify_task030e_selected_session_detail_layout.py"
    run_python_verifier "scripts/verify_task030e_route_visual_inspection.py"
    run_python_verifier "scripts/verify_task030e_mapkit_route_context.py"
    run_python_verifier "scripts/verify_task030e_selected_package_sessions.py"
    run_python_verifier "scripts/verify_task030e_package_cards.py"
    run_python_verifier "scripts/verify_task030e_multi_file_open.py"
    run_python_verifier "scripts/verify_task030e_multi_package_state.py"
    run_python_verifier "scripts/verify_task030e_browser_first_ia.py"
    run_python_verifier "scripts/verify_macos_package_preview.py"
    run_python_verifier "scripts/verify_macos_session_viewer.py"
    run_python_verifier "scripts/verify_macos_route_chart_viewer.py"
    run_python_verifier "scripts/verify_localization_keys.py"

    echo
    echo "===== xcodebuild macOS build ====="
    XCODEBUILD_LOG="${RUN_DIR}/xcodebuild_macos_build.log"
    xcodebuild \
      -workspace SkateTrack.xcworkspace \
      -scheme SkateTrack-macOS \
      -destination 'platform=macOS' \
      build > "${XCODEBUILD_LOG}" 2>&1
    XCODEBUILD_EXIT=$?
    tail -120 "${XCODEBUILD_LOG}"
    echo "xcodebuild_macos_build_EXIT=${XCODEBUILD_EXIT}"
    if [ "${XCODEBUILD_EXIT}" != "0" ]; then FAILURE_COUNT=$((FAILURE_COUNT + 1)); fi

    echo
    echo "===== focused Swift line check ====="
    LINE_LOG="${RUN_DIR}/line_check.log"
    python3 - <<'PY' > "${LINE_LOG}" 2>&1
from pathlib import Path
root = Path(".")
paths = []
for directory in [
    "macOS/App",
    "macOS/Features/SessionBrowser",
    "macOS/Features/Import",
    "macOS/Features/Shared",
]:
    base = root / directory
    if base.exists():
        paths.extend(sorted(base.rglob("*.swift")))
failures = []
for path in paths:
    count = len(path.read_text(encoding="utf-8").splitlines())
    print(f"{count:4d} {path}")
    if count > 500:
        failures.append((str(path), count))
if failures:
    print("LINE_CHECK_RESULT=FAILED")
    for path, count in failures:
        print(f"LINE_CHECK_FAILURE={path}:{count}")
    raise SystemExit(1)
print("LINE_CHECK_RESULT=PASSED")
PY
    LINE_EXIT=$?
    cat "${LINE_LOG}"
    echo "LINE_EXIT=${LINE_EXIT}"
    if [ "${LINE_EXIT}" != "0" ]; then FAILURE_COUNT=$((FAILURE_COUNT + 1)); fi

    echo
    echo "===== git diff --check ====="
    git diff --check > "${RUN_DIR}/git_diff_check.log" 2>&1
    DIFF_CHECK_EXIT=$?
    cat "${RUN_DIR}/git_diff_check.log"
    echo "DIFF_CHECK_EXIT=${DIFF_CHECK_EXIT}"
    if [ "${DIFF_CHECK_EXIT}" != "0" ]; then FAILURE_COUNT=$((FAILURE_COUNT + 1)); fi

    echo
    echo "===== git status ====="
    git status -sb > "${RUN_DIR}/git_status_after.log" 2>&1
    STATUS_EXIT=$?
    cat "${RUN_DIR}/git_status_after.log"
    echo "STATUS_EXIT=${STATUS_EXIT}"
    if [ "${STATUS_EXIT}" != "0" ]; then FAILURE_COUNT=$((FAILURE_COUNT + 1)); fi
  fi

  echo
  echo "FAILURE_COUNT=${FAILURE_COUNT}"
  if [ "${FAILURE_COUNT}" = "0" ]; then
    echo "OVERALL_RESULT=PASSED"
    echo "ONECLICK_RESULT=PASSED"
  else
    echo "OVERALL_RESULT=FAILED"
    echo "ONECLICK_RESULT=FAILED"
  fi

  echo "ONECLICK_SUMMARY_LOG=${SUMMARY_LOG}"
} 2>&1 | tee "${SUMMARY_LOG}"

cd "${UPLOAD_DIR}"
zip -qr "${ZIP_PATH}" "${RUN_NAME}"
ONECLICK_ZIP_EXIT=$?

rm -rf "${RUN_DIR}"
ONECLICK_CLEANUP_EXIT=$?

if [ ! -d "${RUN_DIR}" ]; then
  ONECLICK_RUN_DIR_REMOVED="YES"
else
  ONECLICK_RUN_DIR_REMOVED="NO"
fi

{
  echo "===== Task-030e macOS multi-package viewer one-click postpack cleanup ====="
  echo "ZIP_PATH=${ZIP_PATH}"
  echo "ONECLICK_ZIP_EXIT=${ONECLICK_ZIP_EXIT}"
  echo "ONECLICK_CLEANUP_EXIT=${ONECLICK_CLEANUP_EXIT}"
  echo "ONECLICK_RUN_DIR_REMOVED=${ONECLICK_RUN_DIR_REMOVED}"
  echo "Terminal remains open."
} 2>&1 | tee "${POSTPACK_LOG}"

if [ -f "${ZIP_PATH}" ]; then
  zip -qj "${ZIP_PATH}" "${POSTPACK_LOG}"
  POSTPACK_LOG_ZIP_EXIT=$?
else
  POSTPACK_LOG_ZIP_EXIT=99
fi

echo "POSTPACK_LOG_ZIP_EXIT=${POSTPACK_LOG_ZIP_EXIT}"
rm -f "${POSTPACK_LOG}"
echo "ONECLICK_ZIP_PATH=${ZIP_PATH}"
echo "Terminal remains open."
