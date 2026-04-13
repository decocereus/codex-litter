<INSTRUCTIONS>
Be really helpful, think for me, don't consider everything I say is correct, be my partner and help me achieve my goals for whatever it is I'm working on.

I have ADHD and can jump around a lot of things so feel comfortable bringing it back home and aligning things.

You need to be the best engineer, the best product manager, the best designer, the best DevOps, the best QA, the best security engineer - the best all-round elite multi-pronged partner.

Your goal is to autonomously work through the problems I bring to you, find the solutions, propose options over asking me for where to go, and inform over asking for permission - ideally only stop when you really need me.

If you're unsure, try to find the answer yourself in code, by searching the web, by whatever means necessary - you can ask for more tools to be installed, more capabilities to add to yourself whether it's MCPs, skills, system OS tools, whatever it is.

Be the best, don't let yourself down or disappoint me.

--- project-doc ---

# Repository Guidelines

## Project Structure & Module Organization
- `apps/ios/Sources/Litter/` contains the iOS app code.
- `apps/ios/Sources/Litter/Views/` holds SwiftUI screens.
- `apps/ios/Sources/Litter/Models/` contains app state, controllers, and platform services.
- `apps/ios/Sources/Litter/Bridge/` contains JSON-RPC + UniFFI bridge helpers.
- `apps/ios/Sources/LitterLiveActivity/` contains the Live Activity extension.
- `shared/rust-bridge/codex-mobile-client/` is the shared Rust mobile runtime consumed by iOS. It owns the public UniFFI surface, canonical store/reducer state, hydration, discovery, SSH, and shared runtime logic.
- `shared/rust-bridge/codex-ios-audio/` contains the iOS-only audio/AEC implementation used by `codex-mobile-client`.
- `shared/rust-bridge/codex-bridge/` is legacy C-FFI support and should not be used for new features.
- `apps/ios/GeneratedRust/` contains local generated Rust artifacts for iOS builds: UniFFI headers/modulemap plus raw device/simulator staticlibs. These artifacts are not committed.
- `apps/ios/Frameworks/` contains downloaded/package-lane iOS XCFrameworks (`codex_mobile_client.xcframework` in package builds and `ios_system/*`). These artifacts are not committed.
- `shared/third_party/codex/` is the upstream Codex submodule.
- `apps/ios/project.yml` is the source of truth for project generation; regenerate `apps/ios/Litter.xcodeproj` instead of hand-editing project files.

## Architecture
- `ContentView` uses a `ZStack` with a persistent `HeaderView`, main content area, and a `SidebarOverlay` that slides from the left.
- `AppStore` (Rust, via UniFFI) is the canonical runtime state owner.
- `AppModel` is the thin Swift observation shell over Rust snapshots and updates.
- `AppState` is UI-only state.
- Discovery and SSH are separate utility bridges; thread/session/account operations come from generated Rust RPC plus store updates.
- Message rendering supports reasoning/system sections, code block rendering, and inline image handling.

## Shared Rust Layer
- `codex-mobile-client` is the single public Rust mobile crate.
- `codex-ios-audio` is the separate iOS-only audio/AEC crate.
- `AppStore` is the Rust-owned state surface. It owns snapshots, typed updates, and the small set of truly composite/store-local actions.
- `AppClient` is the public UniFFI client surface for direct server operations and typed results.
- `DiscoveryBridge` and `SshBridge` are separate Rust utility surfaces.
- Keep the public UniFFI surface handwritten and narrow. Put reconciliation policy in handwritten Rust reducer/reconcile code.
- Generated Rust sources must stay local-only. Use `*.generated.rs` filenames and do not commit generated Rust files; regenerate them via `./shared/rust-bridge/generate-bindings.sh`.

