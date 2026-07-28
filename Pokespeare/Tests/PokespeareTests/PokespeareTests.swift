import Foundation
import Testing
@testable import Pokespeare

@Suite("Pokespeare SDK")
struct PokespeareTests {
  @Test func pokemon_not_found() async throws {
    let sdk = Pokespeare.live(
      pokemonManager: PokemonManager.live(session: MockedSession.responding(statusCode: 404)),
      translationManager: TranslationManager.live(session: MockedSession.unimplemented())
    )

    await #expect(throws: Pokespeare.Error.pokemonNotFound) {
      _ = try await sdk.description(for: "picatchu")
    }
  }

  @Suite("Description Service")
  struct DescriptionTests {
    /// Translation is off by default: the PokeAPI flavor text comes back verbatim, and the
    /// translation service is never called.
    @Test func returns_the_untranslated_description_by_default() async throws {
      let expected = "When several of these POKéMON gather, their electricity could build and cause lightning storms."
      let sdk = Pokespeare.live(
        pokemonManager: PokemonManager.live(session: MockedSession.pokemonDescriptionSession(with: expected)),
        translationManager: TranslationManager.live(session: MockedSession.unimplemented())
      )

      #expect(try await sdk.description(for: "pikachu") == expected)
    }

    @Test func routes_through_the_translation_service_when_enabled() async throws {
      let original = "When several of these POKéMON gather, their electricity could build and cause lightning storms."
      let translated = "At which hour several of these pokémon gather, their electricity couldst buildeth and cause lightning storms."
      let sdk = Pokespeare.live(
        pokemonManager: PokemonManager.live(session: MockedSession.pokemonDescriptionSession(with: original)),
        translationManager: TranslationManager.live(session: MockedSession.translationSuccessSession(with: translated)),
        isTranslationEnabled: true
      )

      #expect(try await sdk.description(for: "pikachu") == translated)
    }

    @Test func translation_rate_limit_reaches_the_caller() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: PokemonManager.live(session: MockedSession.pokemonDescriptionSession(with: "A description")),
        translationManager: TranslationManager.live(session: MockedSession.responding(statusCode: 429)),
        isTranslationEnabled: true
      )

      await #expect(throws: Pokespeare.Error.rateLimitExceeded) {
        _ = try await sdk.description(for: "pikachu")
      }
    }
  }

  @Suite("Sprite Service")
  struct SpriteTests {
    @Test func happy_path() async throws {
      let urlString = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
      let expected = URL(string: urlString)
      let sdk = Pokespeare.live(
        pokemonManager: PokemonManager.live(session: MockedSession.pokemonSpriteSession(with: urlString)),
        translationManager: TranslationManager.live(session: MockedSession.unimplemented())
      )

      let spriteUrl = try await sdk.sprite(for: "pikachu")

      #expect(spriteUrl == expected)
    }
  }
}
