# SkateTrack

SkateTrack is a native Apple ecosystem app for skateboard and inline skating session tracking.
This repository was initialized from **Build Plan v1.0 — Task-001: Project Scaffold + Git Setup**.

## Task-001 Scope

This scaffold intentionally contains **zero feature implementation**. It only establishes:

- Xcode workspace and project shell
- iOS, watchOS, and macOS app targets
- Shared folder structure following DevProcess v1.0
- SwiftLint configuration with the 450 / 500 line rule
- Initial live documentation in `docs/FILE_STRUCTURE.md` and `docs/DEV_LOG.md`
- Git repository initialized with `main` and `develop` branches

## Target Deployment Baselines

| Platform | Minimum Deployment |
|---|---:|
| iOS | 17.0 |
| watchOS | 10.0 |
| macOS | 14.0 |

## Expected Local Path

The intended local project path is:

```bash
/Users/doggo/Documents/App軟體區/SkateTrack
```

After extracting this package, place the `SkateTrack` folder at that path.

## GitHub Remote Setup

A real GitHub remote cannot be completed without your repository URL. After creating the repository on GitHub, run:

```bash
cd /Users/doggo/Documents/App軟體區/SkateTrack
./scripts/set_github_remote.sh git@github.com:YOUR_ACCOUNT/SkateTrack.git
```

## Build Notes

Open `SkateTrack.xcworkspace` in Xcode and build each shared scheme:

- `SkateTrack-iOS`
- `SkateTrack-watchOS`
- `SkateTrack-macOS`

Task-001 uses `EmptyView()` for all app entry points to avoid introducing UI scope before Task-002 and later feature tasks.

## Governance

Development follows DevProcess v1.0:

- Principle A — Soft-coded localization architecture
- Principle B — Hybrid Co-Coding Architecture
- Principle C — 500-line hard cap
- Principle D — Semantic naming
- Principle E — Live documentation protocol

Initialized on 2026-06-09.
