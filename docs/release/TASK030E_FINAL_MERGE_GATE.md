# Task-030e-MacViewer-014 final merge gate checklist

**Status:** Final merge gate checklist for Task-030e macOS multi-package viewer.
**Last Updated:** 2026-07-04
**Scope:** Final verification and merge-readiness gate before merging `task-030e-macos-multi-package-viewer` back into `develop`.

This file is the Task-030e final merge gate checklist. It does not add product behavior. It is a source-controlled closure checklist for branch hygiene, automated verification evidence, manual QA signoff, and explicit no-scope-expansion review.

## 1. Required branch preconditions

The final merge gate may proceed only when all of these are true:

- Current working branch is `task-030e-macos-multi-package-viewer` before final Task-030e verification.
- `d14581f Task-030e-013 add manual QA gate` is an ancestor of the current branch head.
- `origin/develop` is an ancestor of the current branch head, or the branch is rebased / merged from latest `develop` and reverified before merge.
- The task branch head is not already merged into `origin/develop` before the final gate records the merge decision.
- `git status --short` is clean before starting final merge commands.
- No unreviewed local Xcode scheme, signing, entitlement, Info.plist, UTType, or document-association drift is present.

## 2. Required automated evidence

Upload and review these before merge:

```text
/Users/doggo/Documents/App軟體區/upload/task030e_014_apply_*.log
/Users/doggo/Documents/App軟體區/upload/task030e_014_oneclick_*.zip
```

Required automated results:

- `APPLY_RESULT=PASSED`
- `verify_task030e_final_merge_gate_EXIT=0`
- `verify_task030e_manual_qa_gate_EXIT=0`
- `verify_task030e_documentation_sync_EXIT=0`
- `verify_task030e_macos_multi_package_viewer_EXIT=0`
- `xcodebuild_macos_build_EXIT=0`
- `LINE_CHECK_RESULT=PASSED`
- `DOC_EOF_RESULT=PASSED`
- `DIFF_CHECK_EXIT=0`
- `STATUS_EXIT=0`
- `OVERALL_RESULT=PASSED`
- `ONECLICK_RESULT=PASSED`
- `ONECLICK_ZIP_EXIT=0`
- `ONECLICK_CLEANUP_EXIT=0`
- `ONECLICK_RUN_DIR_REMOVED=YES`

## 3. Manual signoff carried into final merge

Task-030e-MacViewer-014 depends on the Task-030e-MacViewer-013 manual QA gate. Final merge is blocked unless the operator has already confirmed manual QA success and the evidence covers:

- macOS app launches successfully.
- Session Browser opens `.skatetrack` packages.
- Multi-file open works with valid and invalid file combinations.
- Duplicate file warnings appear when expected.
- Duplicate acknowledgement clears only the transient duplicate-file warning state.
- Package cards and selected package sessions remain usable.
- Route context, expanded route inspection, speed chart, elevation profile, and total ascent display remain display-only.
- `zh-Hant`, `en`, and `ja` copy and accessibility labels remain aligned.
- No location prompt appears.
- No user-location blue dot appears.

## 4. Final no-scope-expansion checks

Task-030e final merge must not introduce or claim any of these:

- no import into local history
- no package merge
- no duplicate deletion
- no winner selection
- no route correction
- no road matching
- no snap-to-road
- no route reconstruction
- no route geometry mutation
- no trusted metrics mutation
- no package schema change
- no Core Data write
- no location permission
- no user-location display
- no Watch or WatchBridge behavior
- no Task-031-prep shared activity visualization pipeline implementation

## 5. Merge command policy

The assistant may provide final merge commands only after all 014 logs and manual confirmation are reviewed. The merge command should:

- fetch `origin`
- verify the task branch and `develop` ancestry
- switch to `develop`
- fast-forward or non-fast-forward merge only according to the current repository state and user approval
- run the source-controlled Task-030e one-click verification after merge
- push `develop` only if the merge verification passes
- leave `main` untouched

Task-030e-MacViewer-014 verification token: Final Merge Gate, task030e_014_oneclick, verify_task030e_final_merge_gate.py, develop merge readiness, origin/develop ancestry, ONECLICK_RUN_DIR_REMOVED=YES, no import / merge / route mutation, no schema / Core Data mutation.
