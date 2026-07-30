# Punto di partenza — dove sta davvero questo codebase

Prima di studiare qualsiasi cosa, un inventario onesto. Conta, perché circa un terzo della superficie WWDC22→25 è **già** in questo progetto, e ri-spiegarla da zero sarebbe tempo sprecato. Quello che segue separa tre cose: cosa già usi bene, cosa usi alla vecchia maniera, e cosa manca del tutto.

Ogni riferimento qui sotto è stato letto al momento della scrittura. I numeri di riga si spostano man mano che fai gli esercizi — trattali come indicazioni, non come indirizzi.

---

## La forma del repo

Due artefatti, nessun workspace:

- **`Pokespeare/`** — un package SPM, l'SDK. `swift-tools-version: 6.0`, `platforms: [.iOS(.v17)]`, zero dipendenze esterne.
- **`Demo/PokeApp.xcodeproj`** — l'app demo, che consuma il package come riferimento locale. `SWIFT_VERSION = 6.0`, `IPHONEOS_DEPLOYMENT_TARGET = 18.1`.

Entrambi compilano in **Swift 6 language mode**. È un punto di partenza genuinamente buono — la maggior parte dei codebase che incontrerai è ancora in mode 5.

Circa 1.600 righe di Swift di produzione, 1.300 di test, 71 test in totale, tutti verdi, SwiftLint pulito, CI su GitHub Actions.

---

## Già usato bene — approfondire, non ri-spiegare

| Funzionalità | Anno | Dove |
|---|---|---|
| Swift 6 language mode | WWDC24 | `Package.swift:1`, pbxproj `SWIFT_VERSION = 6.0` |
| Disciplina `Sendable` / `@Sendable` | WWDC22 | `Pokespeare.swift:3-5`, `APIClient.swift:9,12`, `RetryPolicy.swift:4`, `Session.swift:3` |
| Isolamento `@MainActor` | WWDC21/22 | `SearchViewModel.swift:5` |
| Concorrenza strutturata con `async let` | WWDC21 | `SearchViewModel.swift:172-173` — due chiamate PokeAPI indipendenti in parallelo |
| Cancellazione dei task, fatta bene | WWDC21 | `SearchViewModel.swift:150,155,164,181,186` + l'unwrapper `isCancellation` a `:286-304` |
| `Clock` / `Duration` | WWDC22 | `RetryPolicy.swift:9,42`, `APIClient.swift:40` |
| Espressioni `if` / `switch` | WWDC23 | `RetryPolicy.swift:30`, `Error.swift:41,110`, `APIClient.swift:99` |
| Observation (`@Observable`) | WWDC23 | `SearchViewModel.swift:6`, tenuto in `@State` a `SearchView.swift:6` |
| `NavigationStack` | WWDC22 | `SearchView.swift:14` |
| Presentation detent | WWDC22 | `SearchView.swift:24-25` |
| `onChange` a due parametri | WWDC23 | `SearchView.swift:64,67` |
| Shape statiche e animazioni iOS 17 | WWDC23 | `.capsule` `SearchView.swift:77`, `.rect` `:161`, transizione `.push` `:84-89`, `.smooth` in `TextField+ViewModifier.swift:23` |
| `@ScaledMetric` | — | `PokemonView.swift:7` — lo sprite scala con il Dynamic Type |
| `AsyncImage` basata su fasi | — | `PokemonView.swift:37-48`, con `@unknown default` |
| Macro `#Preview` | WWDC23 | `SearchView.swift:167`, `PokemonView.swift:64` |
| SwiftData `@Model` | WWDC23 | `Pokemon.swift:4-10`, container costruito a mano a `PokeApp.swift:27-47` |
| String Catalog (`.xcstrings`) | WWDC23 | Entrambi i target, en + it, via `String(localized:bundle:)` |
| Swift Testing, in esclusiva | WWDC24 | 71 test, zero XCTest. `@Test`, `@Suite`, `#expect`, `#require`, `@Tag`, `.serialized`, `.disabled(if:)`, argomenti parametrizzati |
| Gruppi sincronizzati con le cartelle in Xcode 16 | WWDC24 | pbxproj `PBXFileSystemSynchronizedRootGroup` |

C'è anche qualità architetturale reale che vale la pena notare, perché diversi esercizi ci costruiscono sopra: l'SDK è una **struct di closure** (`Pokespeare.swift:3-5`) invece di un protocol, il che rende la sostituzione gratuita nei test; il transport è un **unico `APIClient` generico** parametrizzato da una closure `StatusCodeMapper` (`APIClient.swift:12`) invece che duplicato per manager; e il modello degli errori ha **esattamente un punto di mappatura** (`Error.swift:109-124`) il cui ordinamento dei case è portante.

---

