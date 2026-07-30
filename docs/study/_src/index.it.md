# Programma di studio Swift — WWDC22 → WWDC25

Un ripasso strutturato del linguaggio Swift e delle API delle piattaforme Apple uscite tra WWDC22 e WWDC25, insegnato su un codebase reale: questo.

L'obiettivo non è la familiarità. L'obiettivo è saper scegliere lo strumento giusto senza doverlo cercare, capire cosa fanno davvero compilatore e runtime sotto il cofano, e poi applicarlo qui come modifica reale.

---

## Come è costruito questo programma

**Quattro batch, uno per anno WWDC**, più queste fondamenta. Ogni batch viene scritto solo dopo che il precedente è stato studiato e i suoi esercizi implementati, così il materiale successivo può adattarsi a ciò che hai davvero costruito.

| Batch | Anno | Swift | OS | Stato |
|---|---|---|---|---|
| 0 | — | — | — | ✅ scritto |
| 1 | WWDC22 | 5.7 | iOS 16 | ✅ [scritto](wwdc22/README.md) — 6 moduli |
| 2 | WWDC23 | 5.9 | iOS 17 | ⏳ dopo il Batch 1 |
| 3 | WWDC24 | 6.0 | iOS 18 | ⏳ dopo il Batch 2 |
| 4 | WWDC25 | 6.2 | iOS 26 | ⏳ dopo il Batch 3 |

### Documenti di base

| File | Cos'è |
|---|---|
| [Mappa delle versioni](00-version-map.md) | La tabella di consultazione: anno WWDC ↔ Swift ↔ Xcode ↔ OS, con l'elenco completo delle proposte di linguaggio uscite in ogni versione. Da consultare ogni volta che ti chiedi "posso già usarlo?" |
| [Punto di partenza](00-baseline.md) | Un inventario onesto di ciò che questo codebase già fa bene, ciò che fa alla vecchia maniera, e il piano a tappe per i deployment target |
| [Protocollo di revisione](review-protocol.md) | Cosa succede alla fine di ogni batch: come si attiva la revisione, cosa viene controllato e cosa ti viene restituito |

---

## Due regole che questo programma rispetta

**1. Ogni affermazione ha una fonte.** Niente qui è scritto a memoria. Le funzionalità del linguaggio sono ancorate alla loro proposta [Swift Evolution](https://www.swift.org/swift-evolution/) e verificate contro la [dashboard ufficiale](https://download.swift.org/swift-evolution/v1/evolution.json), che registra esattamente in quale release Swift ogni proposta è arrivata. Le API dei framework sono ancorate alla documentazione Apple. Dove qualcosa viene da una fonte non Apple, è etichettato come tale.

**2. Il codice lo scrivi tu.** Questi documenti contengono Swift solo come frammenti didattici in blocchi di codice. Niente qui viene applicato a `Pokespeare/` o `Demo/` — ogni implementazione è tua. Ed è il punto: leggere di `sending` non insegna nulla, litigarci col compilatore per venti minuti insegna per sempre.

---

## Struttura dei documenti

Ogni modulo segue la stessa forma in sette parti:

1. **Cosa è uscito, e quale problema risolve** — la motivazione, prima della sintassi.
2. **Come funziona davvero** — cosa emette il compilatore e cosa fa il runtime. Existential box e witness table, fasi di espansione delle macro, dove finisce davvero un punto di sospensione, perché la region-based isolation è una prova a compile-time e non un controllo a runtime.
3. **Fonti ufficiali** — link verificati e numeri SE.
4. **Dove atterra in questo codebase** — riferimenti concreti `file:riga`, o al codice che lo fa alla vecchia maniera, o al buco dove dovrebbe stare.
5. **Esercizio** — un compito che implementi tu, con criteri di accettazione e comando di verifica.
6. **Trappole** — gli inciampi, inclusi quelli in cui questo progetto è già caduto (vedi `HANDOFF.md` e i finding C-01…C-25 dell'audit).
7. **Autovalutazione** — domande a cui è scomodo rispondere se hai solo scorso il testo.

---

## Il ciclo di studio

Per ogni modulo:

1. **Leggi** il documento da cima a fondo prima di toccare Xcode. Le sezioni 1 e 2 sono la parte che conta; la sintassi è la metà facile.
2. **Rispondi all'autovalutazione** a memoria. Se una domanda è scomoda, rileggi la sezione 2 invece di andare avanti.
3. **Implementa** l'esercizio su un branch — un branch per modulo tiene i diff leggibili e reversibili.
4. **Verifica** — i criteri di accettazione del modulo, più l'intera suite esistente che resta verde (vedi sotto).
5. **Committa**, poi passa al modulo successivo.

Ogni batch si chiude anche con un modulo di **Sfide di implementazione**: feature abbastanza grandi da costringerti a re-implementare da zero la tecnologia WWDC che il progetto già contiene. Leggere `RetryPolicy.swift` e pensare "sì, `Duration`, chiaro" non è la stessa cosa che progettare un nuovo manager e scoprire da solo dove `Sendable` morde.

### Fine del batch

Quando **tu** decidi che un batch è finito, dillo — non c'è nulla di automatico e non vieni mai interrotto a metà. A quel punto leggo ogni diff, eseguo l'intera suite, controllo le invarianti del progetto e sondo la teoria. Ti torna indietro cosa è corretto, cosa è sbagliato con lo scenario di fallimento esplicitato, e quali concetti sono solidi, incerti o non ancora acquisiti.

Dettagli completi, incluso cosa preparare: **[Protocollo di revisione](review-protocol.md)**.

### Comandi di verifica

Il package dichiara solo una piattaforma iOS, quindi tutto passa da `xcodebuild` — `swift test` non funziona. Coincide con la CI (`.github/workflows/ci.yml`).

Test dell'SDK:

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Test dell'app:

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Lint, esattamente come lo esegue la CI:

```bash
swiftlint lint --strict
```

**L'asticella anti-regressione:** 53 test SDK + 18 test app devono restare verdi, e SwiftLint pulito, dopo ogni esercizio. Lascia `RUN_INTEGRATION_TESTS` non impostata — quei test colpiscono API di terze parti dietro un rate limit.

---

## Perimetro

**Dentro:** WWDC22, WWDC23, WWDC24, WWDC25 — il linguaggio Swift, SwiftUI, SwiftData, Swift Testing, Swift Charts, WidgetKit, App Intents, Foundation Models e la toolchain attorno (SwiftPM, Xcode, Instruments).

**Fuori:** WWDC26 / iOS 27 / Xcode 27. Escluso deliberatamente — i quattro anni richiesti sono dal 22 al 25.

Swift 6.3 è successivo a WWDC25 ma è quello installato su questa macchina. Riceve una breve nota in appendice nel Batch 4, non un modulo suo.

---

## Prerequisiti

Verificati presenti su questa macchina:

- Xcode **26.4.1** (build 17E202)
- Swift **6.3.1**
- SDK iOS **26.4**
- Runtime simulatore: iOS **18.6** e **26.4**

Tutto ciò che va da WWDC22 a WWDC25 compila qui, oggi.
