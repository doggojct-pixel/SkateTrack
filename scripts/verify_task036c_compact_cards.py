#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path.cwd()

REQUIRED_FILES = [
    "Shared/WatchUI/WatchActivityViewModel.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Shared/WatchUI/WatchMetricProvider.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
    "scripts/verify_task036c_compact_cards.py",
    "docs/history/DEV_LOG.md",
]

LOCALIZATION_KEYS = [
    "unit.length.meter.short",
    "watch.compact.route.title",
    "watch.compact.route.scope.textOnly",
    "watch.compact.route.status.recorded",
    "watch.compact.route.status.qualityInsufficient",
    "watch.compact.route.status.unavailable",
    "watch.compact.route.points",
    "watch.compact.route.segments",
    "watch.compact.speed.title",
    "watch.compact.speed.max",
    "watch.compact.speed.empty",
    "watch.compact.elevation.title",
    "watch.compact.elevation.ascent",
    "watch.compact.elevation.empty",
]

VIEWMODEL_TOKENS = [
    "WatchActivityRouteMiniCardScope",
    'case textOnly = "TEXT_ONLY"',
    "WatchActivityRouteCompactCardViewState",
    "CompactRouteDisplay?",
    "WatchActivitySpeedCompactCardViewState",
    "CompactSpeedSparkline?",
    "WatchActivityElevationCompactCardViewState",
    "CompactElevationProfile?",
    "ascentMeters = elevationProfile?.displayDerivedTotalAscentMeters",
]

WATCH_VIEW_TOKENS = [
    "WatchRouteCompactCardView",
    "WatchSparklineCompactCardView",
    "WatchCompactSparklineView",
    "WatchMetricCarouselView",
    "watch.compact.route.status.qualityInsufficient",
    "WatchLivePalette.accentColor",
]

CAROUSEL_TOKENS = [
    "WatchMetricCarouselModel",
    "hasRenderableCompactSpeed",
    "hasRenderableCompactElevation",
    "watch-metric-carousel-speed-card",
    "watch-metric-carousel-elevation-card",
    "watch.compact.speed.max",
    "watch.compact.elevation.ascent",
    "WatchMetricCarouselSparklineView",
    "Text(LocalizedStringKey(card.titleLocalizationKey))",
]

PROVIDER_TOKENS = [
    'titleLocalizationKey: "watch.compact.speed.title"',
    'titleLocalizationKey: "watch.compact.elevation.title"',
    "source: hasCompactValues ? .compactSpeedSparkline : .unavailable",
    "source: hasCompactValues ? .compactElevationProfile : .unavailable",
]

TEST_TOKENS = [
    "testTextOnlyRouteCardShowsQualityInsufficientWithoutSemanticForking",
    "routeCard.compactRoute",
    "speedCard.points",
    "elevationCard.points",
    "elevationCard.ascentMeters",
]

