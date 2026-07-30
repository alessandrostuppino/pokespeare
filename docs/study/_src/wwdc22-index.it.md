# Batch 1 — WWDC22 · Swift 5.7 · iOS 16

L'anno in cui i generics di Swift sono diventati usabili, le espressioni regolari sono arrivate native e SwiftUI ha sostituito `NavigationView` con qualcosa di guidato dai dati.

**32 proposte di linguaggio uscite in Swift 5.7.** Questo batch copre quelle che hanno cambiato il modo di scrivere codice quotidiano, più i quattro framework che hanno debuttato insieme a loro.

---

## Moduli

| # | Modulo | Argomento centrale | Dimensione esercizio |
|---|---|---|---|
| 1 | [Generics ed existentials](01-generics-and-existentials.md) | `any` vs `some`, primary associated type, layout dell'existential container | Medio |
| 2 | [Regex ed elaborazione di stringhe](02-regex-and-string-processing.md) | `Regex`, literal, `RegexBuilder`, algoritmi su stringhe | Piccolo |
| 3 | [Fondamenta di concorrenza](03-concurrency-foundations.md) | `Sendable`, livelli di checking, semantica di esecuzione SE-0338, `Clock`/`Duration` | Medio |
| 4 | [Navigazione e layout in SwiftUI](04-swiftui-navigation-and-layout.md) | `NavigationStack`, `navigationDestination`, `Layout`, `ViewThatFits` | Grande |
| 5 | [Debutti di piattaforma](05-platform-debuts.md) | App Intents, Swift Charts, widget da lock screen, `Transferable` | Scegline uno |
| 6 | [Sfide di implementazione](06-build-challenges.md) | Re-implementa la tecnologia WWDC22 che il progetto già usa, costruendo feature reali | Da una a tre |

**Ordine consigliato: 1 → 2 → 3 → 4 → 5 → 6.** Il Modulo 4 non dipende da nulla, ma l'esercizio grande del Modulo 5 e le Sfide B e C del Modulo 6 consumano tutti il lavoro di navigazione del Modulo 4 — non partire da quelli.

I Moduli 1 e 3 sono quelli densi di teoria. Nei Moduli 2, 4 e 5 scrivi più codice. **Il Modulo 6 è dove si dimostra**: tre feature contro endpoint PokéAPI reali — catene evolutive, efficacia dei tipi, filtri di ricerca — dimensionate in modo che tu non possa completarle senza ricostruire da solo la disciplina `Sendable`, il confine degli errori, la regola del transport unico e la gestione di `Duration` che l'SDK già dimostra.

---

## Cosa cambia questo batch nel progetto

Se fai tutti gli esercizi, alla fine del batch il progetto ha:

- Un validatore di nomi basato su regex e testato, al posto del numero magico `searchText.count > 2` (finding **C-20**) — *Modulo 2*
- Un clock iniettabile in `APIClient`, che rende il backoff dei retry testabile senza dormire davvero, e una suite più veloce — *Modulo 3*
- Navigazione vera al posto del dettaglio presentato come sheet, con lo stato di navigazione testato come dato — *Modulo 4*
- Righe della cronologia che sopravvivono alle dimensioni di testo accessibili, tramite `ViewThatFits` — *Modulo 4*
- La condivisione, oppure un App Intent più un widget da lock screen — *Modulo 5*
- Almeno un nuovo servizio SDK costruito end-to-end — request, modello di risposta, manager, mappatura degli errori, test — *Modulo 6*

I Moduli 1 e 3 producono anche analisi scritta, non solo codice. Conserva quelle note — il Batch 3 ci costruisce sopra direttamente.

---

## Due cose da sapere prima di iniziare

**Ogni frammento di questo batch è stato compilato.** Non ricordato: verificato col typechecker contro l'SDK iOS 26.4 in Swift 6 language mode prima di essere scritto. Dove un frammento è mostrato come fallito, quel testo d'errore è output reale del compilatore.

**Una scoperta è uscita da quel processo** e vale la pena segnalarla subito, perché altrimenti ti costa venti minuti: **`Regex` non è `Sendable`.** Un `let` globale che ne contiene uno si prende `@MainActor` inferito, e l'errore compare solo quando codice `nonisolated` lo tocca — che in questo progetto significa tutto l'SDK. Il Modulo 2 lo copre, con entrambi i fix.

---

## Verifica

Ogni esercizio finisce alla stessa asticella: **tutti i 71 test verdi** (53 SDK + 18 app), SwiftLint pulito.

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
swiftlint lint --strict
```

Lascia `RUN_INTEGRATION_TESTS` non impostata — quelli colpiscono API reali con rate limit.

---

## Quando hai finito

Di' **"batch finito"** e parte la revisione. Non c'è nulla di automatico — decidi tu quando.

Tieni pronti: il lavoro committato e una nota breve per modulo su cosa hai costruito, cosa hai deciso di **non** fare, cosa non hai finito e quali domande di autovalutazione ti hanno messo a disagio. Le scelte di giudizio nel Modulo 4 (§5a), Modulo 2 (§6a) e Modulo 6 (A1) sono valutate sul ragionamento, non sul diff.

Vedi il [Protocollo di revisione](review-protocol.md) per sapere esattamente cosa viene controllato e cosa ricevi indietro. Il Batch 2 (WWDC23: macro, interni di Observation, SwiftData in profondità) viene poi adattato in base a cosa è davvero atterrato e dove la teoria era incerta.
