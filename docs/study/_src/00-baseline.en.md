# Baseline — where this codebase actually stands

Before studying anything, an honest inventory. This matters because roughly a third of the WWDC22→25 surface is *already* in this project, and re-teaching it from zero would waste your time. What follows separates three things: what you already use well, what you use the old way, and what is simply absent.

Every reference below was read at the time of writing. Line numbers drift as you do the exercises — treat them as pointers, not addresses.

---

## The shape of the repo

Two artifacts, no workspace:

- **`Pokespeare/`** — an SPM package, the SDK. `swift-tools-version: 6.0`, `platforms: [.iOS(.v17)]`, zero external dependencies.
- **`Demo/PokeApp.xcodeproj`** — the demo app, consuming the package as a local path reference. `SWIFT_VERSION = 6.0`, `IPHONEOS_DEPLOYMENT_TARGET = 18.1`.

Both compile in **Swift 6 language mode**. That is a genuinely good starting position — most codebases you will meet in the wild are still in mode 5.

Roughly 1,600 lines of production Swift, 1,300 lines of tests, 71 tests total, all passing, SwiftLint clean, CI on GitHub Actions.

---

## Already used well — deepen, don't re-teach

| Feature | Year | Where |
|---|---|---|
| Swift 6 language mode | WWDC24 | `Package.swift:1`, pbxproj `SWIFT_VERSION = 6.0` |
| `Sendable` / `@Sendable` discipline | WWDC22 | `Pokespeare.swift:3-5`, `APIClient.swift:9,12`, `RetryPolicy.swift:4`, `Session.swift:3` |
| `@MainActor` isolation | WWDC21/22 | `SearchViewModel.swift:5` |
| `async let` structured concurrency | WWDC21 | `SearchViewModel.swift:172-173` — two independent PokeAPI calls in parallel |
| Task cancellation, done properly | WWDC21 | `SearchViewModel.swift:150,155,164,181,186` + the `isCancellation` unwrapper at `:286-304` |
| `Clock` / `Duration` | WWDC22 | `RetryPolicy.swift:9,42`, `APIClient.swift:40` |
| `if` / `switch` expressions | WWDC23 | `RetryPolicy.swift:30`, `Error.swift:41,110`, `APIClient.swift:99` |
| Observation (`@Observable`) | WWDC23 | `SearchViewModel.swift:6`, held in `@State` at `SearchView.swift:6` |
| `NavigationStack` | WWDC22 | `SearchView.swift:14` |
| Presentation detents | WWDC22 | `SearchView.swift:24-25` |
| Two-parameter `onChange` | WWDC23 | `SearchView.swift:64,67` |
| iOS 17 shape statics & animations | WWDC23 | `.capsule` `SearchView.swift:77`, `.rect` `:161`, `.push` transition `:84-89`, `.smooth` in `TextField+ViewModifier.swift:23` |
| `@ScaledMetric` | — | `PokemonView.swift:7` — sprite scales with Dynamic Type |
| Phase-based `AsyncImage` | — | `PokemonView.swift:37-48`, with `@unknown default` |
| `#Preview` macro | WWDC23 | `SearchView.swift:167`, `PokemonView.swift:64` |
| SwiftData `@Model` | WWDC23 | `Pokemon.swift:4-10`, container built by hand at `PokeApp.swift:27-47` |
| String Catalogs (`.xcstrings`) | WWDC23 | Both targets, en + it, via `String(localized:bundle:)` |
| Swift Testing, exclusively | WWDC24 | 71 tests, zero XCTest. `@Test`, `@Suite`, `#expect`, `#require`, `@Tag`, `.serialized`, `.disabled(if:)`, parameterized arguments |
| Xcode 16 folder-synced groups | WWDC24 | pbxproj `PBXFileSystemSynchronizedRootGroup` |

There is also real architectural quality here worth noticing, because several exercises will build on it: the SDK is a **struct of closures** (`Pokespeare.swift:3-5`) rather than a protocol, which makes substitution free in tests; the transport is a **single generic `APIClient`** parameterised by a `StatusCodeMapper` closure (`APIClient.swift:12`) instead of duplicated per manager; and the error model has **exactly one mapping boundary** (`Error.swift:109-124`) whose case ordering is load-bearing.

