import Foundation

struct PokemonManager: Sendable {
  /// The domain failures of the PokeAPI endpoints.
  ///
  /// Transport failures are not represented here: they leave the manager as ``APIError``,
  /// so a missing description is never confused with a server being down.
  enum Error: Swift.Error, Equatable {
    /// No Pokémon exists with the requested name.
    case pokemonNotFound

    /// The Pokémon exists but the species carries no description at all.
    case descriptionUnavailable(String)

    /// The Pokémon has descriptions, but none in the default language.
    case englishDescriptionUnavailable(String)

    /// The Pokémon exists but has no usable sprite URL.
    case spriteUnavailable
  }

  private var _description: @Sendable (String) async throws -> String
  private var _sprite: @Sendable (String) async throws -> URL

  func sprite(for pokemon: String) async throws -> URL {
    try await self._sprite(pokemon)
  }

  func description(for pokemon: String) async throws -> String {
    try await self._description(pokemon)
  }
}

// MARK: - Live Implementation

extension PokemonManager {
  static func live(session: any Session = URLSession.shared) -> Self {
    let client = APIClient(session: session) { statusCode in
      statusCode == 404 ? Error.pokemonNotFound : nil
    }

    return .init(
      _description: { pokemon in
        let response = try await client.perform(PokemonSpeciesRequest(pokemonName: pokemon))

        guard !response.flavorTextEntries.isEmpty else {
          throw Error.descriptionUnavailable(pokemon)
        }

        guard let entry = response.flavorTextEntries.first(where: { $0.language == defaultLanguage }) else {
          throw Error.englishDescriptionUnavailable(pokemon)
        }

        return entry.flavorText.normalizedFlavorText
      },
      _sprite: { pokemon in
        let response = try await client.perform(PokemonDetailRequest(pokemonName: pokemon))

        guard let url = URL(string: response.sprite) else {
          throw Error.spriteUnavailable
        }

        return url
      }
    )
  }
}

private extension String {
  /// PokeAPI wraps flavor text to a fixed width using newlines and form feeds.
  var normalizedFlavorText: String {
    replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\u{c}", with: " ")
  }
}
