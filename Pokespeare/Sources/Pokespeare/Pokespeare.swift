import Foundation

public struct Pokespeare: Sendable {
  private var _description: @Sendable (_ name: String) async throws -> String
  private var _sprite: @Sendable (_ name: String) async throws -> URL
}

// MARK: - Live Implementation

extension Pokespeare {
  /// The default implementation of the SDK that concretely fetches data from official APIs.
  ///
  /// A single shared instance: building one is cheap but not free, and there is no
  /// per-caller state to keep apart.
  public static let live = Self.live(pokemonManager: .live(), translationManager: .live())

  /// - Parameter isTranslationEnabled: Whether descriptions go through the Shakespearean
  ///   translation step. Defaults to `false` because the FunTranslations endpoint this SDK
  ///   was written against is no longer served; with it off, `description(for:)` returns the
  ///   PokeAPI flavor text verbatim. Turn it on once a translation backend is available
  ///   again — the path stays compiled and covered by tests either way.
  static func live(
    pokemonManager: PokemonManager,
    translationManager: TranslationManager,
    isTranslationEnabled: Bool = false
  ) -> Self {
    .init(
      _description: { name in
        do {
          let description = try await pokemonManager.description(for: name)

          guard isTranslationEnabled else {
            return description
          }

          return try await translationManager.translation(for: description)
        } catch {
          throw Pokespeare.Error.from(error: error)
        }
      },
      _sprite: { name in
        do {
          return try await pokemonManager.sprite(for: name)
        } catch {
          throw Pokespeare.Error.from(error: error)
        }
      }
    )
  }
}

// MARK: - Public Interface

extension Pokespeare {
  /// Function that returns the description of a Pokémon, already translated into Shapespearean style.
  ///
  /// - Parameter pokemon: The name of the Pokémon
  /// - Returns: The description of the Pokémon.
  public func description(for pokemon: String) async throws -> String {
    try await self._description(pokemon)
  }

  /// Function that returns a sprite of a Pokémon for the given name.
  ///
  /// - Parameter pokemon: The name of the Pokémon.
  /// - Returns: The `URL` of the Pokémon's sprite.
  public func sprite(for pokemon: String) async throws -> URL {
    try await self._sprite(pokemon)
  }
}
