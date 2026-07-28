import Foundation

/// The view model populating the view.
public struct PokemonViewModel {
  /// The name of the Pokémon used to fetch its sprite and description.
  let name: String

  /// The description of the Pokémon.
  let description: String

  /// The URL used to load the sprite of the Pokémon.
  let spriteUrl: URL?

  public init(name: String, description: String, spriteUrl: URL?) {
    self.name = name
    self.description = description
    self.spriteUrl = spriteUrl
  }
}
