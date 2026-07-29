# Handoff — architectural audit and refactor

Written for whoever picks this branch up next. It records what changed, why, what the
non-obvious constraints are, and what is deliberately left undone.

Language matches the rest of the repository (README, commits, doc comments): English.

- **Branch:** `refactor` (branched from `master`, pushed to `origin`)
- **Commits:** 17, all self-contained and individually revertible
- **State:** SDK 53 tests green, app 18 tests green, SwiftLint clean under `--strict`,
  both targets building in Swift 6 language mode

---

## 1. What this was

An audit of the repository from a senior iOS perspective, followed by the fixes. The
starting point was **1,359 lines over 29 Swift files**: a Swift package (`Pokespeare`) and
a SwiftUI demo app (`PokeApp`).

The underlying design was sound — struct-of-closures managers, a `Session` protocol as a
test seam, Swift Concurrency throughout, Swift Testing with nested suites. The problem was
that all of it was **used halfway**: the injection seam existed but was never used by the
app, the declarative networking layer was duplicated across both managers, and a third of
the public error enum could never reach a user.

**25 findings**: 3 blocking, 9 high, 12 medium, 1 low. All resolved.

---

## 2. Commits, in order

Each commit names the finding IDs it closes. `git log --oneline master..refactor`:

| Commit | Closes | What |
|---|---|---|
| `11ff09d` | C-10 | `#expect(throws:)` instead of assertions inside `catch` |
| `e587db3` | C-11 | Integration tests gated behind `RUN_INTEGRATION_TESTS` |
| `d92fbc1` | C-12 | `Issue.record` instead of `fatalError` in the unimplemented session |
| `111b42c` | — | Characterization tests for request building and the error pipeline |
| `5c1fb55` | — | SwiftLint + EditorConfig configuration |
| `5218626` | C-24 | Indentation normalised, 200 lint violations to 0 |
| `1279c7b` | — | CI workflow |
| `5d952d5` | C-01, C-03, C-04, C-05, C-07, C-17, C-25 | Single API client, rebuilt error model |
| `0995a0a` | C-02, C-06, C-08, C-09 | `@MainActor`, constructor injection, `async let`, cancellation |
| `d18b915` | — | Test target for the app, `SearchViewModel` coverage |
| `5425a58` | C-13, C-14, C-15 | SwiftData history made durable |
| `dcddc75` | — | README brought in line with the code |
| `b573772` | C-20, C-22 | Namespaced constants, locale-aware languages |
| `d2488d1` | C-18, C-19 | HTTP layer trimmed, translation text moved to a body |
| `88da092` | C-16 | UIKit out of the view model |
| `19b4731` | C-21 | String Catalogs, en + it |
| `9f787fc` | C-23 | Retry, cache, accessibility |

**Ordering was not arbitrary.** The test suite was repaired first: refactoring the error
handling on top of a suite where 3 of 12 tests passed without asserting anything would have
meant not noticing the regressions.

---

## 3. The three that mattered

### C-01 — every network failure reached the user as "error code -1"

The managers threw bare `URLError`s. `Pokespeare.Error.from(error:)` had no case for them,
so they fell into the `else` branch and became `.networkError(.unknown)`. A 500, a timeout
and a device with no connection produced the **same message with the same code**.

Now errors are typed end to end. `APIClient` is the only place that touches transport, and
every failure leaves it as an `APIError` carrying the real cause.

### C-25 — the SDK swallowed its own errors

Not visible by reading: found by a characterization test in phase 1.

The `guard`s in `Pokespeare.live` threw `Pokespeare.Error` *inside* the `do` block whose
`catch` funnelled everything through `from(error:)` — which had no case for
`Pokespeare.Error` and rewrote it as `.networkError(.unknown)`. Three of the eight public
cases (`descriptionUnavailable`, `englishDescriptionUnavailable`, `spriteUnavailable`) were
therefore undeliverable. A Pokémon that existed but had no english description told the
user "something went wrong, code -1".

`from(error:)` now passes its own type through first, and falls back to `.unknown` for
genuinely unknown errors instead of pretending they are network problems.

### C-02 — data race in the view model

`SearchViewModel` mutated UI-observed state and a non-`Sendable` `ModelContext` from a
detached `Task`. It only compiled because the app target was on `SWIFT_VERSION 5.0` while
the package was on `swift-tools 6.0`. Now `@MainActor`, and the app builds in Swift 6
language mode.

---

## 4. Architecture after the refactor

### SDK

```
Pokespeare.swift          public services, the only place that maps to Pokespeare.Error
Core/
  Constants.swift         namespaced; preferred languages come from Locale
  Networking/
    APIClient.swift       the single transport: build, validate, decode, wrap
    RetryPolicy.swift     which failures are worth another attempt, and how long to wait
  Managers/
    PokemonManager        domain logic only
    TranslationManager    domain logic only
  Models/Network/         HTTPRequest, HTTPRequestBody, HTTPMethod, status codes, Session
  Models/Requests|Responses
UI/                       PokemonView, PokemonViewModel
Resources/Localizable.xcstrings
```

Two rules hold the error model together:

1. **Transport failures leave a manager as `APIError`.** Managers only throw their own
   domain errors. Endpoint-specific status codes (404 for PokeAPI, 429 for FunTranslations)
   are supplied as `APIClient`'s `statusCodeMapper`, which is what stops the transport from
   being duplicated per manager.
2. **`Pokespeare.Error.from(error:)` is the only boundary.** It handles `Pokespeare.Error`
   first, then the manager types, then `APIError`, then bare `URLError`, then `.unknown`.

Public surface is exactly `Pokespeare`, `Pokespeare.Error`, `PokemonView`,
`PokemonViewModel`. Everything else is `internal`.

