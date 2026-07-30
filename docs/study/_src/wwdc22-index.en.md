# Batch 1 — WWDC22 · Swift 5.7 · iOS 16

The year Swift's generics became usable, regular expressions arrived natively, and SwiftUI replaced `NavigationView` with something data-driven.

**32 language proposals shipped in Swift 5.7.** This batch covers the ones that changed how you write everyday code, plus the four frameworks that debuted alongside them.

---

## Modules

| # | Module | Core topic | Exercise size |
|---|---|---|---|
| 1 | [Generics and Existentials](01-generics-and-existentials.md) | `any` vs `some`, primary associated types, existential container layout | Medium |
| 2 | [Regex and String Processing](02-regex-and-string-processing.md) | `Regex`, literals, `RegexBuilder`, string algorithms | Small |
| 3 | [Concurrency Foundations](03-concurrency-foundations.md) | `Sendable`, checking levels, SE-0338 execution semantics, `Clock`/`Duration` | Medium |
| 4 | [SwiftUI Navigation and Layout](04-swiftui-navigation-and-layout.md) | `NavigationStack`, `navigationDestination`, `Layout`, `ViewThatFits` | Large |
| 5 | [Platform Debuts](05-platform-debuts.md) | App Intents, Swift Charts, Lock Screen widgets, `Transferable` | Pick one |
| 6 | [Build Challenges](06-build-challenges.md) | Re-implement the WWDC22 tech the project already uses, by building real features | Pick one to three |

**Suggested order: 1 → 2 → 3 → 4 → 5 → 6.** Module 4 depends on nothing, but Module 5's larger exercise and Module 6's Challenges B and C both consume Module 4's navigation work — do not start those first.

Modules 1 and 3 are the theory-heavy ones. Modules 2, 4 and 5 are where you write the most code. **Module 6 is where it is proven**: three features against live PokéAPI endpoints — evolution chains, type matchups, search filters — sized so you cannot complete them without rebuilding, yourself, the `Sendable` discipline, the error boundary, the single-transport rule and the `Duration` handling that the SDK already demonstrates.

---

## What this batch changes in the project

If you do every exercise, the project ends the batch with:

- A regex-backed, tested name validator replacing the `searchText.count > 2` magic number (audit finding **C-20**) — *Module 2*
- An injectable clock in `APIClient`, making the retry backoff testable without real sleeping, and a faster test suite — *Module 3*
- Real navigation replacing the sheet-based detail presentation, with navigation state tested as data — *Module 4*
- History rows that survive accessibility text sizes via `ViewThatFits` — *Module 4*
- Either sharing, or an App Intent plus a Lock Screen widget — *Module 5*
- At least one new SDK service built end to end — request, response model, manager, error mapping, tests — *Module 6*

Modules 1 and 3 also produce written analysis rather than only code. Keep those notes — Batch 3 builds directly on them.

---

## Two things worth knowing before you start

**Every snippet in this batch was compiled.** Not recalled — typechecked against the iOS 26.4 SDK in Swift 6 language mode before being written down. Where a snippet is shown as failing, that error text is real compiler output.

**One finding came out of that process** and is worth flagging up front, because it will cost you twenty minutes otherwise: **`Regex` is not `Sendable`.** A global `let` holding one gets `@MainActor` inferred, and the error only appears when nonisolated code touches it — which in this project means the whole SDK. Module 2 covers it, with both fixes.

---

## Verification

Every exercise ends at the same bar: **all 71 tests green** (53 SDK + 18 app), SwiftLint clean.

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
swiftlint lint --strict
```

Leave `RUN_INTEGRATION_TESTS` unset — those hit live rate-limited APIs.

---

## When you finish

Say **"batch done"** and the review starts. Nothing is automatic — you decide when.

Have ready: your work committed, and a short note per module covering what you built, what you decided *against*, what you did not finish, and which self-check questions were uncomfortable. The judgement calls in Module 4 (§5a), Module 2 (§6a) and Module 6 (A1) are assessed on the reasoning, not the diff.

See the [Review Protocol](review-protocol.md) for exactly what gets checked and what you get back. Batch 2 (WWDC23: macros, Observation internals, SwiftData depth) is then adjusted based on what actually landed and where the theory was shaky.