## Usato alla vecchia maniera — la superficie di refactor

Funzionano, ma un'API WWDC22→25 fa il lavoro meglio. Ognuno diventa un esercizio.

**La navigazione è solo sheet e alert.** `NavigationStack` c'è a `SearchView.swift:14`, ma non esiste un solo `navigationDestination`, `NavigationLink` o `NavigationPath` nel progetto. Il dettaglio è uno `.sheet(item:)` a `:17`, ed entrambi gli alert sono guidati da booleani a `:27` e `:36`. → *Batch 1: routing type-safe.*

**I binding passano dal dynamic member lookup di `@State`.** `SearchView.swift:6` tiene il view model `@Observable` in `@State` e recupera i binding come `$viewModel.searchText`. `@Bindable` non è mai usato, e nemmeno `@Environment` — il view model è passato dall'initializer a `PokeApp.swift:17`. → *Batch 2.*

**Lo stato vuoto è uno `Spacer()`.** `SearchView.swift:126`. `ContentUnavailableView` (iOS 17) esiste esattamente per questo, e darebbe anche al percorso d'errore una presentazione vera invece di un alert. → *Batch 2.*

**Le stringhe localizzate sono costanti `String` pre-risolte.** `SearchViewModel.swift:40-56` risolve ogni stringa all'init con `String(localized:)`, poi le view le rendono via `Text(String)`. Questo congela il locale al momento della costruzione e rinuncia alle capacità a runtime del catalog. `LocalizedStringResource` è la risposta moderna. → *Batch 2.*

**SwiftData è guidato in modo imperativo.** `FetchDescriptor` costruito a mano a `SearchViewModel.swift:256`, cronologia filtrata in memoria con `first(where:)` a `:143`. Niente `@Query`, niente `#Predicate`, niente `#Index`. E non c'è `VersionedSchema`/`MigrationPlan` — `PokeApp.swift:27-47` cancella e ricostruisce lo store quando non riesce ad aprirlo, con un `fatalError` se fallisce anche quello. → *Batch 2 e 3.*

**Gli errori non sono tipizzati.** Il modello a tre livelli (`APIError` → errori dei manager → `Pokespeare.Error`) è ben progettato, ma ogni funzione è un `throws` nudo. È il caso da manuale per i typed throws (SE-0413): `APIClient.perform` può lanciare solo `APIError`, e il compilatore potrebbe imporlo. → *Batch 3.*

**La validazione è un numero magico.** `SearchViewModel.swift:88` — `searchText.count > 2` fa sia da visibilità del bottone sia da validazione dell'input, e `:233-236` filtra i caratteri con una closure `filter`. È ciò per cui `Regex` è stato introdotto. (Registrato come finding di audit C-20.) → *Batch 1.*

**Il ciclo di retry è un `while true` scritto a mano.** `APIClient.swift:35-44`. Funziona, e il backoff a `RetryPolicy.swift:42` è pulito. Ma non c'è `withTaskCancellationHandler`, e niente nel progetto usa `AsyncStream`, `AsyncSequence` o `TaskGroup`. → *Batch 3.*

**`Package.swift` non ha alcun `swiftSettings`.** Nessun upcoming-feature flag, nessuna language mode esplicita, nessun `defaultIsolation`. Swift 6 mode arriva puramente dalla tools version. → *Batch 3 e 4.*

---

## Assente del tutto

Niente in questo progetto usa: macro scritte da te · typed throws · `Synchronization` (`Mutex`, `Atomic`) · `sending` o region-based isolation su cui ragionare · actor nel codice di produzione (solo nei test) · `@concurrent` / `nonisolated(nonsending)` / isolamento di default · `Span` / `InlineArray` · `Observations` · `@Entry` / `@Previewable` · `.task` / `.searchable` / `.refreshable` · `Layout` personalizzati / `Grid` / `ViewThatFits` · `PhaseAnimator` / `KeyframeAnimator` / `symbolEffect` · la famiglia di API sullo scroll · `MeshGradient` / `TextRenderer` / `onGeometryChange` · Swift Charts · WidgetKit · App Intents · Liquid Glass · Foundation Models.

Quella lista è il programma.

---

## Quella che rende il capstone degno

L'app si chiama **PokéSpeare**. La sua intera premessa sono descrizioni di Pokémon in stile shakespeariano, via l'API FunTranslations.

Quell'endpoint non esiste più. Perciò `Pokespeare.swift:45-49` esce con `isTranslationEnabled: Bool = false`, e `description(for:)` restituisce il flavor text grezzo di PokéAPI. L'app al momento non fa la cosa da cui prende il nome.