### App

`SearchViewModel` is `@MainActor`, `final`, and takes both dependencies through its
initialiser:

```swift
SearchViewModel(modelContext: ModelContext, pokespeare: Pokespeare = .live)
```

The two PokeAPI calls run concurrently with `async let`. The search `Task` is retained and
cancelled when a new search starts, so a slower older search cannot overwrite a newer
result. Cancellation is not an error: it raises no alert and does not clear a spinner a
newer search just turned on.

---

## 5. Build, test, lint

The package declares only `.iOS(.v17)`, so **`swift build` and `swift test` do not work on
macOS**. Everything goes through `xcodebuild`.

```bash
cd Pokespeare && xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
swiftlint lint --strict
```

Integration tests hit live third-party APIs behind a 5 calls/hour limit and are skipped
unless asked for:

```bash
cd Pokespeare && RUN_INTEGRATION_TESTS=1 xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

CI (`.github/workflows/ci.yml`) runs lint, the package tests and the app tests on every push
to `master` and every pull request. It resolves the simulator at run time, preferring
iPhone 17 Pro and falling back to whatever iPhone the runner image has, because runner
images rotate device types.

---

## 6. Things that will bite you if nobody tells you

### FunTranslations is gone

The endpoint the SDK was written against is no longer served. Translation is **off by
default** and `description(for:)` returns the PokeAPI flavor text verbatim.

This is an explicit parameter, not commented-out code:

```swift
Pokespeare.live(pokemonManager:translationManager:isTranslationEnabled: true)
```

The translated path stays compiled and covered by tests. Turn the flag on when a translation
backend exists again.

### SwiftData: in-memory containers trap

On Xcode 26.4 / iOS 26.4, **any `fetch` against an `isStoredInMemoryOnly` container crashes
with `SIGTRAP` inside SwiftData**. The same fetch against a file-backed store works.

Tests and the SwiftUI preview therefore use throwaway file-backed stores under the temporary
directory (`Demo/PokeAppTests/TemporaryStore.swift`). Do not "simplify" them back to
in-memory.

### SwiftData: a context does not retain its container

`ModelContext` does **not** keep its `ModelContainer` alive. A helper that builds a container
and returns only `container.mainContext` produces a context that traps as soon as the
container is deallocated. `TemporaryStore` holds the containers in a static array for the
lifetime of the test process for exactly this reason.

### The app rebuilds its store if it cannot open it

Moving `@Attribute(.unique)` from a generated UUID to `name` is not migratable from an
installed version. `PokeApp.makeModelContainer()` tries to open the store, and if it cannot,
deletes it (including the `-shm`/`-wal` sidecars) and starts fresh.

This is deliberate: the history is a cache of past searches, and a crash loop after an update
is a far worse outcome than re-fetching them. If the model ever holds user-authored content,
replace this with a real `VersionedSchema` + `MigrationPlan`.

### Retries are narrower than they look

`RetryPolicy` only retries dropped connections, timeouts, failed name lookups and 5xx. A 404,
a malformed body and the translation rate limit are **not** retried — repeating them only
delays the message or burns more of the hourly quota. This needs no special-casing: errors a
manager mapped into its own domain type never reach the retry logic, because they are no
longer `APIError`.

### Tests must be serialised

`SearchViewModelTests` is marked `.serialized`. Standing up several SwiftData stores
concurrently crashes the test process.

### Two loose ends from the process itself

- The branch is called **`refactor`**, not `refactor/architectural-audit`: a ref named
  `refactor` already existed and blocked creating the nested path.
- The formatting commit (`5218626`) swallowed a pre-existing uncommitted working-tree change
  (the commented-out translation call) because it was staged with `git add -A`. The substance
  was resolved in `5d952d5`, which turned it into the `isTranslationEnabled` parameter, but
  the commit itself mixes formatting with that one behavioural line.

---

## 7. Testing conventions

- **No assertions inside `catch`.** Use `#expect(throws:)`. The old pattern passed green
  whenever the code under test stopped throwing, which is exactly the regression you want to
  catch.
- **Substituting the SDK needs no protocol and no mock class.** `Pokespeare` is a struct of
  closures with a public `init(description:sprite:)`:

  ```swift
  let sdk = Pokespeare(description: { _ in "A description" }, sprite: { _ in someURL })
  ```

  `Demo/PokeAppTests/PokespeareStub.swift` wraps this in `.stub(...)` and `.unimplemented()`,
  the latter recording an issue if it is ever called.
- **Language lists are passed explicitly** in tests (`PokemonManager.live(session:languages:)`)
  so results do not depend on the machine's locale.
- **Never trap in a test helper.** A `fatalError` takes the whole test process down and
  discards every other result. Record an issue and throw.

---

## 8. What is not done

Nothing from the audit remains open. Reasonable next steps, none of them blocking:

- **A real SwiftData migration plan**, if the model ever stores anything the user authored.
  Today's recovery path is a deliberate trade for a cache.
- **More languages in the String Catalogs.** The mechanism is proven with en + it; adding a
  locale is now only a catalog entry.
- **Snapshot tests for `PokemonView`**, particularly across Dynamic Type sizes. The
  accessibility work was verified by hand on the simulator, not pinned by a test.
- **A translation backend.** When one exists, flip `isTranslationEnabled` and consider API
  key support so the 5 calls/hour ceiling stops being the binding constraint.
- **Instrument the retry policy.** The backoff numbers (2 retries, 300ms base) are reasonable
  defaults, not measured ones.

The full audit document, with every finding and its severity, lives outside the repository at
`~/.claude/plans/analizza-questo-repository-come-greedy-hamster.md`.
