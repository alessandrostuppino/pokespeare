# End-of-Batch Review Protocol

Every batch ends with a review. **You decide when.** Say *"batch done"* (or *"batch N finito"*) and the review starts. Nothing happens automatically — you are never interrupted mid-batch.

This page describes exactly what happens, so nothing about the assessment is a surprise.

---

## What you do first

Before saying the batch is done, have these ready. Two minutes of preparation makes the review far more useful:

1. **Your work committed** — ideally one branch or commit per module, so the diffs read cleanly.
2. **A short note per module** answering:
    - What did you build?
    - What did you decide *against*, and why?
    - What did you not finish, and what blocked you?
    - Which self-check questions were uncomfortable?
3. **The current test count and suite duration.** Say what it was and what it is now.

Point 2 matters most. The exercises deliberately contain judgement calls with no single right answer — Module 4 §5a (sheet vs navigation) and Module 2 §6a (SDK vs app placement) are both like this. **The reasoning is the assessed artifact, not the diff.**

If something is half-finished, say so. An honest "I did not understand region-based isolation well enough to attempt it" is more useful to me than a working copy-paste, and it changes what the next batch contains.

---

## What I do

### 1. Read the code

`git diff` against the batch start point, every file. Not skimmed.

### 2. Run everything

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
swiftlint lint --strict
```

I report what actually happened. If tests fail, you get the failure output, not a summary of it.

### 3. Check the project's own invariants

The audit that produced findings C-01…C-25 established rules this codebase now lives by. Every review checks them, because regressing one is worse than not attempting an exercise:

| Invariant | Origin |
|---|---|
| `APIClient` is the only transport | C-03 |
| Every failure terminates in `Pokespeare.Error`; `from(error:)` ordering intact | C-01, C-25 |
| No `Optional` used as an error channel | C-05 |
| Public surface stays deliberate | C-17 |
| No assertions inside `catch` | C-10 |
| Integration tests gated behind `RUN_INTEGRATION_TESTS` | C-11 |
| No UIKit in view models | C-16 |
| User-facing strings localized in **both** catalogs | C-21 |
| VoiceOver labels and Dynamic Type respected | C-23 |
| No `@unchecked Sendable` in production code | C-02 |

### 4. Probe the theory

This is the part that is not about the code. For each module I pick the concepts the batch was actually built on and ask you to explain them — usually drawn from the module's self-check questions, sometimes a variation designed to catch a memorized answer.

A feature can work for the wrong reason. Code that compiles under Swift 6 mode because you sprinkled `@MainActor` until the errors stopped is not the same as code that is correctly isolated, and the difference does not show up in a test run. It shows up here.

---

## What you get back

### Per module

- **Built** — what landed, factually.
- **Correct** — what is right, specifically, with `file:line`. Not encouragement; the parts worth keeping and repeating.
- **Wrong** — defects, with the failing scenario spelled out: given this input, this happens, and it should do that.
- **Theory gaps** — where the code reveals a misunderstanding rather than a slip. This is the section that drives the next batch.
- **Deviations** — where you departed from the project's patterns, and whether the departure is defensible. Sometimes yours is better than what was there. That gets said.

### Overall

- A judgement on whether the batch's core concepts are **solid**, **shaky**, or **not yet there** — per concept, not one grade for the batch. "Solid on `Sendable`, shaky on existential cost, not yet there on SE-0338 execution semantics" is a useful sentence; "7/10" is not.
- **What to re-read**, pointed at specific sections rather than whole modules.
- **What the next batch changes** as a result — extra material where you are shaky, skipped material where you are clearly past it.

### The two rules I hold myself to

**No inflated praise.** If something is wrong you will be told plainly, once, with the reason. If it is right that gets said too — but "good job" with nothing specific attached is noise, and it makes the genuine praise worthless.

**No invented problems.** If a module came out clean, the report says clean. Manufacturing a nitpick to look thorough wastes your time and mine.

---

## Re-review

Fix things and say *"re-review"* — you get a focused pass on just the changed parts, not the whole batch again.

A concept that came back **shaky** twice gets extra material in the next batch instead of a third repetition of the same explanation. If an explanation is not landing, the explanation is the problem.

---

## What this is not

- Not a gate. You can start the next batch whenever you want; the review is a checkpoint, not a lock.
- Not a code review of the whole repository. Only what the batch touched, plus the invariants above.
- Not a rewrite service. I point at the defect and the reasoning; you fix it. That is the entire point of the arrangement — the code stays yours.