**Foundation Models** (WWDC25) può fare quella traduzione on-device, offline, gratis, senza API key e senza rate limit. È il capstone del Batch 4 — non un esercizio inventato per esercitarsi su un framework, ma il framework che si dà il caso risolva il difetto centrale del progetto.

---

## Strategia sui deployment target

Stato attuale:

| Artefatto | Impostazione | Valore |
|---|---|---|
| Package | `Package.swift:9` | `.iOS(.v17)` |
| App | pbxproj `IPHONEOS_DEPLOYMENT_TARGET` | `18.1` (4 occorrenze: righe 264, 321, 395, 414) |

Entrambi sono compilati da Xcode 26.4.1 contro l'**SDK iOS 26.4**.

### Aumenti a tappe

Invece di un salto unico, il target sale quando il programma lo richiede. È deliberato: ogni aumento è un'occasione per esercitarsi con `@available` su codice reale, che è l'abilità che serve davvero al lavoro.

| Quando | Modifica | Perché |
|---|---|---|
| **Ora — Batch 0** | App `18.1` → **`26.0`** | Sblocca subito ogni API WWDC24/25 lato app. L'app è la superficie di sperimentazione. |
| **Batch 3** | Package `.v17` → **`.v18`** | Serve per SwiftData `#Index`/`#Unique` e le API SwiftUI iOS 18 in `PokemonView`. |
| **Batch 4** | Package `.v18` → **`.v26`** | Serve per `glassEffect` dentro il `PokemonView` condiviso, e per Foundation Models. |

Il package resta deliberatamente indietro rispetto all'app. Un SDK che pretende l'OS più recente è un cattivo SDK, e tenerlo indietro ti costringe a scrivere le guardie di availability per bene invece di alzare il pavimento ogni volta che qualcosa è scomodo.

### Una cosa già vera che dovresti sapere

L'adozione di Liquid Glass è guidata dall'**SDK con cui compili**, non dal deployment target. Poiché questo progetto è già compilato con Xcode 26 contro l'SDK iOS 26, l'app **rende già con Liquid Glass** sui dispositivi iOS 26, oggi — prima di qualsiasi aumento e prima che tu scriva una riga di `glassEffect`.

L'opt-out temporaneo è la chiave Info.plist `UIDesignRequiresCompatibility`. Questo progetto imposta `GENERATE_INFOPLIST_FILE = YES` e non ha un file Info.plist, quindi dovrebbe entrare come build setting `INFOPLIST_KEY_UIDesignRequiresCompatibility`. Apple descrive la chiave come un aiuto di migrazione a breve termine che smetterà di funzionare in una release futura, quindi trattala come strumento di debug, non come strategia.

*Nota sulle fonti: l'esistenza e il comportamento della chiave sono documentati in vari thread degli Apple Developer Forums e in resoconti di terze parti ampiamente concordanti, ma non ho potuto leggere direttamente la pagina di documentazione Apple — i doc Apple sono renderizzati in JavaScript e non leggibili da macchina. Verifica contro le release note di Xcode 26 prima di farci affidamento. Questo è segnalato, non presentato come assodato.*

### Esercizio 0 — alza il target dell'app

**Compito.** Imposta il deployment target dell'app a iOS 26.0, per tutte e quattro le build configuration dei target `PokeApp` e `PokeAppTests`.

**Criteri di accettazione.**

1. `grep -c "IPHONEOS_DEPLOYMENT_TARGET = 26" Demo/PokeApp.xcodeproj/project.pbxproj` restituisce `4`.
2. Entrambe le suite passano su un simulatore iOS 26:

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

3. Il package compila ancora intatto a `.iOS(.v17)` — non lo stai ancora alzando:

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

4. `swiftlint lint --strict` resta pulito.

**Due cose da controllare già che ci sei.**

- **`knownRegions`** a `project.pbxproj:149` elenca solo `(en, Base)`, eppure `Demo/PokeApp/Resources/Localizable.xcstrings` porta l'italiano per tutte e 11 le chiavi. Verifica che l'italiano venga davvero spedito: avvia l'app su un simulatore in italiano e controlla la UI, oppure ispeziona il bundle `.app` compilato cercando un `it.lproj`. Se non c'è, è un bug di localizzazione vero nascosto in bella vista.
- **La CI** (`.github/workflows/ci.yml`) risolve il simulatore per *nome* (`PREFERRED_SIMULATOR: iPhone 17 Pro`) senza fissare una versione di runtime. Un iPhone 17 Pro esiste solo su iOS 26+, quindi l'aumento dovrebbe reggere — ma tieni d'occhio la prima CI dopo il push.

**Trappola.** Xcode scrive il deployment target in ogni build configuration separatamente. Cambiarlo sul progetto non lo cambia necessariamente su ogni target — controlla tutte e quattro le occorrenze, non solo le due che ti mostra il Project editor.
