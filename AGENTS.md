# Agent instructions

## Deployment

When asked to deploy, complete the following workflow:

1. Review the changes to release. Preserve unrelated local changes and exclude
   them from both the release build and commit.
2. Increment the patch version in `manifest.xml`, unless another version was requested.
3. Build with `bash scripts/build.sh -r -w -l 1`. Stop if compilation fails.
   Do not run tests or additional validation as part of deployment.
4. Commit the release changes and version bump. Deployment alone does not include
   pushing commits or creating tags.
5. Upload the requested `.prg`, defaulting to the freshly built
   `bin/GarminFace.prg`, to `GARMIN/Apps`. Verify it targets FR955. Never upload
   `GarminFaceTests.prg`.
6. Report the version, commit, uploaded file and destination. Do not download
   the uploaded file or compare SHA-256 hashes as part of deployment.

Do not report a successful deployment if compilation or transfer fails.
Operation on the physical watch must be confirmed separately; simulator tests
do not establish real battery life or hardware behaviour.

## USB transfer with libmtp

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

The verified transfer method uses `LIBMTP_Open_Raw_Device_Uncached` and discovers
the current storage ID and the `Apps` folder ID under `GARMIN`; never hard-code
these IDs. Use `LIBMTP_Send_File_From_File` with the target filename, size,
`storage_id` and `parent_id`. Check the transfer API result without downloading
the file for verification. Release the device with
`LIBMTP_Release_Device` when finished.

Do not treat `mtp-sendfile` exit code `0` as proof of success: the message
`Parent folder could not be found, skipping` means no file was transferred.
The direct library method and matching SHA-256 were verified on a physical FR955 Solar.
