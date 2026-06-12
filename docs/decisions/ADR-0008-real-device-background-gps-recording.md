# ADR-0008: Real-device background GPS recording strategy

## Status

Accepted for Task-027-preflight.

## Context

Real-device testing on an iPhone 13 Pro showed that a session started in the foreground could record an initial location, but after the screen was turned off and the phone was placed in a pocket, the completed session had no route movement and no speed samples. The observed result matches the pre-existing implementation: `GPSProvider` used standard foreground location updates, `pausesLocationUpdatesAutomatically` was enabled, and the generated iOS Info.plist did not declare `UIBackgroundModes = location`.

SkateTrack is a ride recording app, so locked-screen pocket recording is a core commercial requirement. However, the implementation must remain honest: it must not add fake speed, fake route points, or IMU-only route drawing when GPS updates are unavailable.

## Decision

Task-027-preflight enables real-device background location recording for active ride sessions by:

- Declaring `UIBackgroundModes = location` in the generated iOS Info.plist build settings.
- Enabling `CLLocationManager.allowsBackgroundLocationUpdates` only when the app bundle actually declares the background location mode.
- Showing the system background location indicator during active background-capable ride recording.
- Disabling automatic location pausing while active ride recording is running.
- Requesting an Always authorization upgrade when the app already has When In Use location access and a real session needs background recording.
- Keeping the initial permission request as When In Use so the first-run prompt remains understandable.
- Emitting location-driven motion samples in addition to the 10 Hz timer so background Core Location callbacks can still preserve route data if normal timers are throttled.
- Deriving a conservative GPS speed from consecutive accepted locations when `CLLocation.speed` is unavailable.
- Relaxing the accepted horizontal accuracy from 20 m to 35 m to reduce false empty-route results in outdoor pocket tests while keeping poor-quality fixes filtered.

## Consequences

This makes locked-screen outdoor test sessions more likely to preserve route and speed data, while still relying on real GPS updates and real Core Location authorization.

The implementation changes generated Info.plist behavior but does not add an entitlements file, does not modify signing identities, and does not add App Store / Google / cloud service credentials.

## Deferred

- Full battery policy and long-session power profiling.
- Fine-grained runtime diagnostics screen for authorization status, precise-location status, accepted / rejected GPS counts, and last GPS sample age.
- User education flow for denied Always permission and reduced-accuracy location.
- App Store privacy review copy for production release readiness.
- Background recording recovery after force quit or system termination.
- Indoor / GPS-denied odometry, IMU-only route drawing, ARKit route tracking, UWB venue tracking, and any fake speed or fake route generation.
