# Version Map — WWDC year ↔ Swift ↔ Xcode ↔ OS

The lookup table for "when can I use this, and what do I have to guard?"

**Sourcing note.** The Swift-version-per-proposal data below comes from the [official Swift Evolution dashboard](https://download.swift.org/swift-evolution/v1/evolution.json) (`implementationVersions` + per-proposal `status.version`), snapshot of 2026-07-28. It is authoritative: it is generated from the swift-evolution repository itself. The Swift↔Xcode column has no single official table published by Apple; the row for this machine was measured directly (`xcodebuild -version` → Xcode 26.4.1, `swift --version` → Swift 6.3.1), and the rest comes from Apple's Xcode release notes.

---

## The master table

| WWDC | Swift | Xcode | iOS | Shipped | Language headline |
|---|---|---|---|---|---|
| **2022** | **5.7** | 14 | **16** | Sept 2022 | Existentials & generics finally usable; Regex; `Clock`/`Duration` |
| — | 5.8 | 14.3 | — | Mar 2023 | Consolidation release |
| **2023** | **5.9** | 15 | **17** | Sept 2023 | **Macros**; Observation; ownership; parameter packs |
| — | 5.10 | 15.3 | — | Mar 2024 | Full data isolation under `-strict-concurrency=complete` |
| **2024** | **6.0** | 16 | **18** | Sept 2024 | **Swift 6 language mode**; typed throws; region-based isolation; `Synchronization` |
| — | 6.1 | 16.3 | — | Mar 2025 | Trailing-comma support, package traits |
| **2025** | **6.2** | 26 | **26** | Sept 2025 | **Approachable concurrency**; `Span`; `InlineArray`; `Observations` |
| — | 6.3 | 26.4 | 26.4 | 2026 | Current toolchain here. After WWDC25 — appendix only |

**On the version jump:** iOS went 18 → 26 and Xcode 16 → 26 because Apple unified all OS and tooling version numbers onto a year-based scheme in September 2025. There is no iOS 19–25. Xcode 26 is the September 2025 through September 2026 release window.

**The three numbers that are independent.** Keep these apart — conflating them is the most common source of confusion:

- **Swift language mode** (`swiftLanguageMode` / `SWIFT_VERSION`) — which *dialect* the compiler enforces. `6` turns on complete data-race safety as errors.
- **Swift toolchain version** — which compiler binary you have. Swift 6.3.1 here. A 6.3 toolchain can still compile in language mode 5.
- **Deployment target** (`platforms:` / `IPHONEOS_DEPLOYMENT_TARGET`) — which OS the *runtime* APIs must exist on. Independent of both of the above.

You can use a Swift 6.2 language feature while deploying to iOS 17, because language features are compile-time. You cannot use `glassEffect` while deploying to iOS 17 without an `#available` guard, because that is a runtime API.

---

## What each year brought

### WWDC22 · Swift 5.7 · iOS 16

**Language** — 32 proposals. The theme is *generics and existentials becoming usable*, plus string processing.

The generics story: `any` became mandatory spelling for existentials ([SE-0335](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0335-existential-any.md), actually Swift 5.6), then 5.7 removed the restrictions that made existentials painful — [SE-0309](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md) unlocked existentials for protocols with associated types, [SE-0346](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md) added primary associated types (`some Collection<Int>`), [SE-0341](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0341-opaque-parameters.md) allowed `some` in parameter position, and [SE-0352](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0352-implicit-open-existentials.md) let the compiler implicitly open an existential to call a generic function on it.

Also: **Regex** — a five-proposal package ([SE-0350](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0350-regex-type-overview.md) type, [SE-0351](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0351-regex-builder.md) builder DSL, [SE-0354](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0354-regex-literals.md) literals, [SE-0355](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0355-regex-syntax-run-time-construction.md) syntax, [SE-0357](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0357-algorithms-string-processing.md) algorithms). **Clock/Instant/Duration** ([SE-0329](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md)) — already used in this repo at `RetryPolicy.swift:9`. `if let x {` shorthand ([SE-0345](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0345-if-let-shorthand.md)). `Sendable` and `@Sendable` closures ([SE-0302](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)). Distributed actors ([SE-0336](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0336-distributed-actor-isolation.md), [SE-0344](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0344-distributed-actor-runtime.md)).

**Frameworks** — `NavigationStack` / `NavigationSplitView` replacing `NavigationView`; the `Layout` protocol, `Grid`, `ViewThatFits`; presentation detents; `ShareLink` and `Transferable`; **Swift Charts** debut; **App Intents** debut; WidgetKit lock-screen widgets; WeatherKit.

### WWDC23 · Swift 5.9 · iOS 17

**Language** — 23 proposals. The theme is *macros* and *ownership*.

**Macros** are the flagship: [SE-0382](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0382-expression-macros.md) expression macros, [SE-0389](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0389-attached-macros.md) attached macros, [SE-0397](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0397-freestanding-declaration-macros.md) freestanding declaration macros, [SE-0394](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0394-swiftpm-expression-macros.md) SwiftPM support. This repo uses three macros daily without ever seeing inside one: `@Observable`, `@Model`, `#Preview`.

Ownership: [SE-0366](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0366-move-function.md) `consume`, [SE-0377](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md) `borrowing`/`consuming`, [SE-0390](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md) noncopyable types. Generics: [SE-0393](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0393-parameter-packs.md) value and type parameter packs. Also [SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md) `if`/`switch` expressions (used throughout this repo — e.g. `RetryPolicy.swift:30`, `Error.swift:110`), [SE-0395](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0395-observability.md) **Observation**, [SE-0386](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0386-package-access-modifier.md) the `package` access level, [SE-0392](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md) custom actor executors.

**Frameworks** — **SwiftData**; Observation in SwiftUI (`@Observable`, `@Bindable`); `PhaseAnimator` and `KeyframeAnimator`; the scroll API family (`scrollTargetBehavior`, `scrollPosition`, `containerRelativeFrame`, `visualEffect`); `ContentUnavailableView`; `Inspector`; `symbolEffect`; `#Preview`; **String Catalogs**; TipKit; StoreKit views; interactive widgets.

### WWDC24 · Swift 6.0 · iOS 18

**Language** — 33 proposals. The theme is *complete data-race safety*.

Swift 6 language mode makes data-race safety a compile-time guarantee rather than a warning. The supporting cast: [SE-0414](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md) **region-based isolation** (the compiler proves a value is not referenced elsewhere, so it may cross an isolation boundary even if not `Sendable`), [SE-0430](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md) `sending`, [SE-0431](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md) `@isolated(any)`, [SE-0420](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0420-inheritance-of-actor-isolation.md) inheritance of actor isolation, [SE-0423](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md) dynamic isolation enforcement, [SE-0434](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0434-global-actor-isolated-types-usability.md) usability of global-actor-isolated types.

Beyond concurrency: [SE-0413](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md) **typed throws**; [SE-0433](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0433-mutex.md) `Mutex` and [SE-0410](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0410-atomics.md) `Atomic` in the new `Synchronization` module; [SE-0427](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md) noncopyable generics; [SE-0408](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0408-pack-iteration.md) pack iteration; [SE-0435](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0435-swiftpm-per-target-swift-language-version-setting.md) per-target language version; [SE-0425](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0425-int128.md) 128-bit integers.

**Frameworks** — **Swift Testing** debut (this repo already uses it exclusively); `@Entry` and `@Previewable` macros; custom SwiftUI containers; zoom navigation transitions; `MeshGradient`; `TextRenderer`; `onGeometryChange`; the new `Tab` API; SwiftData `#Index`, `#Unique`, custom `DataStore`, history tracking; Control Widgets.

### WWDC25 · Swift 6.2 · iOS 26

**Language** — 32 proposals. The theme is *approachable concurrency* — walking back the parts of Swift 6 that punished code which was never concurrent to begin with.

[SE-0466](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md) **control default actor isolation** — opt a whole module into `@MainActor` by default, so single-threaded UI code stops paying for concurrency it never asked for. [SE-0461](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md) **run nonisolated async functions on the caller's actor by default** — and with it the `@concurrent` attribute, the explicit opt-in to leaving the caller's actor. [SE-0472](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md) starting tasks synchronously. [SE-0470](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md) global-actor-isolated conformances.

Performance and safety: [SE-0447](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0447-span-access-shared-contiguous-storage.md) `Span`, [SE-0453](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0453-vector.md) `InlineArray`, [SE-0446](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0446-non-escapable.md) nonescapable types, [SE-0458](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0458-strict-memory-safety.md) opt-in strict memory safety. Observation: [SE-0475](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md) **transactional observation of values** — the `Observations` async sequence. Tooling: [SE-0486](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0486-adopting-swift-features.md) migration tooling for Swift features, [SE-0480](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0480-warning-control-flags.md) warning control in SwiftPM.

**Frameworks** — **Liquid Glass** (`glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`); **Foundation Models** — the on-device LLM, with `@Generable` guided generation; `WebView`/`WebPage`; the `AttributedString` rich text editor; `@Animatable`; 3D Swift Charts; Swift Testing exit tests and attachments; Icon Composer.

---

## Availability in practice

Language features are compile-time and need no guard. Runtime APIs do. The two forms:

```swift
// Guard an expression.
if #available(iOS 26, *) {
  content.glassEffect()
} else {
  content.background(.regularMaterial)
}

// Guard a whole declaration.
@available(iOS 26, *)
struct GlassCard: View { /* … */ }
```

For view modifiers specifically, the branch above duplicates the view's type on each side. When only the modifier differs, prefer a conditional modifier helper so the view identity stays stable — SwiftUI treats the two branches of an `if` as *different views*, which resets state and breaks animations.

`@available` also carries deprecation and obsolescence, which is what you will meet when reading Apple headers:

```swift
@available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use NavigationStack")
```

See [`00-baseline.md`](00-baseline.md) for this project's staged deployment-target plan.

---

## Full proposal index

Every proposal that shipped in each of the four target versions, from the evolution dashboard. Use this to check whether something you half-remember is real, and which version it landed in.

<details>
<summary><b>Swift 5.7 — 32 proposals (WWDC22)</b></summary>

SE-0292 Package Registry Service · SE-0302 `Sendable` and `@Sendable` closures · SE-0309 Unlock existentials for all protocols · SE-0326 Multi-statement closure type inference · SE-0328 Structural opaque result types · SE-0329 Clock, Instant, and Duration · SE-0333 Expand usability of `withMemoryRebound` · SE-0334 Pointer API usability · SE-0336 Distributed Actor Isolation · SE-0338 Execution of non-actor-isolated async functions · SE-0339 Module aliasing · SE-0340 Unavailable from async · SE-0341 Opaque parameter declarations · SE-0343 Concurrency in top-level code · SE-0344 Distributed Actor Runtime · SE-0345 `if let` shorthand · SE-0346 Lightweight same-type requirements · SE-0347 Type inference from default expressions · SE-0348 `buildPartialBlock` · SE-0349 Unaligned loads and stores · SE-0350 Regex type · SE-0351 Regex builder DSL · SE-0352 Implicitly opened existentials · SE-0353 Constrained existential types · SE-0354 Regex literals · SE-0355 Regex syntax · SE-0356 Swift Snippets · SE-0357 Regex-powered string algorithms · SE-0358 Primary associated types in the stdlib · SE-0360 Opaque result types with limited availability · SE-0361 Extensions on bound generic types · SE-0363 Unicode for string processing

</details>

<details>
<summary><b>Swift 5.9 — 23 proposals (WWDC23)</b></summary>

SE-0366 `consume` operator · SE-0374 `sleep(for:)` on Clock · SE-0377 `borrowing`/`consuming` · SE-0380 `if`/`switch` expressions · SE-0381 DiscardingTaskGroups · SE-0382 Expression Macros · SE-0384 Forward-declared Obj-C interfaces · SE-0386 `package` access modifier · SE-0388 `AsyncStream.makeStream` · SE-0389 Attached Macros · SE-0390 Noncopyable structs and enums · SE-0391 Package Registry Publish · SE-0392 Custom Actor Executors · SE-0393 Value and Type Parameter Packs · SE-0394 SwiftPM custom macros · SE-0395 Observation · SE-0396 `Never: Codable` · SE-0397 Freestanding Declaration Macros · SE-0398 Generic types abstracting over packs · SE-0399 Tuple of value pack expansion · SE-0400 Init accessors · SE-0401 Remove actor isolation inference from property wrappers · SE-0402 `extension` macros

</details>

<details>
<summary><b>Swift 6.0 — 33 proposals (WWDC24)</b></summary>

SE-0220 `count(where:)` · SE-0270 Collection ops on noncontiguous elements · SE-0301 Package editor commands · SE-0364 Retroactive conformance warning · SE-0405 String initializers with encoding validation · SE-0408 Pack iteration · SE-0409 Access-level modifiers on imports · SE-0410 Low-Level Atomic Operations · SE-0413 Typed throws · SE-0414 Region based Isolation · SE-0415 Function Body Macros · SE-0416 Keypath literals as functions · SE-0417 Task Executor Preference · SE-0418 Inferring `Sendable` for methods and key paths · SE-0420 Inheritance of actor isolation · SE-0421 Effect polymorphism for `AsyncSequence` · SE-0422 Expression macro as default argument · SE-0423 Dynamic actor isolation enforcement · SE-0424 Custom isolation checking for SerialExecutor · SE-0425 128-bit Integer Types · SE-0426 BitwiseCopyable · SE-0427 Noncopyable Generics · SE-0428 Resolve DistributedActor protocols · SE-0429 Partial consumption of noncopyable values · SE-0430 `sending` parameters and results · SE-0431 `@isolated(any)` function types · SE-0432 Borrowing/consuming pattern matching · SE-0433 Synchronous Mutual Exclusion Lock · SE-0434 Usability of global-actor-isolated types · SE-0435 Swift language version per target · SE-0437 Noncopyable stdlib primitives · SE-0440 DebugDescription macro

</details>

<details>
<summary><b>Swift 6.2 — 32 proposals (WWDC25)</b></summary>

SE-0371 Isolated synchronous deinit · SE-0419 Swift Backtrace API · SE-0446 Nonescapable Types · SE-0447 Span · SE-0451 Raw identifiers · SE-0452 Integer Generic Parameters · SE-0453 InlineArray · SE-0456 `Span`-providing properties · SE-0457 Attosecond representation of `Duration` · SE-0458 Opt-in Strict Memory Safety · SE-0459 `Collection` conformance for `enumerated()` · SE-0461 Nonisolated async on caller's actor · SE-0462 Task Priority Escalation · SE-0463 Obj-C completion handlers as `@Sendable` · SE-0464 UTF8Span · SE-0465 Stdlib primitives for nonescapable types · SE-0466 Control default actor isolation · SE-0467 MutableSpan / MutableRawSpan · SE-0468 `Hashable` for AsyncStream.Continuation · SE-0469 Task Naming · SE-0470 Global-actor isolated conformances · SE-0471 Custom SerialExecutor isolation checking · SE-0472 Starting tasks synchronously · SE-0475 Transactional Observation of Values · SE-0476 Controlling function ABI · SE-0477 Default value in string interpolations · SE-0480 Warning control for SwiftPM · SE-0482 Binary static library dependencies · SE-0483 `InlineArray` type sugar · SE-0485 OutputSpan · SE-0486 Migration tooling for Swift features · SE-0488 `extracting()` slicing pattern

</details>

---

## Reference links

- [Swift Evolution dashboard](https://www.swift.org/swift-evolution/) — searchable, filterable by version
- [Machine-readable dashboard JSON](https://download.swift.org/swift-evolution/v1/evolution.json) — what this table was built from
- [swift-evolution proposals](https://github.com/swiftlang/swift-evolution/tree/main/proposals) — the full text of every proposal
- [Swift CHANGELOG](https://github.com/swiftlang/swift/blob/main/CHANGELOG.md) — language changes per release, with examples
- [Apple Developer — Updates](https://developer.apple.com/documentation/updates) — per-framework, per-release API changes. The best official "what's new in framework X" index
- [Swift 6 migration guide](https://www.swift.org/migration/documentation/migrationguide/) — official, for Batch 3
