# Swift Study Curriculum — WWDC22 → WWDC25

A structured revision of the Swift language and the Apple platform APIs shipped between WWDC22 and WWDC25, taught against a real codebase: this one.

The goal is not familiarity. The goal is being able to reach for the right tool without looking it up, understand what the compiler and runtime actually do underneath, and then apply it here as a real change.

---

## How this curriculum is built

**Four batches, one per WWDC year**, plus this foundation. Each batch is written only after the previous one has been studied and its exercises implemented, so later material can react to what actually got built.

| Batch | Year | Swift | OS | Status |
|---|---|---|---|---|
| 0 | — | — | — | ✅ written |
| 1 | WWDC22 | 5.7 | iOS 16 | ✅ [written](wwdc22/README.md) — 6 modules |
| 2 | WWDC23 | 5.9 | iOS 17 | ⏳ after Batch 1 |
| 3 | WWDC24 | 6.0 | iOS 18 | ⏳ after Batch 2 |
| 4 | WWDC25 | 6.2 | iOS 26 | ⏳ after Batch 3 |

### Foundation documents

| File | What it is |
|---|---|
| [Version Map](00-version-map.md) | The lookup table: WWDC year ↔ Swift ↔ Xcode ↔ OS, with the full list of language proposals shipped per version. Consult this whenever you ask "can I use this yet?" |
| [Baseline](00-baseline.md) | An honest inventory of what this codebase already does well, what it does the old way, and the staged deployment-target plan |
| [Review Protocol](review-protocol.md) | What happens at the end of each batch: how the review is triggered, what gets checked, and what you get back |

---

## Two rules this curriculum follows

**1. Every claim is sourced.** Nothing here is written from memory. Language features are anchored to their [Swift Evolution](https://www.swift.org/swift-evolution/) proposal and verified against the [official evolution dashboard](https://download.swift.org/swift-evolution/v1/evolution.json), which records exactly which Swift release each proposal shipped in. Framework APIs are anchored to Apple's developer documentation. Where something comes from a non-Apple source, it is labelled as such.

**2. You write all the code.** These documents contain Swift only as teaching snippets in fenced blocks. Nothing here is applied to `Pokespeare/` or `Demo/` — every implementation is yours. That is the point: reading about `sending` teaches you nothing, and fighting the compiler over it for twenty minutes teaches you permanently.

---

## Document structure

Every module document follows the same seven-part shape:

1. **What shipped, and what problem it solves** — the motivation, before the syntax.
2. **How it actually works** — what the compiler emits and what the runtime does. Existential boxes and witness tables, macro expansion phases, where a suspension point really goes, why region-based isolation is a compile-time proof rather than a runtime check.
3. **Official sources** — verified links and SE numbers.
4. **Where it lands in this codebase** — concrete `file:line` references, either to code doing it the old way or to the gap where it belongs.
5. **Exercise** — a task you implement, with acceptance criteria and the verification command.
6. **Pitfalls** — the traps, including the ones this project already fell into (see `HANDOFF.md` and the C-01…C-25 audit findings).
7. **Self-check** — questions that are uncomfortable to answer if you only skimmed.

---

## The study loop

For each module:

1. **Read** the module document end to end before touching Xcode. Sections 1 and 2 are the part that matters; the syntax is the easy half.
2. **Answer the self-check** from memory. If a question is uncomfortable, re-read section 2 rather than moving on.
3. **Implement** the exercise on a branch — one branch per module keeps the diffs readable and reversible.
4. **Verify** — the module's acceptance criteria, plus the full existing suite staying green (see below).
5. **Commit**, then move to the next module.

Each batch also ends with a **Build Challenges** module: features large enough that you have to re-implement, from scratch, the WWDC technology the project already contains. Reading `RetryPolicy.swift` and thinking "yes, `Duration`, understood" is not the same as designing a new manager and discovering for yourself where `Sendable` bites.

### End of batch

When *you* decide a batch is done, say so — nothing is automatic, and you are never interrupted mid-batch. I then read every diff, run the full suite, check the project's invariants, and probe the theory. You get back what is correct, what is wrong with the failing scenario spelled out, and which concepts are solid, shaky, or not yet there.

Full details, including what to prepare: **[Review Protocol](review-protocol.md)**.

### Verification commands

The package declares only an iOS platform, so everything goes through `xcodebuild` — `swift test` will not work. This matches CI (`.github/workflows/ci.yml`).

SDK tests:

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

App tests:

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Lint, exactly as CI runs it:

```bash
swiftlint lint --strict
```

**The regression bar:** 53 SDK tests + 18 app tests must stay green, and SwiftLint must stay clean, after every exercise. Leave `RUN_INTEGRATION_TESTS` unset — those tests hit live third-party APIs behind a rate limit.

---

## Scope

**In scope:** WWDC22, WWDC23, WWDC24, WWDC25 — the Swift language, SwiftUI, SwiftData, Swift Testing, Swift Charts, WidgetKit, App Intents, Foundation Models, and the surrounding tooling (SwiftPM, Xcode, Instruments).

**Out of scope:** WWDC26 / iOS 27 / Xcode 27. Deliberately excluded — the four years asked for are 22 through 25.

Swift 6.3 sits after WWDC25 but is what is installed on this machine. It gets a short appendix note in Batch 4, not a module of its own.

---

## Prerequisites

Verified present on this machine:

- Xcode **26.4.1** (build 17E202)
- Swift **6.3.1**
- iOS SDK **26.4**
- Simulator runtimes: iOS **18.6** and **26.4**

Everything from WWDC22 through WWDC25 compiles here today.
