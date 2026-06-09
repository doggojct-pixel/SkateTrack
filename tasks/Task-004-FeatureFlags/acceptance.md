# Task-004 Acceptance Checklist

- [ ] `python3 scripts/verify_feature_flags.py` passes.
- [ ] `python3 scripts/verify_localization_keys.py` passes.
- [ ] `python3 scripts/verify_shared_models.py` passes.
- [ ] `GatedFeature` includes all 10 Build Plan Phase 1a gated features.
- [ ] `FeatureFlagEngine.hasAccess(to:)` returns subscriber-gated access for gated features.
- [ ] `FeatureFlagEngine.hasAccess(to:)` returns `true` for free features.
- [ ] DEBUG iOS simulator shows the subscription debug toggle.
- [ ] No production StoreKit implementation is added before Task-016.
- [ ] iOS, watchOS, and macOS targets still build.