---

## Used the old way — the refactor surface

These work, but a WWDC22→25 API does the job better. Each becomes an exercise.

**Navigation is sheet-and-alert only.** `NavigationStack` is present at `SearchView.swift:14` but there is not a single `navigationDestination`, `NavigationLink`, or `NavigationPath` in the project. The detail view is a `.sheet(item:)` at `:17`, and both alerts are boolean-driven at `:27` and `:36`. → *Batch 1: type-safe routing.*

**Bindings go through `@State` dynamic member lookup.** `SearchView.swift:6` holds the `@Observable` view model in `@State` and reaches bindings as `$viewModel.searchText`. `@Bindable` is never used, and neither is `@Environment` — the view model is passed by initializer at `PokeApp.swift:17`. → *Batch 2.*

**The empty state is a `Spacer()`.** `SearchView.swift:126`. `ContentUnavailableView` (iOS 17) exists precisely for this, and would also give the error path a real presentation instead of an alert. → *Batch 2.*

**Localized strings are pre-resolved `String` constants.** `SearchViewModel.swift:40-56` resolves every string at init with `String(localized:)`, then views render them via `Text(String)`. That freezes the locale at construction time and gives up the catalog's runtime capabilities. `LocalizedStringResource` is the modern answer. → *Batch 2.*

**SwiftData is driven imperatively.** `FetchDescriptor` built by hand at `SearchViewModel.swift:256`, history filtered in memory with `first(where:)` at `:143`. No `@Query`, no `#Predicate`, no `#Index`. And there is no `VersionedSchema`/`MigrationPlan` — `PokeApp.swift:27-47` deletes and rebuilds the store when it cannot be opened, with a `fatalError` if that also fails. → *Batches 2 and 3.*

**Errors are untyped.** The three-layer model (`APIError` → manager errors → `Pokespeare.Error`) is well designed but every function is a bare `throws`. This is the textbook case for typed throws (SE-0413): `APIClient.perform` can only ever throw `APIError`, and the compiler could enforce that. → *Batch 3.*

**Validation is a magic number.** `SearchViewModel.swift:88` — `searchText.count > 2` doubles as both button visibility and input validation, and `:233-236` filters characters with a `filter` closure. This is what `Regex` was introduced for. (Recorded as audit finding C-20.) → *Batch 1.*

**The retry loop is a hand-rolled `while true`.** `APIClient.swift:35-44`. It works, and the backoff at `RetryPolicy.swift:42` is clean. But there is no `withTaskCancellationHandler`, and nothing in the project uses `AsyncStream`, `AsyncSequence`, or `TaskGroup`. → *Batch 3.*

**`Package.swift` has no `swiftSettings` at all.** No upcoming-feature flags, no explicit language mode, no `defaultIsolation`. Swift 6 mode comes purely from the tools version. → *Batches 3 and 4.*

---

## Absent entirely

Nothing in this project uses: macros you wrote yourself · typed throws · `Synchronization` (`Mutex`, `Atomic`) · `sending` or region-based isolation you had to reason about · actors in production code (only in tests) · `@concurrent` / `nonisolated(nonsending)` / default actor isolation · `Span` / `InlineArray` · `Observations` · `@Entry` / `@Previewable` · `.task` / `.searchable` / `.refreshable` · custom `Layout` / `Grid` / `ViewThatFits` · `PhaseAnimator` / `KeyframeAnimator` / `symbolEffect` · the scroll API family · `MeshGradient` / `TextRenderer` / `onGeometryChange` · Swift Charts · WidgetKit · App Intents · Liquid Glass · Foundation Models.

That list is the curriculum.

---

## The one that makes the capstone worth doing

The app is called **PokéSpeare**. Its entire premise is Shakespearean Pokémon descriptions, via the FunTranslations API.

That endpoint no longer exists. So `Pokespeare.swift:45-49` ships with `isTranslationEnabled: Bool = false`, and `description(for:)` returns raw PokéAPI flavor text. The app currently does not do the thing it is named after.