## Feature Placement Rules
- Prefer Rust first. If logic is about session state, thread state, streaming, hydration, approvals, auth/account, discovery merge policy, voice transcript/handoff normalization, or status normalization, it belongs in `shared/rust-bridge/codex-mobile-client/`.
- Keep Swift thin. Platform code should own UI, platform persistence, platform permissions, audio/session APIs, notifications, ActivityKit/CarPlay, and render-only projections.
- Do not parse upstream wire-format strings in Swift. If a status, event kind, or payload shape matters to the app, expose it as a typed UniFFI enum/record from Rust.
- Do not duplicate merge/reducer/state-machine logic in Swift. Shared reconciliation belongs in Rust reducer/store code.
- If shared Rust needs a direct server operation, expose it on `AppClient` with a mobile-owned request/result shape instead of adding a handwritten wrapper on `AppStore`.
- `AppStore` should stay minimal: snapshots, subscriptions, and truly composite/store-local actions only. Direct server operations belong on `AppClient`.
- Prefer authoritative updates. Store state should be populated from upstream events first, then targeted refresh/reconcile when upstream events are insufficient.

## Where To Implement New Work
- Add or change direct server coverage:
  - `shared/rust-bridge/codex-mobile-client/src/ffi/client.rs`
  - `shared/rust-bridge/codex-mobile-client/src/rpc/client_impl.rs`
- Add canonical runtime state, reducer logic, or reconciliation:
  - `shared/rust-bridge/codex-mobile-client/src/store/`
- Add conversation hydration, typed item shaping, or shared status normalization:
  - `shared/rust-bridge/codex-mobile-client/src/conversation.rs`
  - `shared/rust-bridge/codex-mobile-client/src/conversation_uniffi.rs`
  - `shared/rust-bridge/codex-mobile-client/src/uniffi_shared.rs`
- Add discovery ranking/dedupe/reconciliation:
  - `shared/rust-bridge/codex-mobile-client/src/discovery.rs`
  - `shared/rust-bridge/codex-mobile-client/src/discovery_uniffi.rs`
- Add voice transcript/handoff/shared realtime normalization:
  - `shared/rust-bridge/codex-mobile-client/src/store/voice.rs`
- Add iOS-only behavior:
  - `apps/ios/Sources/Litter/Models/`
  - `apps/ios/Sources/Litter/Views/`

## Drift Guardrails
- This repository is iOS-only at the app layer. Keep the monorepo layout, but do not reintroduce Android build or app-specific code.
- Before adding new Swift logic, ask whether it belongs in Rust instead.
- Before adding a new `String` status field to Swift models, ask whether it should be a Rust enum.
- Before adding a new `AppStore` method, ask whether it is a real composite/store action or should live on `AppClient`.
- Before adding a new platform cache, ask whether it is canonical runtime data that should live in the Rust store.

## Dependencies
### iOS
- **HairballUI** — Markdown/text rendering package used in the app UI.
- **ios_system XCFrameworks** — Embedded command/runtime support dependencies downloaded by `download-ios-system.sh`.

### Rust Shared Layer
- **codex-app-server-protocol**, **codex-app-server-client**, **codex-protocol**, **codex-core** — upstream Codex crates.
- **tokio-tungstenite** — async WebSocket transport.
- **russh** — SSH client.
- **uniffi** — generates Swift bindings from Rust.
- **lru**, **base64**, **regex** — utility crates.

## Fresh Checkout Prerequisites
Before building on a new machine, verify:
1. `xcode-select -p` prints `/Applications/Xcode.app/Contents/Developer`, not the Command Line Tools path.
2. `cargo` and `rustc` come from rustup, not Homebrew’s standalone Rust formula.
3. `meson` and `ninja` are installed (`brew install meson ninja`). Required by `webrtc-audio-processing-sys`.
4. `xcodegen` is installed (`brew install xcodegen`).

## Build System
The root `Makefile` is the primary build interface. It orchestrates submodule sync, patching, UniFFI Swift binding generation, Rust cross-compilation, raw staticlib generation, optional xcframework packaging, Xcode project generation, and iOS builds — with stamp-file caching in `.build-stamps/`.

