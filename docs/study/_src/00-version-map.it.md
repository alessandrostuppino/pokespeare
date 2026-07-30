# Mappa delle versioni — anno WWDC ↔ Swift ↔ Xcode ↔ OS

La tabella da consultare per "quando posso usarlo, e cosa devo proteggere con una guardia?"

**Nota sulle fonti.** I dati "quale proposta in quale versione di Swift" vengono dalla [dashboard ufficiale Swift Evolution](https://download.swift.org/swift-evolution/v1/evolution.json) (`implementationVersions` + `status.version` per proposta), snapshot del 2026-07-28. È autorevole: è generata dal repository swift-evolution stesso. La colonna Swift↔Xcode non ha una tabella ufficiale pubblicata da Apple; la riga di questa macchina è stata misurata direttamente (`xcodebuild -version` → Xcode 26.4.1, `swift --version` → Swift 6.3.1), il resto viene dalle release note di Xcode.

---

## La tabella principale

| WWDC | Swift | Xcode | iOS | Uscita | Titolo del linguaggio |
|---|---|---|---|---|---|
| **2022** | **5.7** | 14 | **16** | Set 2022 | Existential e generics finalmente usabili; Regex; `Clock`/`Duration` |
| — | 5.8 | 14.3 | — | Mar 2023 | Release di consolidamento |
| **2023** | **5.9** | 15 | **17** | Set 2023 | **Macro**; Observation; ownership; parameter pack |
| — | 5.10 | 15.3 | — | Mar 2024 | Isolamento dati completo sotto `-strict-concurrency=complete` |
| **2024** | **6.0** | 16 | **18** | Set 2024 | **Swift 6 language mode**; typed throws; region-based isolation; `Synchronization` |
| — | 6.1 | 16.3 | — | Mar 2025 | Virgola finale, package traits |
| **2025** | **6.2** | 26 | **26** | Set 2025 | **Approachable concurrency**; `Span`; `InlineArray`; `Observations` |
| — | 6.3 | 26.4 | 26.4 | 2026 | Toolchain attuale qui. Successiva a WWDC25 — solo appendice |

**Sul salto di versione:** iOS è passato da 18 a 26 e Xcode da 16 a 26 perché a settembre 2025 Apple ha unificato i numeri di versione di tutti gli OS e della toolchain su uno schema basato sull'anno. Non esistono iOS 19–25. Xcode 26 è la finestra di release da settembre 2025 a settembre 2026.

**I tre numeri indipendenti.** Tienili separati — confonderli è la fonte di confusione più comune:

- **Swift language mode** (`swiftLanguageMode` / `SWIFT_VERSION`) — quale *dialetto* il compilatore impone. `6` accende la data-race safety completa come errori.
- **Versione della toolchain Swift** — quale binario del compilatore hai. Qui Swift 6.3.1. Una toolchain 6.3 può comunque compilare in language mode 5.
- **Deployment target** (`platforms:` / `IPHONEOS_DEPLOYMENT_TARGET`) — su quale OS devono esistere le API a *runtime*. Indipendente dagli altri due.

Puoi usare una funzionalità di linguaggio di Swift 6.2 con deployment a iOS 17, perché le funzionalità di linguaggio sono compile-time. Non puoi usare `glassEffect` con deployment a iOS 17 senza una guardia `#available`, perché quella è un'API a runtime.

---

## Cosa ha portato ogni anno

### WWDC22 · Swift 5.7 · iOS 16

**Linguaggio** — 32 proposte. Il tema è *generics ed existential che diventano usabili*, più l'elaborazione di stringhe.

La storia dei generics: `any` è diventata la grafia obbligatoria per gli existential ([SE-0335](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0335-existential-any.md), in realtà Swift 5.6), poi 5.7 ha rimosso le restrizioni che li rendevano dolorosi — [SE-0309](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md) ha sbloccato gli existential per i protocol con associated type, [SE-0346](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md) ha aggiunto i primary associated type (`some Collection<Int>`), [SE-0341](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0341-opaque-parameters.md) ha permesso `some` in posizione di parametro, e [SE-0352](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0352-implicit-open-existentials.md) ha lasciato che il compilatore apra implicitamente un existential per chiamarci sopra una funzione generica.

Inoltre: **Regex** — un pacchetto di cinque proposte ([SE-0350](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0350-regex-type-overview.md) tipo, [SE-0351](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0351-regex-builder.md) DSL builder, [SE-0354](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0354-regex-literals.md) literal, [SE-0355](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0355-regex-syntax-run-time-construction.md) sintassi, [SE-0357](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0357-algorithms-string-processing.md) algoritmi). **Clock/Instant/Duration** ([SE-0329](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md)) — già usato in questo repo a `RetryPolicy.swift:9`. La forma abbreviata `if let x {` ([SE-0345](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0345-if-let-shorthand.md)). `Sendable` e closure `@Sendable` ([SE-0302](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)). Distributed actor ([SE-0336](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0336-distributed-actor-isolation.md), [SE-0344](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0344-distributed-actor-runtime.md)).

**Framework** — `NavigationStack` / `NavigationSplitView` al posto di `NavigationView`; il protocol `Layout`, `Grid`, `ViewThatFits`; i presentation detent; `ShareLink` e `Transferable`; debutto di **Swift Charts**; debutto di **App Intents**; widget da lock screen in WidgetKit; WeatherKit.

### WWDC23 · Swift 5.9 · iOS 17

**Linguaggio** — 23 proposte. Il tema è *macro* e *ownership*.

Le **macro** sono il pezzo forte: [SE-0382](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0382-expression-macros.md) macro di espressione, [SE-0389](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0389-attached-macros.md) macro attached, [SE-0397](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0397-freestanding-declaration-macros.md) macro di dichiarazione freestanding, [SE-0394](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0394-swiftpm-expression-macros.md) supporto SwiftPM. Questo repo usa tre macro ogni giorno senza averne mai visto l'interno: `@Observable`, `@Model`, `#Preview`.

Ownership: [SE-0366](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0366-move-function.md) `consume`, [SE-0377](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md) `borrowing`/`consuming`, [SE-0390](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md) tipi noncopyable. Generics: [SE-0393](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0393-parameter-packs.md) value e type parameter pack. Inoltre [SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md) espressioni `if`/`switch` (usate ovunque in questo repo — ad es. `RetryPolicy.swift:30`, `Error.swift:110`), [SE-0395](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0395-observability.md) **Observation**, [SE-0386](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0386-package-access-modifier.md) il livello di accesso `package`, [SE-0392](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md) executor di actor personalizzati.

**Framework** — **SwiftData**; Observation in SwiftUI (`@Observable`, `@Bindable`); `PhaseAnimator` e `KeyframeAnimator`; la famiglia di API sullo scroll (`scrollTargetBehavior`, `scrollPosition`, `containerRelativeFrame`, `visualEffect`); `ContentUnavailableView`; `Inspector`; `symbolEffect`; `#Preview`; **String Catalog**; TipKit; view StoreKit; widget interattivi.

### WWDC24 · Swift 6.0 · iOS 18

**Linguaggio** — 33 proposte. Il tema è *data-race safety completa*.

Lo Swift 6 language mode rende la data-race safety una garanzia a compile-time invece di un warning. Il contorno: [SE-0414](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md) **region-based isolation** (il compilatore dimostra che un valore non è referenziato altrove, quindi può attraversare un confine di isolamento anche se non è `Sendable`), [SE-0430](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md) `sending`, [SE-0431](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md) `@isolated(any)`, [SE-0420](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0420-inheritance-of-actor-isolation.md) ereditarietà dell'isolamento, [SE-0423](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md) enforcement dinamico, [SE-0434](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0434-global-actor-isolated-types-usability.md) usabilità dei tipi isolati su global actor.

Oltre la concorrenza: [SE-0413](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md) **typed throws**; [SE-0433](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0433-mutex.md) `Mutex` e [SE-0410](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0410-atomics.md) `Atomic` nel nuovo modulo `Synchronization`; [SE-0427](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md) generics noncopyable; [SE-0408](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0408-pack-iteration.md) iterazione sui pack; [SE-0435](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0435-swiftpm-per-target-swift-language-version-setting.md) versione di linguaggio per target; [SE-0425](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0425-int128.md) interi a 128 bit.

**Framework** — debutto di **Swift Testing** (questo repo lo usa già in esclusiva); macro `@Entry` e `@Previewable`; container SwiftUI personalizzati; transizioni di navigazione zoom; `MeshGradient`; `TextRenderer`; `onGeometryChange`; la nuova API `Tab`; SwiftData `#Index`, `#Unique`, `DataStore` personalizzato, history tracking; Control Widget.

### WWDC25 · Swift 6.2 · iOS 26

**Linguaggio** — 32 proposte. Il tema è *approachable concurrency* — fare marcia indietro sulle parti di Swift 6 che punivano codice che non era mai stato concorrente.

[SE-0466](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md) **controllo dell'isolamento di default** — porta un intero modulo a `@MainActor` di default, così il codice UI a thread singolo smette di pagare per una concorrenza che non ha mai chiesto. [SE-0461](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md) **le funzioni async nonisolated girano sull'actor del chiamante di default** — e con essa l'attributo `@concurrent`, l'opt-in esplicito per lasciare l'actor del chiamante. [SE-0472](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md) avvio sincrono dei task. [SE-0470](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md) conformance isolate su global actor.

Performance e sicurezza: [SE-0447](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0447-span-access-shared-contiguous-storage.md) `Span`, [SE-0453](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0453-vector.md) `InlineArray`, [SE-0446](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0446-non-escapable.md) tipi nonescapable, [SE-0458](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0458-strict-memory-safety.md) strict memory safety opt-in. Observation: [SE-0475](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md) **osservazione transazionale dei valori** — la sequenza asincrona `Observations`. Toolchain: [SE-0486](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0486-adopting-swift-features.md) tooling di migrazione, [SE-0480](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0480-warning-control-flags.md) controllo dei warning in SwiftPM.

**Framework** — **Liquid Glass** (`glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`); **Foundation Models** — l'LLM on-device, con guided generation via `@Generable`; `WebView`/`WebPage`; l'editor di testo ricco basato su `AttributedString`; `@Animatable`; Swift Charts 3D; exit test e attachment in Swift Testing; Icon Composer.

---

## L'availability in pratica

Le funzionalità di linguaggio sono compile-time e non richiedono guardie. Le API a runtime sì. Le due forme:

```swift
// Proteggere un'espressione.
if #available(iOS 26, *) {
  content.glassEffect()
} else {
  content.background(.regularMaterial)
}

// Proteggere un'intera dichiarazione.
@available(iOS 26, *)
struct GlassCard: View { /* … */ }
```

Per i view modifier in particolare, il ramo qui sopra duplica il tipo della view su entrambi i lati. Quando cambia solo il modifier, preferisci un helper per modifier condizionali così l'identità della view resta stabile — SwiftUI tratta i due rami di un `if` come *view diverse*, il che azzera lo stato e rompe le animazioni.

`@available` porta anche deprecazione e obsolescenza, che è ciò che incontrerai leggendo gli header Apple:

```swift
@available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use NavigationStack")
```

Vedi [Punto di partenza](00-baseline.md) per il piano a tappe dei deployment target di questo progetto.

---

## Indice completo delle proposte

Tutte le proposte uscite in ciascuna delle quattro versioni target, dalla dashboard. Usalo per verificare se una cosa che ricordi a metà esiste davvero, e in quale versione è arrivata.

<details>
<summary><b>Swift 5.7 — 32 proposte (WWDC22)</b></summary>

SE-0292 Package Registry Service · SE-0302 `Sendable` e closure `@Sendable` · SE-0309 Existential per tutti i protocol · SE-0326 Inferenza di tipo in closure multi-statement · SE-0328 Opaque result type strutturali · SE-0329 Clock, Instant e Duration · SE-0333 Usabilità di `withMemoryRebound` · SE-0334 Usabilità delle API sui puntatori · SE-0336 Distributed Actor Isolation · SE-0338 Esecuzione delle funzioni async non isolate · SE-0339 Module aliasing · SE-0340 Unavailable from async · SE-0341 Opaque parameter declaration · SE-0343 Concorrenza nel top-level code · SE-0344 Distributed Actor Runtime · SE-0345 Forma abbreviata `if let` · SE-0346 Same-type requirement leggeri · SE-0347 Inferenza di tipo da espressioni di default · SE-0348 `buildPartialBlock` · SE-0349 Load e store non allineati · SE-0350 Tipo Regex · SE-0351 DSL regex builder · SE-0352 Existential aperti implicitamente · SE-0353 Existential vincolati · SE-0354 Literal regex · SE-0355 Sintassi regex · SE-0356 Swift Snippets · SE-0357 Algoritmi su stringhe basati su regex · SE-0358 Primary associated type nella stdlib · SE-0360 Opaque result type con availability limitata · SE-0361 Extension su tipi generici vincolati · SE-0363 Unicode per l'elaborazione di stringhe

</details>

<details>
<summary><b>Swift 5.9 — 23 proposte (WWDC23)</b></summary>

SE-0366 Operatore `consume` · SE-0374 `sleep(for:)` su Clock · SE-0377 `borrowing`/`consuming` · SE-0380 Espressioni `if`/`switch` · SE-0381 DiscardingTaskGroup · SE-0382 Macro di espressione · SE-0384 Interfacce Obj-C dichiarate in avanti · SE-0386 Modificatore di accesso `package` · SE-0388 `AsyncStream.makeStream` · SE-0389 Macro attached · SE-0390 Struct ed enum noncopyable · SE-0391 Package Registry Publish · SE-0392 Executor di actor personalizzati · SE-0393 Value e Type Parameter Pack · SE-0394 Macro personalizzate in SwiftPM · SE-0395 Observation · SE-0396 `Never: Codable` · SE-0397 Macro di dichiarazione freestanding · SE-0398 Tipi generici che astraggono sui pack · SE-0399 Tupla da espansione di value pack · SE-0400 Init accessor · SE-0401 Rimozione dell'inferenza di isolamento dai property wrapper · SE-0402 Macro `extension`

</details>

<details>
<summary><b>Swift 6.0 — 33 proposte (WWDC24)</b></summary>

SE-0220 `count(where:)` · SE-0270 Operazioni su elementi non contigui · SE-0301 Comandi package editor · SE-0364 Warning per conformance retroattive · SE-0405 Inizializzatori String con validazione dell'encoding · SE-0408 Iterazione sui pack · SE-0409 Modificatori di accesso sulle import · SE-0410 Operazioni atomiche di basso livello · SE-0413 Typed throws · SE-0414 Region based Isolation · SE-0415 Macro sul corpo di funzione · SE-0416 Literal keypath come funzioni · SE-0417 Preferenza di Task Executor · SE-0418 Inferenza di `Sendable` per metodi e keypath · SE-0420 Ereditarietà dell'isolamento · SE-0421 Polimorfismo degli effetti per `AsyncSequence` · SE-0422 Macro di espressione come argomento di default · SE-0423 Enforcement dinamico dell'isolamento · SE-0424 Controllo dell'isolamento per SerialExecutor · SE-0425 Tipi interi a 128 bit · SE-0426 BitwiseCopyable · SE-0427 Generics noncopyable · SE-0428 Risoluzione dei protocol DistributedActor · SE-0429 Consumo parziale di valori noncopyable · SE-0430 Parametri e risultati `sending` · SE-0431 Tipi di funzione `@isolated(any)` · SE-0432 Pattern matching borrowing/consuming · SE-0433 Lock di mutua esclusione sincrono · SE-0434 Usabilità dei tipi isolati su global actor · SE-0435 Versione di linguaggio per target · SE-0437 Primitive stdlib noncopyable · SE-0440 Macro DebugDescription

</details>

<details>
<summary><b>Swift 6.2 — 32 proposte (WWDC25)</b></summary>

SE-0371 Deinit sincrono isolato · SE-0419 API Swift Backtrace · SE-0446 Tipi nonescapable · SE-0447 Span · SE-0451 Identificatori raw · SE-0452 Parametri generici interi · SE-0453 InlineArray · SE-0456 Proprietà che forniscono `Span` · SE-0457 Rappresentazione in attosecondi di `Duration` · SE-0458 Strict Memory Safety opt-in · SE-0459 Conformance `Collection` per `enumerated()` · SE-0461 Async nonisolated sull'actor del chiamante · SE-0462 Escalation di priorità dei task · SE-0463 Completion handler Obj-C come `@Sendable` · SE-0464 UTF8Span · SE-0465 Primitive stdlib per tipi nonescapable · SE-0466 Controllo dell'isolamento di default · SE-0467 MutableSpan / MutableRawSpan · SE-0468 `Hashable` per AsyncStream.Continuation · SE-0469 Naming dei task · SE-0470 Conformance isolate su global actor · SE-0471 Controllo dell'isolamento per SerialExecutor personalizzati · SE-0472 Avvio sincrono dei task · SE-0475 Osservazione transazionale dei valori · SE-0476 Controllo dell'ABI di una funzione · SE-0477 Valore di default nelle interpolazioni di stringa · SE-0480 Controllo dei warning per SwiftPM · SE-0482 Dipendenze da librerie statiche binarie · SE-0483 Zucchero sintattico per `InlineArray` · SE-0485 OutputSpan · SE-0486 Tooling di migrazione per le feature Swift · SE-0488 Pattern di slicing `extracting()`

</details>

---

## Link di riferimento

- [Dashboard Swift Evolution](https://www.swift.org/swift-evolution/) — ricercabile, filtrabile per versione
- [JSON della dashboard](https://download.swift.org/swift-evolution/v1/evolution.json) — da cui è costruita questa tabella
- [Proposte swift-evolution](https://github.com/swiftlang/swift-evolution/tree/main/proposals) — il testo completo di ogni proposta
- [CHANGELOG di Swift](https://github.com/swiftlang/swift/blob/main/CHANGELOG.md) — modifiche al linguaggio per release, con esempi
- [Apple Developer — Updates](https://developer.apple.com/documentation/updates) — modifiche alle API per framework e per release. Il miglior indice ufficiale "cosa c'è di nuovo nel framework X"
- [Guida alla migrazione a Swift 6](https://www.swift.org/migration/documentation/migrationguide/) — ufficiale, riferimento per il Batch 3