**Foundation Models** (WWDC25) can do that translation on-device, offline, free, with no API key and no rate limit. That is the Batch 4 capstone — not an exercise invented to practise a framework, but the framework that happens to fix the project's central defect.

---

## Deployment-target strategy

Current state:

| Artifact | Setting | Value |
|---|---|---|
| Package | `Package.swift:9` | `.iOS(.v17)` |
| App | pbxproj `IPHONEOS_DEPLOYMENT_TARGET` | `18.1` (4 occurrences: lines 264, 321, 395, 414) |

Both are compiled by Xcode 26.4.1 against the **iOS 26.4 SDK**.

### Staged bumps

Rather than one jump, the target rises when the curriculum needs it. This is deliberate: each bump is an occasion to practise `@available` on real code, which is the skill you actually need at work.

| When | Change | Why |
|---|---|---|
| **Now — Batch 0** | App `18.1` → **`26.0`** | Unlocks every app-side WWDC24/25 API immediately. The app is the experimentation surface. |
| **Batch 3** | Package `.v17` → **`.v18`** | Needed for SwiftData `#Index`/`#Unique` and the iOS 18 SwiftUI APIs in `PokemonView`. |
| **Batch 4** | Package `.v18` → **`.v26`** | Needed for `glassEffect` inside the shared `PokemonView`, and for Foundation Models. |

The package deliberately lags the app. An SDK that demands the newest OS is a bad SDK, and keeping it behind forces you to write the availability guards properly instead of raising the floor every time something is inconvenient.

### Something already true that you should know

Liquid Glass adoption is driven by **the SDK you build against**, not by your deployment target. Because this project is already built with Xcode 26 against the iOS 26 SDK, the app **already renders with Liquid Glass** on iOS 26 devices today — before any bump, and before you write a line of `glassEffect`.

The temporary opt-out is the `UIDesignRequiresCompatibility` Info.plist key. This project sets `GENERATE_INFOPLIST_FILE = YES` and has no Info.plist file, so it would have to go in as an `INFOPLIST_KEY_UIDesignRequiresCompatibility` build setting. Apple describes the key as a short-term migration aid that will stop working in a future release, so treat it as a debugging tool, not a strategy.

*Sourcing note: the key's existence and behaviour are documented across Apple Developer Forums threads and widely-corroborated third-party write-ups, but I was not able to read Apple's own documentation page for it directly — Apple's docs are JavaScript-rendered and not machine-readable. Verify against the Xcode 26 release notes before relying on it. This is flagged rather than presented as settled.*

### Exercise 0 — raise the app target

**Task.** Set the app's deployment target to iOS 26.0, for all four build configurations of both the `PokeApp` and `PokeAppTests` targets.

**Acceptance criteria.**

1. `grep -c "IPHONEOS_DEPLOYMENT_TARGET = 26" Demo/PokeApp.xcodeproj/project.pbxproj` returns `4`.
2. Both test suites pass on an iOS 26 simulator:

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

3. The package still builds untouched at `.iOS(.v17)` — you are not bumping it yet:

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

4. `swiftlint lint --strict` stays clean.

**Two things to check while you are in there.**

- **`knownRegions`** at `project.pbxproj:149` lists only `(en, Base)`, yet `Demo/PokeApp/Resources/Localizable.xcstrings` carries Italian for all 11 keys. Confirm Italian actually ships: run the app on a simulator set to Italian and check the UI, or inspect the built `.app` bundle for an `it.lproj`. If it does not, that is a real localization bug hiding in plain sight.
- **CI** (`.github/workflows/ci.yml`) resolves its simulator by *name* (`PREFERRED_SIMULATOR: iPhone 17 Pro`) without pinning a runtime version. An iPhone 17 Pro only exists on iOS 26+, so the bump should be safe — but watch the first CI run after you push.

**Pitfall.** Xcode writes the deployment target into every build configuration separately. Changing it on the project does not necessarily change it on each target — check all four occurrences, not just the two the Project editor shows you.