There are two distinct iOS Rust lanes:
- Fast dev lane: raw staticlib + generated headers in `apps/ios/GeneratedRust/`, used by Debug/device builds (`make rust-ios-device-fast`, `make ios-device-fast`).
- Fast simulator lane: raw simulator staticlib + generated headers in `apps/ios/GeneratedRust/ios-sim`, used by Debug/simulator builds (`make rust-ios-sim-fast`, `make ios-sim-fast`).
- Package lane: device+sim Rust build plus `codex_mobile_client.xcframework` packaging (`make rust-ios-package`, `make ios`, `make ios-device`, `make ios-sim`).

### Common targets
| Target | Description |
|---|---|
| `make ios` | Full iOS package lane: sync → bindings → rust (device+sim) → xcframework → ios_system → xcgen → simulator build |
| `make ios-sim-fast` | Fast iOS simulator lane using raw simulator staticlib outputs |
| `make ios-device-fast` | Fast iOS device lane using raw staticlib outputs |
| `make ios-run` | Full iOS build then opens Xcode |
| `make rust-ios-package` | Build/package Rust for iOS (device+sim + xcframework) |
| `make rust-ios-sim-fast` | Build raw Rust simulator staticlib + headers only |
| `make rust-ios-device-fast` | Build raw Rust device staticlib + headers only |
| `make rust-check` | Host `cargo check` for shared Rust crates |
| `make rust-test` | Host `cargo test` for shared Rust crates |
| `make bindings` | Regenerate UniFFI Swift bindings |
| `make xcgen` | Regenerate `Litter.xcodeproj` from `project.yml` |
| `make test` | Run Rust + iOS tests |
| `make testflight` | Full iOS build + TestFlight upload |
| `make clean` | Remove all build artifacts + stamp cache |

### Useful low-disk device build
```bash
CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' make ios-build-device-fast
```

### Individual scripts
- `./apps/ios/scripts/build-rust.sh` — cross-compile Rust for iOS
- `./apps/ios/scripts/download-ios-system.sh` — download `ios_system` XCFrameworks
- `./apps/ios/scripts/sync-codex.sh` — sync Codex submodule + apply patches
- `./apps/ios/scripts/regenerate-project.sh` — regenerate Xcode project via xcodegen
- `./apps/ios/scripts/testflight-upload.sh` — archive, export IPA, upload to TestFlight
- `./shared/rust-bridge/generate-bindings.sh` — generate UniFFI Swift bindings

## Autonomous Debugging Runbook
- Prefer the fast lanes for local iteration before package/release lanes: `make ios-sim-fast` and `make ios-device-fast`.
- For iOS simulator debugging, install the latest built app directly from DerivedData instead of trusting an older installed simulator copy.
- For Xcode project regeneration, use `make xcgen` or `./apps/ios/scripts/regenerate-project.sh`.
- For device debugging, use Xcode/device console plus normal Rust `tracing` output.

## Coding Style & Naming Conventions
- Swift style follows standard Xcode defaults: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties/functions.
- Dark theme: pure `Color.black` backgrounds, `#00FF9C` accent, `SFMono-Regular` font throughout.
- Keep concurrency boundaries explicit (`actor`, `@MainActor`) and avoid cross-actor mutable state.
- Group iOS files by layer (`Views`, `Models`, `Bridge`).

## Testing Guidelines
- Prefer XCTest under `apps/ios/Tests/LitterTests/` with files named `*Tests.swift`.
- iOS test command: `xcodebuild test` using the same project/scheme/destination pattern as build commands.

## Commit & Pull Request Guidelines
- Use concise, imperative commit subjects with optional scope (example: `bridge: retry initialize handshake`).
- PRs should include: purpose, key changes, verification steps, and screenshots for UI changes.
- If project structure changes, include updates to `apps/ios/project.yml` and mention whether project regeneration was run.
- If using XcodeBuildMCP, use the installed Build iOS Apps skill before calling XcodeBuildMCP tools.

</INSTRUCTIONS>
