import Foundation
import Testing
@testable import Pokespeare

@Suite("Pokemon Manager")
struct PokemonManagerTests {
  @Suite("Unit Tests")
  struct UnitTests {
    @Test func sprite_ok() async throws {
      let urlString = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
      let url = URL(string: urlString)
      let result = try await PokemonManager.live(session: MockedSession.pokemonSpriteSession(with: urlString)).sprite(for: "pikachu")

      #expect(result == url)
    }

    @Test func description_ok() async throws {
      let expected = "When several of these POKéMON gather, their electricity could build and cause lightning storms."
      let manager = PokemonManager.live(session: MockedSession.pokemonDescriptionSession(with: expected))
      let result = try await manager.description(for: "pikachu")

      #expect(result == expected)
    }
  }

  @Suite(
    "Integration Tests",
    .tags(.integration),
    .disabled(if: !IntegrationTests.isEnabled, IntegrationTests.skipReason)
  )
  struct LiveAPITests {
    @Test func sprite_integration() async throws {
      let expected = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png")
      let sprite = try await PokemonManager.live().sprite(for: "pikachu")
      #expect(sprite == expected)
    }

    @Test func description_integration() async throws {
      let expected = "When several of these POKéMON gather, their electricity could build and cause lightning storms."
      let description = try await PokemonManager.live().description(for: "pikachu")
      #expect(description == expected)
    }
  }
}

extension MockedSession {
  static func pokemonSpriteSession(with urlString: String) -> MockedSession {
    let pokemon = PokemonDetailResponse(sprite: urlString)

    return .init { _ in
      (
        try! JSONEncoder().encode(pokemon),
        HTTPURLResponse(url: URL(string: "about:blank")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      )
    }
  }

  static func pokemonDescriptionSession(with description: String) -> MockedSession {
    let pokemon = PokemonSpeciesResponse(
      flavorTextEntries: [
        .init(
          flavorText: description,
          language: "en"
        )
      ]
    )

    return .init { _ in
        (
          try! JSONEncoder().encode(pokemon),
          HTTPURLResponse(url: URL(string: "about:blank")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
    }
  }
}
