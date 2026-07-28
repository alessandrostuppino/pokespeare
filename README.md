# Pokémon in partnership with William Shakespeare

#### Table of Contents
- [Pokespeare](#pokespeare)
  - [The services](#the-services)
    - [Usage example](#usage-example)
    - [Substituting the SDK](#substituting-the-sdk)
  - [The built-in UI Component](#the-built-in-ui-component)
    - [Usage example](#usage-example-1)
  - [SDK structure](#sdk-structure)
  - [Building and testing](#building-and-testing)
- [PokeApp](#pokeapp)
  - [The structure](#the-structure)
  - [Testing the app](#testing-the-app)

The repo contains two main projects:
- **Pokespeare**: A Swift Package with the SDK exposing services and a built-in UI component.
- **PokeApp**: A demo app representing a search engine that uses the SDK services and displays the fetched Pokémon.

## Pokespeare
### The services
The package exposes two services services. Respectively:
```swift
func description(for pokemon: String) async throws -> String
```
Used to retrieve the description for the given Pokémon name. The description is fetched using [PokeAPI](pokeapi.co), optionally translated into Shakespearean style using [FunTranslationsAPI](funtranslations.com/api/shakespeare) and returned by the method.

> [!IMPORTANT]
> The FunTranslations endpoint this SDK was written against is no longer served, so translation is **off by default** and `description(for:)` returns the PokeAPI flavor text verbatim. The translated path is still compiled and covered by tests: turn it on with `Pokespeare.live(pokemonManager:translationManager:isTranslationEnabled: true)` once a translation backend is available again.

```swift
func sprite(for pokemon: String) async throws -> URL
```
Used to retrieve the sprite for the given Pokémon name. The sprite is fetched using [PokeAPI](pokeapi.co) and the `front_default` sprite is used. The method returns the `URL` of the sprite.

Both the services use Swift Concurrency with `async/await` and throw errors of `Pokespeare.Error` kind. `Pokespeare.Error` conforms to `LocalizedError`, so `errorDescription` and `localizedDescription` both carry the message displayed to the user inside the Demo App. Network failures keep their real `URLError` code, so being offline, a timeout and a server failure stay distinguishable. They are accessible through the shared instance of the SDK `Pokespeare.live`.

#### Usage example
```swift
let pokemonName = "pikachu"
let description = try await Pokespeare.live.description(for: pokemonName)
let spriteUrl = try await Pokespeare.live.sprite(for: pokemonName)
```

#### Substituting the SDK
`Pokespeare` is a struct of closures, so tests and previews can replace it without declaring a protocol or maintaining a mock class:

```swift
let sdk = Pokespeare(
  description: { _ in "A description" },
  sprite: { _ in URL(string: "https://example.com/pikachu.png")! }
)
```

### The built-in UI component
The package also provides a built-in UI component named `PokemonView` initialized through the use of its own `PokemonViewModel` which accepts three params:
- `name`: The name of the Pokémon,
- `description`: The Pokémon translated description,
- `spriteUrl`: An optional Pokémon sprite `URL`. If `nil`, a placeholder is displayed.

The component is thought to be presented modally but it is easily embeddable inside whatever custom view. It displays the sprite of the Pokémon, its name and translated description in a vertical layout. The sprite image is rendered through the use of `SwiftUI.AsyncImage` that accepts an optional url and fallbacks on a custom placeholder.

#### Usage example
```swift
PokemonView(
    viewModel: PokemonViewModel(
      name: "Pikachu",
      description: "Pikachu stores electricity in its cheeks and discharges 't at which hour 't doth feel threatened.",
      spriteUrl: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png")
    )
  )
```

### SDK structure
The package project structure is organized into `UI`, `Core` and the main file `Pokespeare.swift`.

The `UI` folder contains the previously described built-in UI component and view model.

The `Core` folder contains logic and models useful to allow the SDK working properly.
The logic is divided between:
- `APIClient`, the single place where an `HTTPCodableRequest` becomes a decoded response: it builds the request, validates the status code, decodes the body and turns every failure into a typed `APIError`. Endpoint-specific status codes (404 for PokeAPI, 429 for FunTranslations) are passed in as a `statusCodeMapper`, so the transport is not duplicated per manager.
- `PokemonManager` which exposes the methods invoking the endpoints related to PokeAPI.
- `TranslationManager` which exposes the method dealing with the text translation using FunTranslationsAPI.

Both managers hold domain logic only; transport failures leave them as `APIError`. `Pokespeare.Error.from(error:)` is the single boundary that maps everything onto the public error surface.

The `Pokespeare.swift` file is the one containing the exposed services and the same that directly deals with `PokemonManager` and `TranslationManager`.

Everything below the public surface — the HTTP request protocols, `HTTPMethod`, the request and response models — is `internal`. The public API is `Pokespeare`, `Pokespeare.Error`, `PokemonView` and `PokemonViewModel`.

The SDK also contains `Tests` with specific tests for the request building, the error pipeline, `PokemonManager`, `TranslationManager` and `Pokespeare` itself. These include unit tests with mocked session and integration tests invoking real APIs.

> [!NOTE]
> The integration tests hit live third-party APIs behind a rate limit of 5 calls per hour and 60 per day, and FunTranslations is no longer reachable. They are tagged `.integration` and skipped unless `RUN_INTEGRATION_TESTS` is set, so the default suite stays deterministic.

### Building and testing
The package declares only `.iOS(.v17)`, so `swift build` and `swift test` do not work on macOS: everything goes through `xcodebuild` against a simulator.

```bash
cd Pokespeare && xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

To include the integration suite:

```bash
cd Pokespeare && RUN_INTEGRATION_TESTS=1 xcodebuild test -scheme Pokespeare -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Linting uses SwiftLint with the configuration at the repository root:

```bash
swiftlint lint --strict
```

CI runs all three on every push to `master` and every pull request.

---

## PokeApp
The demo app is a single-view application that gives the possibility to search for a Pokémon through the name, view its details and save it in a list containing recent searches. The list acts as an history and is useful to revisit the detail of Pokémon already displayed without the use of further network calls.

The history is kept alive through the use of `SwiftData`, keyed on the Pokémon name: searching one that is already in the history reuses the stored entry and makes no network call.

### The structure
Keeping in mind that it is a single-view application, the project structure is very simple.

It is based on MVVM architectural pattern and contains the folders `Models` and `View`. The first contains the model of the stored Pokémon. The second contains a folder for the search view (`Search`) where the view and view model definitions can be found, and another folder (`Helpers`) which hosts the UI helpers, in my case a `SwiftUI.ViewModifier` usefull tu add a clear button to a `SwiftUI.TextField`.

`SearchViewModel` is `@MainActor` and takes both its `ModelContext` and its `Pokespeare` instance as constructor dependencies, wired in `PokeApp.swift`. The two PokeAPI calls of a search run concurrently with `async let`, and starting a new search cancels the previous one so a slower older result cannot overwrite a newer one.

The app target builds in Swift 6 language mode.

### Testing the app

```bash
xcodebuild test -project Demo/PokeApp.xcodeproj -scheme PokeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`PokeAppTests` covers the search happy path, error surfacing, cancellation, and the history.

> [!NOTE]
> Tests build their SwiftData stores as throwaway files rather than with `isStoredInMemoryOnly`: on the current toolchain (Xcode 26.4 / iOS 26.4) any `fetch` against an in-memory container traps inside SwiftData.
