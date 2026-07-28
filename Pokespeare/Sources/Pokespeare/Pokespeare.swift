import Foundation

public struct Pokespeare: Sendable {
  private var _description: @Sendable (_ name: String) async throws -> String
  private var _sprite: @Sendable (_ name: String) async throws -> URL
}

// MARK: - Live Implementation

extension Pokespeare {
  /// The default implementation of the SDK that concretely fetches data from official APIs.
  public static var live: Self {
    self.live(pokemonManager: .live(), translationManager: .live())
  }

  static func live(pokemonManager: PokemonManager, translationManager: TranslationManager) -> Self {
    .init(
      _description: { name in
        do {
          guard let description = try await pokemonManager.description(for: name) else {
            throw Pokespeare.Error.pokemonNotFound
          }

//					return try await translationManager.translation(for: description)
          return description
        } catch {
          throw Pokespeare.Error.from(error: error)
        }
      },
      _sprite: { name in
        do {
          guard let url = try await pokemonManager.sprite(for: name) else {
            throw Pokespeare.Error.spriteUnavailable
          }

          return url
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
