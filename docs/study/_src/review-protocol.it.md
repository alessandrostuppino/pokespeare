# Protocollo di revisione di fine batch

Ogni batch si chiude con una revisione. **Decidi tu quando.** Di' *"batch finito"* e la revisione parte. Non succede nulla in automatico — non vieni mai interrotto a metà batch.

Questa pagina descrive esattamente cosa accade, così nulla della valutazione ti coglie di sorpresa.

---

## Cosa fai prima

Prima di dire che il batch è finito, prepara queste cose. Due minuti di preparazione rendono la revisione molto più utile:

1. **Il lavoro committato** — idealmente un branch o un commit per modulo, così i diff si leggono puliti.
2. **Una nota breve per modulo** che risponda a:
    - Cosa hai costruito?
    - Cosa hai deciso di **non** fare, e perché?
    - Cosa non hai finito, e cosa ti ha bloccato?
    - Quali domande di autovalutazione ti hanno messo a disagio?
3. **Numero di test e durata della suite, attuali.** Di' com'era e com'è adesso.

Il punto 2 è il più importante. Gli esercizi contengono deliberatamente scelte di giudizio senza una risposta unica — il Modulo 4 §5a (sheet o navigazione) e il Modulo 2 §6a (SDK o app) sono entrambi così. **Il ragionamento è l'artefatto valutato, non il diff.**

Se qualcosa è a metà, dillo. Un onesto "non ho capito abbastanza la region-based isolation per provarci" mi è più utile di un copia-incolla funzionante, e cambia il contenuto del batch successivo.

---

## Cosa faccio io

### 1. Leggo il codice

`git diff` rispetto al punto di partenza del batch, ogni file. Non a campione.

### 2. Eseguo tutto

```bash
xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
swiftlint lint --strict
```

Riporto quello che è successo davvero. Se i test falliscono ricevi l'output del fallimento, non un riassunto.

### 3. Controllo le invarianti del progetto

L'audit che ha prodotto i finding C-01…C-25 ha stabilito regole secondo cui questo codebase ora vive. Ogni revisione le controlla, perché far regredire una è peggio che non aver tentato un esercizio:

| Invariante | Origine |
|---|---|
| `APIClient` è l'unico transport | C-03 |
| Ogni fallimento termina in `Pokespeare.Error`; ordinamento di `from(error:)` intatto | C-01, C-25 |
| Nessun `Optional` usato come canale d'errore | C-05 |
| La superficie pubblica resta deliberata | C-17 |
| Nessuna assertion dentro `catch` | C-10 |
| Test di integrazione dietro `RUN_INTEGRATION_TESTS` | C-11 |
| Nessun UIKit nei view model | C-16 |
| Stringhe utente localizzate in **entrambi** i cataloghi | C-21 |
| Label VoiceOver e Dynamic Type rispettati | C-23 |
| Nessun `@unchecked Sendable` in codice di produzione | C-02 |

### 4. Sondo la teoria

Questa è la parte che non riguarda il codice. Per ogni modulo scelgo i concetti su cui il batch è davvero costruito e ti chiedo di spiegarli — di solito partendo dalle domande di autovalutazione, a volte con una variante pensata per smascherare una risposta imparata a memoria.

Una feature può funzionare per il motivo sbagliato. Codice che compila in Swift 6 mode perché hai cosparso `@MainActor` finché gli errori non sono spariti non è la stessa cosa di codice correttamente isolato, e la differenza non emerge da un run di test. Emerge qui.

---

## Cosa ricevi indietro

### Per modulo

- **Costruito** — cosa è atterrato, in modo fattuale.
- **Corretto** — cosa è giusto, nello specifico, con `file:riga`. Non incoraggiamento: le parti che vale la pena tenere e ripetere.
- **Sbagliato** — i difetti, con lo scenario di fallimento esplicitato: dato questo input succede questo, e dovrebbe succedere quest'altro.
- **Lacune teoriche** — dove il codice rivela un fraintendimento e non una svista. È la sezione che guida il batch successivo.
- **Deviazioni** — dove ti sei allontanato dai pattern del progetto, e se la deviazione è difendibile. A volte la tua è migliore di quella che c'era. In quel caso lo dico.

### Complessivo

- Un giudizio su quanto i concetti centrali del batch siano **solidi**, **incerti** o **non ancora acquisiti** — per concetto, non un voto unico. "Solido su `Sendable`, incerto sul costo degli existential, non ancora acquisita la semantica di esecuzione SE-0338" è una frase utile; "7/10" no.
- **Cosa rileggere**, puntato a sezioni specifiche e non a moduli interi.
- **Cosa cambia nel batch successivo** di conseguenza — materiale in più dove sei incerto, materiale saltato dove è chiaro che sei già oltre.

### Le due regole che mi impongo

**Nessuna lode gonfiata.** Se qualcosa è sbagliato te lo dico chiaramente, una volta, con la motivazione. Se è giusto lo dico altrettanto — ma un "ottimo lavoro" senza nulla di specifico attaccato è rumore, e svaluta la lode genuina.

**Nessun problema inventato.** Se un modulo è venuto pulito, il report dice pulito. Fabbricare un appunto per sembrare scrupoloso spreca il tuo tempo e il mio.

---

## Nuova revisione

Sistema le cose e di' *"rivedi di nuovo"* — ricevi un passaggio mirato solo sulle parti cambiate, non l'intero batch da capo.

Un concetto che torna **incerto** due volte riceve materiale aggiuntivo nel batch successivo, invece di una terza ripetizione della stessa spiegazione. Se una spiegazione non arriva, il problema è la spiegazione.

---

## Cosa non è

- Non è un cancello. Puoi iniziare il batch successivo quando vuoi; la revisione è un checkpoint, non un lucchetto.
- Non è una code review dell'intero repository. Solo ciò che il batch ha toccato, più le invarianti qui sopra.
- Non è un servizio di riscrittura. Io indico il difetto e il ragionamento; tu lo sistemi. È esattamente il senso dell'accordo — il codice resta tuo.
