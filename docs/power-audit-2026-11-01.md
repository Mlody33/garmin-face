# Power and performance review — 2026-11-01

## Current solar-data source

Solar times use Garmin's dated `Weather.getSunrise/getSunset` API and the
last position supplied by `Position.getInfo()`, independently of weather location. This preserves
previous-day comparisons and the exact sunset-to-next-sunrise night interval.
Labels and comparisons round both event times up to whole minutes; arc progress
uses the original absolute timestamps, including across midnight and DST.
The existing `Positioning` permission permits this passive read. The lightweight
`SolarPosition` module retains the last valid device position in RAM only; it does
not start GPS, persist coordinates or fall back to the weather location. Old saved
coordinates are still deleted at startup. With no device position, solar data is
unavailable rather than calculated for a substitute location. Regression tests
cover dated next-day sunrise, rounded comparisons, midnight, DST, position-cache
recovery and independence from the weather observation location.
The measurements below describe the earlier implementation and have not been
remeasured for this change.

## Audit baseline

The baseline is the working tree immediately before this review, including the
recent weather, solar-time, arc and sleep-mode changes. It is not the deployed
0.1.4 release. Appearance and update frequency are preserved.

## Changes

- **Seconds rendering:** every active `onUpdate()` already restores the whole
  scene bitmap. The digit renderer now draws its two opaque tiles directly,
  without clearing the same area again or changing the clipping region. The
  unused previous-second path has been removed. Proportional fallback fonts keep
  their native text spacing and clipping, using the restored scene as background.
- **Battery text:** the reader normalizes valid battery readings to the whole
  percentage that is actually displayed. Fractional changes no longer invalidate
  the formatted-text cache. Read frequency and displayed values are unchanged.
- **Position caching:** rounded coordinate keys are cached alongside the last
  position. Each refresh avoids converting the previous position back to degrees
  and rounding it again. The existing 0.001-degree threshold for saving a changed
  position remains the same; exact current coordinates are still retained.
- **Regression tests:** digital seconds are tested for all 60 values, both themes
  and several font sizes. Since the renderer no longer depends on the previous
  digit, the former exhaustive pairs of previous/current seconds were redundant.

## Review of the rest of the project

- `GarminFaceView` uses one reusable full-scene bitmap. Full updates restore the
  display after overlays and menus. Rendering is skipped when cached visible data
  is unchanged; copying the scene is still required on a full update.
- Sleep mode has no application `onPartialUpdate()` implementation, custom timer
  or background service. Seconds, arcs, metric icons and solar labels stay hidden.
  Solar work and goal-progress calculations are skipped while asleep. Activity
  data is read only when needed by visible fields or active arcs.
- `MetricFields` shares repeated readings between slots and formats changed
  values only. Heart rate comes from the existing system complication rather than
  a new sensor session. Independent battery/heart-rate fields do not require an
  activity-monitor read.
- `WeatherRow` reads cached weather at most once per minute or on return to the
  face. Text widths are measured only when date/temperature text changes. The
  feels-like value is taken from the same reading.
- `SunArc` caches solar labels. `SolarTimes` caches dated events by day and rounded
  position. Minute rounding, previous-day comparisons, DST handling and exact
  event timestamps for progress remain unchanged by this review.
- `SolarPosition` reads existing position data and saves changed coordinates
  conditionally. It does not enable GPS or location events.
- `FaceFonts`, `DataIcons`, `FaceColors` and `FaceOptions` reuse resources and
  settings in memory. Native anti-aliasing and the full device palette are kept
  for the existing visual quality.
- App initialization, customization and metric navigation run at startup or in
  response to interaction. The build uses `-O 3p`; test code is excluded from the
  normal PRG. The manifest and build/key-generation scripts were also reviewed.

## Measurements

FR955 simulator, device API 5.2.0, SDK 9.3.0, compiler optimization `-O 3p`.
Three alternating before/after pairs, with a warm-up frame before each measurement.
The same settings and simulator session were used; visible activity values were
stable. Results below are medians in milliseconds.

| Scenario | Before | After |
| --- | ---: | ---: |
| 50 active full updates, dark background | 111 | 102 |
| 50 active full updates, light background | 111 | 96 |
| 50 sleep-mode full updates, dark background | 73 | 74 |
| 50 sleep-mode full updates, light background | 73 | 74 |
| 1,200 digit draws, dark background | 494 | 425 |
| 1,200 digit draws, light background | 701 | 455 |

Active full updates were approximately 8–14% faster in this sample. The one-ms
sleep-mode difference is within the observed timing variation; no sleep-mode
speedup is claimed. The standalone digit timings were more variable, especially
on the light background, and should not be generalized to the whole face.

The unchanged native-text control had before/after medians of 717/722 ms on dark
and 728/719 ms on light. An earlier stalled simulator session produced errors and
much slower control results; it was restarted and those samples were excluded.

These are simulator execution/graphics timings, not current draw, display-transfer
energy or battery-life measurements. Real energy savings require a comparison on
the physical FR955 under comparable use, notifications, gestures and lighting.

## Validation

- Test build: `bash scripts/build.sh --tests -w -l 1`.
- All 37 tests passed on a fresh simulator session, including sleep/wake,
  settings/cache invalidation, weather layout, solar rounding, DST and midnight.
- All six final paired benchmark runs passed.
- Release build: `bash scripts/build.sh -r -w -l 1`.
- Timing logs and before/after binaries are local, ignored artifacts under
  `work/power-audit-2026-11-01/`.

The watch-face lifecycle and reason for retaining full-screen restoration follow
[Garmin's WatchFace documentation](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html).
