import Foundation

/// The response of the `https://pokeapi.co/api/v2/pokemon/{name}` endpoint.
struct PokemonDetailResponse: Codable {
  enum CodingKeys: String, CodingKey {
    case sprite = "sprites"
  }

  enum SpriteCodingKeys: String, CodingKey {
    case frontDefault = "front_default"
  }

  /// The string url of the front default sprite.
  let sprite: String

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let spriteContainer = try container.nestedContainer(keyedBy: SpriteCodingKeys.self, forKey: .sprite)
    self.sprite = try spriteContainer.decode(String.self, forKey: .frontDefault)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var spriteContainer = container.nestedContainer(keyedBy: SpriteCodingKeys.self, forKey: .sprite)
    try spriteContainer.encode(sprite, forKey: .frontDefault)
  }

  internal init(sprite: String) {
    self.sprite = sprite
  }
}
