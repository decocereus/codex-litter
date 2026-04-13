# Development Guide

## Prerequisites

- **Xcode.app** (full install, not only Command Line Tools):

  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

- **Rust via rustup** with iOS targets. If Homebrew's `rust` formula is installed, its `cargo`/`rustc` will shadow rustup and break cross-compilation. Either `brew uninstall rust` or ensure `~/.cargo/bin` appears before `/opt/homebrew/bin` in your `PATH`.

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
  ```

- **meson** + **ninja** (required by `webrtc-audio-processing-sys`):

  ```bash
  brew install meson ninja
  ```

- **xcodegen** (for regenerating `Litter.xcodeproj`):

  ```bash
  brew install xcodegen
  ```

## Connect Your Mac to Litter Over SSH

Use this flow to make Codex sessions from your Mac visible in the iOS app.

1. Enable SSH on the Mac.

   - UI: `System Settings` -> `General` -> `Sharing` -> enable `Remote Login`.
   - CLI:
     ```bash
     sudo systemsetup -setremotelogin on
     ```
   - If you get a Full Disk Access error, grant it to your terminal app in `System Settings` -> `Privacy & Security` -> `Full Disk Access`, then restart terminal and retry.

2. Verify SSH and Codex binaries from a non-interactive SSH shell.

   ```bash
   ssh <mac-user>@<mac-host-or-ip> 'echo ok'
   ssh <mac-user>@<mac-host-or-ip> 'command -v codex || command -v codex-app-server'
   ```

   If the second command prints nothing, install Codex and/or fix shell PATH startup files.

3. Connect from the Litter app.

   - Keep phone and Mac on the same LAN (or same Tailnet).
   - In Discovery: tap a host showing `codex running` to connect directly, or tap an `SSH` host and enter credentials.

4. Fallback: run app-server manually on Mac and add server manually in app.

   ```bash
   codex app-server --listen ws://0.0.0.0:8390
   ```

   Then in app choose `Add Server` and enter `<mac-ip>` + `8390`.

5. Thread/session listing is `cwd`-scoped. If expected sessions are missing, choose the same working directory used when those sessions were created.

## Codex Submodule + Patches

Upstream Codex is vendored as a submodule at `shared/third_party/codex`.

Current local patch set (applied by `sync-codex.sh`):

- `patches/codex/ios-exec-hook.patch`
- `patches/codex/client-controlled-handoff.patch`
- `patches/codex/mobile-code-mode-stub.patch`

Additional patches (not auto-applied):

- `patches/codex/realtime-transcript-deltas.patch`

Sync/apply (idempotent):

```bash
./apps/ios/scripts/sync-codex.sh
```

Pass `--recorded-gitlink` to reset the submodule to the commit recorded in the superproject.

## Build the Rust Bridge

```bash
./apps/ios/scripts/build-rust.sh              # package mode (device + sim + xcframework)
./apps/ios/scripts/build-rust.sh --fast-device # raw device staticlib only
```

## Build and Run iOS

For a fresh local machine, start with:

```bash
make ios-local-setup
```

That helper:
- chooses a local `com.<identifier>.litter` bundle/app-group namespace
- auto-detects the first Apple Development team in your keychain unless you override it
- regenerates `apps/ios/Litter.xcodeproj`
- downloads `ios_system` frameworks by default

Override the defaults if needed:

```bash
IOS_LOCAL_IDENTIFIER=myname IOS_LOCAL_TEAM_ID=TEAMID1234 make ios-local-setup
```

Regenerate project if `apps/ios/project.yml` changed:

```bash
make xcgen
```

Open in Xcode:

```bash
open apps/ios/Litter.xcodeproj
```

CLI build:

```bash
xcodebuild -project apps/ios/Litter.xcodeproj -scheme Litter -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Fast Local iOS Build

For the smallest local footprint on a laptop with limited disk space:

```bash
CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' make ios-device-fast
```

## TestFlight (iOS)

1. Authenticate with App Store Connect:

   ```bash
   asc auth login \
     --name "Litter ASC" \
     --key-id "<KEY_ID>" \
     --issuer-id "<ISSUER_ID>" \
     --private-key "$HOME/AppStore.p8" \
     --network
   ```

2. Bootstrap TestFlight defaults:

   ```bash
   APP_BUNDLE_ID=<BUNDLE_ID> ./apps/ios/scripts/testflight-setup.sh
   ```

3. Build and upload:

   ```bash
   APP_BUNDLE_ID=<BUNDLE_ID> \
   APP_STORE_APP_ID=<APP_STORE_CONNECT_APP_ID> \
   TEAM_ID=<APPLE_TEAM_ID> \
   ASC_KEY_ID=<KEY_ID> \
   ASC_ISSUER_ID=<ISSUER_ID> \
   ASC_PRIVATE_KEY_PATH="$HOME/AppStore.p8" \
   ./apps/ios/scripts/testflight-upload.sh
   ```

   - Reads `MARKETING_VERSION` from `apps/ios/project.yml`; auto-bumps patch if the version is already live.
   - Auto-increments build number from the latest App Store Connect build.

## App Store Release (iOS)

```bash
APP_BUNDLE_ID=<BUNDLE_ID> \
APP_STORE_APP_ID=<APP_STORE_CONNECT_APP_ID> \
TEAM_ID=<APPLE_TEAM_ID> \
ASC_KEY_ID=<KEY_ID> \
ASC_ISSUER_ID=<ISSUER_ID> \
ASC_PRIVATE_KEY_PATH="$HOME/AppStore.p8" \
./apps/ios/scripts/app-store-release.sh
```

Metadata is sourced from `apps/ios/fastlane/metadata/en-US/`.
