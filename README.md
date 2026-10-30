# Garmin Face — Forerunner 955

A Connect IQ watch face for **Garmin Forerunner 955 / Solar (`fr955`)**, written
in Monkey C. Designed for the 260 × 260 MIP display; requires Connect IQ API 4.2.2
or later. Includes English and Polish translations.

## Features

- 24-hour time with digital seconds or an orbiting dot. Seconds appear only while
  the face is awake and disappear in low-power mode.
- Date, weather in °C, alarm status and phone connection status.
- Three configurable fields: steps, calories, stress, heart rate, battery,
  daily distance in kilometres or floors climbed. Fields can be repeated or hidden.
- Progress arcs for daily steps, weekly intensity minutes and the current day
  or night. Solar labels show sunrise/sunset and their change from the previous day.
- Accent colours, a light background and a simple view that hides the arcs
  and solar labels.

Weather uses Garmin's cached data. Solar times use the last available location;
missing values appear as `--` or `--:--`. The face does not start GPS or a separate
heart-rate sensor session, make network requests or run a background service.
In low-power mode, the display updates once per minute.

## Customize

On the watch, hold **UP/MENU → Watch Face → Garmin Face → START → Customize**.
Choose the three fields, accent colour, light background, simple view and seconds
style. Select **None** to hide a field; remaining fields centre automatically.
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

## Deploy to the watch

Use **libmtp only**, through terminal tools or the library API. Do not use OpenMTP
or a graphical transfer application. Connect the watch with a USB data cable and
release the USB connection from other MTP clients, such as Garmin Express.

```sh
# Install once on macOS
brew install libmtp

# Detect the watch and inspect its folders
mtp-detect
mtp-folders
```

When asked to deploy:

1. Review the changes to release. Preserve unrelated local changes and exclude
   them from both the release build and commit.
2. Increment the patch version in `manifest.xml`, unless another version was requested.
3. Build with `bash scripts/build.sh -r -w -l 1` and run the relevant checks.
   Stop if the build or checks fail.
4. Commit the release changes and version bump. Deployment alone does not include
   pushing commits or creating tags.
5. Upload the requested `.prg`, defaulting to the freshly built
   `bin/GarminFace.prg`, to `GARMIN/Apps`. Verify it targets FR955. Never upload
   `GarminFaceTests.prg`.
6. Download the uploaded file and compare its SHA-256 with the local release.
   Report the version, commit, destination and verification result.

The verified transfer method uses `LIBMTP_Open_Raw_Device_Uncached` and discovers
the current storage ID and the `Apps` folder ID under `GARMIN`; never hard-code
these IDs. Use `LIBMTP_Send_File_From_File` with the target filename, size,
`storage_id` and `parent_id`. Keep the returned `item_id` and use
`LIBMTP_Get_File_To_File` for verification. Release the device with
`LIBMTP_Release_Device` when finished.

Do not treat `mtp-sendfile` exit code `0` as proof of success: the message
`Parent folder could not be found, skipping` means no file was transferred.
The direct library method and matching SHA-256 were verified on a physical FR955 Solar.

Disconnect the watch and select **Garmin Face**. Confirm operation on the watch;
simulator tests do not establish real battery life or hardware behaviour.

Further details: [power audit](docs/power-audit.md) and
[Garmin icon sources](resources/drawables/garmin/SOURCES.md).