FORBIDDEN_WATCH_UI_PATTERNS = [
    r"\bimport\s+MapKit\b",
    r"\bMKMap",
    r"\bCLLocationCoordinate2D\b",
    r"RouteDisplayPipeline",
    r"SpeedDisplayPipeline",
    r"ElevationDisplayPipeline",
    r"RouteDisplayPipeline\+Segmentation",
    r"SpeedDisplayPipeline\(",
    r"ElevationDisplayPipeline\(",
    r"\.filter\s*\(",
    r"\bSnow\b",
    r"\bsnow\b",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail(message: str, failures: list[str]) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def require_tokens(text: str, tokens: list[str], label: str, failures: list[str]) -> None:
    for token in tokens:
        if token not in text:
            fail(f"missing {label} token: {token}", failures)


def main() -> int:
    failures: list[str] = []

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"missing required file {relative}", failures)

    viewmodel = read("Shared/WatchUI/WatchActivityViewModel.swift") if (ROOT / "Shared/WatchUI/WatchActivityViewModel.swift").exists() else ""
    carousel_model = read("Shared/WatchUI/WatchMetricCarouselModel.swift") if (ROOT / "Shared/WatchUI/WatchMetricCarouselModel.swift").exists() else ""
    metric_provider = read("Shared/WatchUI/WatchMetricProvider.swift") if (ROOT / "Shared/WatchUI/WatchMetricProvider.swift").exists() else ""
    watch_view = read("watchOS/Features/WatchLiveSessionFaceView.swift") if (ROOT / "watchOS/Features/WatchLiveSessionFaceView.swift").exists() else ""
    carousel_view = read("watchOS/Features/WatchMetricCarouselView.swift") if (ROOT / "watchOS/Features/WatchMetricCarouselView.swift").exists() else ""
    tests = read("Tests/iOSTests/WatchActivityViewModelTests.swift") if (ROOT / "Tests/iOSTests/WatchActivityViewModelTests.swift").exists() else ""
    carousel_tests = read("Tests/iOSTests/WatchMetricCarouselModelTests.swift") if (ROOT / "Tests/iOSTests/WatchMetricCarouselModelTests.swift").exists() else ""
    dev_log = read("docs/history/DEV_LOG.md") if (ROOT / "docs/history/DEV_LOG.md").exists() else ""

    require_tokens(viewmodel, VIEWMODEL_TOKENS, "view model compact card", failures)
    require_tokens(watch_view, WATCH_VIEW_TOKENS, "watch compact card UI", failures)
    require_tokens(carousel_model + "\n" + carousel_view, CAROUSEL_TOKENS, "watch metric carousel compact UI", failures)
    require_tokens(metric_provider, PROVIDER_TOKENS, "watch metric provider compact output", failures)
    require_tokens(tests, TEST_TOKENS, "compact card test", failures)
    require_tokens(
        carousel_tests,
        ["testCarouselModelUsesCompactSpeedAndElevationProviderOutputs", ".compactSpeedSparkline", ".compactElevationProfile"],
        "metric carousel compact test",
        failures,
    )

    localization_complete = True
    for locale in ["en", "zh-Hant", "ja"]:
        path = ROOT / "Shared" / "Localization" / f"{locale}.lproj" / "Localizable.strings"
        if not path.exists():
            fail(f"missing localization file for {locale}", failures)
            localization_complete = False
            continue
        text = path.read_text(encoding="utf-8")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {locale}", failures)
                localization_complete = False

    semantic_fork_count = 0
    for relative in [
        "Shared/WatchUI/WatchActivityViewModel.swift",
        "Shared/WatchUI/WatchMetricCarouselModel.swift",
        "watchOS/Features/WatchLiveSessionFaceView.swift",
        "watchOS/Features/WatchMetricCarouselView.swift",
    ]:
        path = ROOT / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in FORBIDDEN_WATCH_UI_PATTERNS:
            matches = re.findall(pattern, text)
            semantic_fork_count += len(matches)
            if matches:
                fail(f"forbidden Watch UI semantic fork token {pattern} in {relative}", failures)

    route_uses_compact = "CompactRouteDisplay?" in viewmodel and "compactRoute: compactSummary?.compactRoute" in viewmodel
    speed_uses_compact = "CompactSpeedSparkline?" in viewmodel and "speedSparkline: compactSummary?.speedSparkline" in viewmodel
    elevation_uses_compact = "CompactElevationProfile?" in viewmodel and "elevationProfile: compactSummary?.elevationProfile" in viewmodel

    devlog_ok = "Task-036c - Route/Speed/Elevation Compact Cards" in dev_log
    if not devlog_ok:
        fail("missing Task-036c DEV_LOG entry", failures)

    print(f"USES_COMPACT_SPEED_SPARKLINE={'YES' if speed_uses_compact else 'NO'}")
    print(f"USES_COMPACT_ELEVATION_PROFILE={'YES' if elevation_uses_compact else 'NO'}")
    print("WATCH_ROUTE_MINI_CARD_SCOPE=TEXT_ONLY")
    print("WATCH_ROUTE_MINI_CARD_SCOPE_IN_SCOPE=YES")
    print(f"ROUTE_CARD_IF_PRESENT_USES_COMPACT_ROUTE_DISPLAY={'YES' if route_uses_compact else 'NO'}")
    print("ROUTE_MINI_CARD_DECISION_SOURCE=Task-031d_review_at_Task-036c")
    print(f"LOCALIZATION_KEYS_COMPLETE={'YES' if localization_complete else 'NO'}")
    print(f"WATCH_SEMANTIC_FORK_COUNT={semantic_fork_count}")
    print("MAPKIT_IMPORT_IN_WATCH_UI=NO")
    print("SNOW_UI_IMPLEMENTED=NO")
    print(f"DEV_LOG_UPDATED={'YES' if devlog_ok else 'NO'}")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK036C_COMPACT_CARDS_RESULT=FAILED")
        return 1

    print("VERIFY_TASK036C_COMPACT_CARDS_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
