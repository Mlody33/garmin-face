# Garmin Face — Forerunner 955

A Connect IQ watch face for **Garmin Forerunner 955 / Solar (`fr955`)**, written
in Monkey C. Designed for the 260 × 260 MIP display; requires Connect IQ API 4.2.2
or later. Includes English and Polish translations.

## Features

- 24-hour time with digital seconds. Seconds appear only while
  the face is awake and disappear in low-power mode.
- Date, current temperature in °C (e.g. `8°`), weather conditions,
  alarm status and phone connection status.
- Three configurable fields: steps, calories, stress, heart rate, battery,
  daily distance in kilometres or floors climbed. Fields can be repeated or hidden.
  In low-power mode, fields check for new cached readings every three seconds;
  only changed values are repainted. Measurement frequency remains controlled by Garmin.
- Progress arcs for daily steps, weekly intensity minutes and the current day
  or night. After sunset, the top arc tracks the night until the next sunrise.
  A centered solar label shows the next sunrise or sunset, with its change in
  minutes from the previous day's matching event.
  Each event time rounds to the nearest minute (30 seconds rounds up), matching the checked native
  Garmin readings. Day-to-day changes compare these displayed times.
  Each bottom goal arc turns green when its target is reached.
  Small rectangles on the arcs mark yesterday's steps and the previous calendar week's intensity
  minutes against the current goals. The arc fills continue to show today and this
  week. Week boundaries follow the watch settings.
  Missing history is left unmarked; a local cache retains completed days because
  Garmin exposes at most seven days of activity history.
- Accent colours, a light background and a simple view that hides the arcs
  and solar labels.

Weather uses Garmin's cached data. Sunrise and sunset come from Garmin's
`Weather.getSunrise/getSunset` API for the last position supplied by the watch
through `Position.getInfo()`. Solar data does not use the weather observation
location. The last valid device position is retained in RAM; before one is
available, solar labels show `--:--`. Other missing values appear as `--`.
Coordinates are kept only in memory; the face does not start GPS or a separate heart-rate sensor session,
make network requests or run a background service.
In low-power mode, the display updates once per minute.
Seconds, metric icons, progress arcs and solar labels are hidden until the face
wakes; metric values remain visible.

## Customize

On the watch, hold **UP/MENU → Watch Face → Garmin Face → START → Customize**.
Choose the three fields, accent colour, light background and simple view.
Select **None** to hide a field; remaining fields centre automatically.
Settings persist across restarts.

Holding a metric field is intended to open its native Garmin view. Touch must be
enabled; these shortcuts still need confirmation on a physical FR955.

## Build and test

Install Java, the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/),
an SDK and the **Forerunner 955 / Solar** device profile. Select the active SDK.
For VS Code, install Garmin's **Monkey C** extension (`garmin.monkey-c`) and run
**Monkey C: Verify Installation**.

Restore your signing key to `.keys/developer_key.der`, or generate a new one:

```sh
bash scripts/generate-key.sh
```

Keep a private backup of the key. Signing keys, build output and local VS Code
settings are excluded from Git. Set **Monkey C: Developer Key Path** in VS Code.

```sh
# Release build → bin/GarminFace.prg
bash scripts/build.sh -r -w -l 1

# Test build → bin/GarminFaceTests.prg
bash scripts/build.sh --tests -w -l 1

# Run tests with the Connect IQ simulator already open
monkeydo bin/GarminFaceTests.prg fr955 -t
```

The build script detects the active SDK or `monkeyc` on `PATH`. Override paths with
`CIQ_SDK_HOME` and `CIQ_DEVELOPER_KEY`. The default optimization is `-O 3p`,
configurable through `CIQ_OPTIMIZATION`.

Use F5 in VS Code to launch the face. In the simulator, **Settings → Trigger App
Settings** opens customization; **Set Position** and **Set Weather** provide test data.

## Install on the watch

When asked to deploy, increment the patch version in `manifest.xml`, compile with
`bash scripts/build.sh -r -w -l 1`, commit the release changes and version bump,
then upload the requested `.prg` (default: freshly built `bin/GarminFace.prg`).
Do not run tests, download the uploaded file, or validate SHA-256 during deployment.
Stop if compilation or transfer fails. See [agent instructions](AGENTS.md) for
the full deployment procedure.

1. Connect the watch with a USB data cable.
2. Transfer `bin/GarminFace.prg` to `GARMIN/Apps` using `libmtp` on macOS
   (`brew install libmtp`). Close other MTP clients before transferring.
3. Disconnect the watch and select **Garmin Face** in the watch-face menu.

Further details: [power audit](docs/power-audit-2026-11-01.md) and
[Garmin icon sources](resources/drawables/garmin/SOURCES.md).
