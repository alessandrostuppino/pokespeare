import Foundation
import Testing
@testable import Pokespeare

@Suite("Pokespeare SDK")
struct PokespeareTests {
  @Test func pokemon_not_found() async throws {
    let urlError = PokemonManager.Error.pokemonNotFound
    let sdk = Pokespeare.live(
      pokemonManager: PokemonManager.live(session: MockedSession.failureSession(with: urlError)),
      translationManager: TranslationManager.live(session: MockedSession.unimplemented())
    )
    
    await #expect(throws: Pokespeare.Error.pokemonNotFound) {
      _ = try await sdk.description(for: "picatchu")
    }
  }
  
  @Suite("Description Service")
  struct DescriptionTests {
    @Test func happy_path() async throws {
      let expected = "At which hour several of these pokémon gather, their electricity couldst buildeth and cause lightning storms."
      let sdk = Pokespeare.live(
        pokemonManager: PokemonManager.live(session: MockedSession.pokemonDescriptionSession(with: expected)),
        translationManager: TranslationManager.live(session: MockedSession.translationSuccessSession(with: expected))
      )
      
      let result = try await sdk.description(for: "pikachu")
      
      #expect(result == expected)
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
