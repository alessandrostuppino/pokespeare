# Pokémon in partnership with William Shakespeare

#### Table of Contents
- [Pokespeare](#pokespeare)
  - [The services](#the-services)
    - [Usage example](#usage-example)
  - [The built-in UI Component](#the-built-in-ui-component)
    - [Usage example](#usage-example-1)
  - [SDK structure](#sdk-structure)
- [PokeApp](#pokeapp)
  - [The structure](#the-structure) 

The repo contains two main projects:
- **Pokespeare**: A Swift Package with the SDK exposing services and a built-in UI component.
- **PokeApp**: A demo app representing a search engine that uses the SDK services and displays the fetched Pokémon.

## Pokespeare
### The services
The package exposes two services services. Respectively:
```swift
func description(for pokemon: String) async throws -> String
```
Used to retrieve the description for the given Pokémon name. The description is fetched using [PokeAPI](pokeapi.co), translated into Shakespearean style using [FunTranslationsAPI](funtranslations.com/api/shakespeare) and returned by the method.

```swift
func sprite(for pokemon: String) async throws -> URL
```
Used to retrieve the sprite for the given Pokémon name. The sprite is fetched using [PokeAPI](pokeapi.co) and the `front_default` sprite is used. The method returns the `URL` of the sprite.

Both the services use Swift Concurrency with `async/await` and throw errors of `Pokespeare.Error` kind which provide an `errorDescription` displayed to the user inside the Demo App. They are accessible through the static instance of the SDK `Pokespeare.live`.

#### Usage example
```swift
let pokemonName = "pikachu"
let description = try await Pokespeare.live.description(for: pokemonName)
let spriteUrl = try await Pokespeare.live.sprite(for: pokemonName)
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
- `PokemonManager` which exposes the methods invoking the endpoints related to PokeAPI.
- `TranslationManager` which exposes the method dealing with the text translation using FunTranslationsAPI.

The `Pokespeare.swift` file is the one containing the exposed services and the same that directly deals with `PokemonManager` and `TranslationManager`.

The SDK also contains `Tests` with specific tests for `PokemonManager`, `TranslationManager` and `Pokespeare` itself. These include unit tests with mocked session and integration tests invoking real APIs.

> [!NOTE]  
> The integration tests could fail if ran multiple times due to API rate limit which allows 5 calls per hour and 60 calls per day.

---

## PokeApp
The demo app is a single-view application that gives the possibility to search for a Pokémon through the name, view its details and save it in a list containing recent searches. The list acts as an history and is useful to revisit the detail of Pokémon already displayed without the use of further network calls.

The history is kept alive through the use of `SwiftData`.

### The structure
Keeping in mind that it is a single-view application, the project structure is very simple.

It is based on MVVM architectural pattern and contains the folders `Models` and `View`. The first contains the model of the stored Pokémon. The second contains a folder for the search view (`Search`) where the view and view model definitions can be found, and another folder (`Helpers`) which hosts the UI helpers, in my case a `SwiftUI.ViewModifier` usefull tu add a clear button to a `SwiftUI.TextField`.
