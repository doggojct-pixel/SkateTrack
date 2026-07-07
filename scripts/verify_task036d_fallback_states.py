#!/usr/bin/env python3
# [Collaboration] scripts/verify_task036d_fallback_states.py
"""Verify Task-036d Watch fallback/Always-On state boundaries."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def has_all(text: str, tokens: list[str]) -> bool:
    return all(token in text for token in tokens)


def main() -> int:
    failures: list[str] = []

    view_model_path = "Shared/WatchUI/WatchActivityViewModel.swift"
    watch_view_path = "watchOS/Features/WatchLiveSessionFaceView.swift"
    tests_path = "Tests/iOSTests/WatchActivityViewModelTests.swift"
    dev_log_path = "docs/history/DEV_LOG.md"

    view_model = read(view_model_path)
    watch_view = read(watch_view_path)
    tests = read(tests_path)
    dev_log = read(dev_log_path)

    required_view_model_tokens = [
        "enum WatchActivityFallbackKind",
        "case disconnected",
        "case noSamples",
        "case disabledProvider",
        "case staleData",
        "WatchActivityFallbackViewState",
        "connection.isDisconnected",
        "connection.isStale",
        "samples.isDisabled",
        "!samples.hasAnySampleData && !compactSummary.hasAnyDisplayData",
    ]
    if not has_all(view_model, required_view_model_tokens):
        failures.append("fallback view-model states are incomplete")

    required_watch_tokens = [
        "@Environment(\\.isLuminanceReduced)",
        "WatchFallbackBannerView",
        "WatchAlwaysOnFallbackView",
        "watch-always-on-fallback",
        "state.accessibilityIdentifier",
        "watch.fallback.alwaysOn.title",
    ]
    if not has_all(watch_view, required_watch_tokens):
        failures.append("watch fallback/Always-On UI tokens are incomplete")

    required_test_tokens = [
        "testDisconnectedFallbackWhenWatchBridgeIsUnavailable",
        "testNoSamplesFallbackWhenActiveSessionHasNoDisplayData",
        "testDisabledProviderFallbackWhenProviderIsDisabled",
        "testStaleDataFallbackWhenTransportQualityIsStale",
        "XCTAssertEqual(viewModel.fallback.kind, .ready)",
    ]
    if not has_all(tests, required_test_tokens):
        failures.append("view-model fallback tests are incomplete")

    required_localization_keys = [
        "watch.fallback.ready.title",
        "watch.fallback.ready.detail",
        "watch.fallback.disconnected.title",
        "watch.fallback.disconnected.detail",
        "watch.fallback.noSamples.title",
        "watch.fallback.noSamples.detail",
        "watch.fallback.disabledProvider.title",
        "watch.fallback.disabledProvider.detail",
        "watch.fallback.staleData.title",
        "watch.fallback.staleData.detail",
        "watch.fallback.alwaysOn.title",
        "watch.fallback.alwaysOn.detail",
    ]
    for locale in ("en", "zh-Hant", "ja"):
        localization = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        missing = [key for key in required_localization_keys if f'"{key}"' not in localization]
        if missing:
            failures.append(f"{locale} localization missing keys: {', '.join(missing)}")

    if "TASK036D_FALLBACK_STATES_DEVLOG_START" not in dev_log:
        failures.append("Task-036d dev log entry missing")

    forbidden_watch_tokens = [
        "import MapKit",
        "CLLocationCoordinate2D",
        "MKMap",
        "MKPolyline",
        "ski",
        "snow",
        "Snow",
        "route segmentation",
        "speed filtering",
        "totalAscent",
    ]
    forbidden_hits = []
    for relative in (view_model_path, watch_view_path):
        text = read(relative)
        for token in forbidden_watch_tokens:
            if token in text:
                forbidden_hits.append(f"{relative}:{token}")
    if forbidden_hits:
        failures.append("forbidden Watch UI semantic tokens found: " + ", ".join(forbidden_hits))

    disconnected_present = "case disconnected" in view_model and "watch.fallback.disconnected.title" in view_model
    no_data_present = "case noSamples" in view_model and "watch.fallback.noSamples.title" in view_model
    stale_present = "case staleData" in view_model and "watch.fallback.staleData.title" in view_model

    print("DISCONNECTED_STATE_PRESENT=" + ("YES" if disconnected_present else "NO"))
    print("NO_DATA_STATE_PRESENT=" + ("YES" if no_data_present else "NO"))
    print("STALE_DATA_STATE_PRESENT=" + ("YES" if stale_present else "NO"))
    print("DISABLED_PROVIDER_STATE_PRESENT=" + ("YES" if "case disabledProvider" in view_model else "NO"))
    print("ALWAYS_ON_FALLBACK_PRESENT=" + ("YES" if "WatchAlwaysOnFallbackView" in watch_view else "NO"))
    print("LOCALIZATION_ACCESSIBILITY_PRESENT=" + ("YES" if not failures else "CHECK"))
    print("WATCH_UI_SEMANTIC_REIMPLEMENTATION_COUNT=" + str(len(forbidden_hits)))

    failure_count = len(failures)
    if failure_count:
        for failure in failures:
            print(f"FAILURE={failure}")
        print("VERIFY_TASK036D_FALLBACK_STATES_RESULT=FAILED")
    else:
        print("VERIFY_TASK036D_FALLBACK_STATES_RESULT=PASSED")
    print(f"FAILURE_COUNT={failure_count}")

    return 1 if failure_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
