# litter

<p align="center">
  <img src="apps/ios/Sources/Litter/Resources/brand_logo.png" alt="litter logo" width="180" />
</p>

<p align="center">
  Native iOS client for <a href="https://github.com/openai/codex">Codex</a>. Connect to local or remote servers, manage sessions, and run agentic coding workflows from your phone.
</p>

<p align="center">
  <a href="https://kittylitter.app"><img src="docs/badges/website.svg" alt="kittylitter.app" /></a>
  &nbsp;
  <a href="https://apps.apple.com/us/app/kittylitter/id6759521788"><img src="docs/badges/app-store.svg" alt="App Store" /></a>
</p>

## Screenshots

<p align="center">
  <img src="docs/screenshots/01-hero-iphone-1320x2868.png" alt="Home" width="200" />
  <img src="docs/screenshots/02-remote-iphone-1320x2868.png" alt="Remote servers" width="200" />
  <img src="docs/screenshots/07-generative-ui-iphone-1320x2868.png" alt="Generative UI" width="200" />
  <img src="docs/screenshots/05-realtime-voice-iphone-1320x2868.png" alt="Realtime voice" width="200" />
</p>

## Quick Start

```bash
make ios-device-fast
make ios-sim-fast
```

For device builds, a practical low-disk command is:

```bash
CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' make ios-build-device-fast
```

See [AGENTS.md](AGENTS.md) for the canonical repository layout, architecture, and build workflow details.

## Repository Layout

```text
apps/ios/                  iOS app (project.yml is the source of truth)
shared/rust-bridge/        Shared Rust mobile runtime + UniFFI surface
shared/third_party/codex/  Upstream Codex submodule
patches/codex/             Local patch set applied during builds
tools/scripts/             iOS and shared helper scripts
```

## Make Targets

| Target | Description |
|---|---|
| `make ios-device-fast` | Fast iOS device build using the raw staticlib lane |
| `make ios-sim-fast` | Fast iOS simulator build |
| `make ios` | Full package lane (device + simulator + xcframework) |
| `make rust-check` | Host `cargo check` for shared Rust crates |
| `make rust-test` | Host `cargo test` for shared Rust crates |
| `make bindings` | Regenerate UniFFI Swift bindings |
| `make xcgen` | Regenerate Xcode project from `project.yml` |
| `make clean` | Remove build artifacts |
