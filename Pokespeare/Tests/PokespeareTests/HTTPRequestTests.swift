import Foundation
import Testing
@testable import Pokespeare

@Suite("HTTP Request Building")
struct HTTPRequestTests {
  @Test func pokemon_detail_request_builds_the_expected_url() throws {
    let request = try PokemonDetailRequest(pokemonName: "pikachu").makeURLRequest()

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon/pikachu")
    #expect(request.httpMethod == "GET")
  }

  @Test func pokemon_species_request_builds_the_expected_url() throws {
    let request = try PokemonSpeciesRequest(pokemonName: "pikachu").makeURLRequest()

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon-species/pikachu")
    #expect(request.httpMethod == "GET")
  }

  @Test func default_headers_and_timeout_are_applied() throws {
    let request = try PokemonDetailRequest(pokemonName: "pikachu").makeURLRequest()

    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(request.timeoutInterval == 30)
  }

  @Test func get_requests_carry_no_body() throws {
    let request = try PokemonDetailRequest(pokemonName: "pikachu").makeURLRequest()

    #expect(request.httpBody == nil)
    #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
  }

  @Test func special_characters_in_the_pokemon_name_are_percent_encoded() throws {
    let request = try PokemonDetailRequest(pokemonName: "mr mime").makeURLRequest()

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon/mr%20mime")
  }

  // MARK: - Translation

  /// Was C-19: the text used to travel in the query string of a POST whose body was a
  /// hardcoded `{}`, risking URL length limits and leaking the text into access logs.
  @Test func translation_request_sends_the_text_in_a_form_body() throws {
    let request = try ShakespeareanTranslationRequest(text: "Hello there").makeURLRequest()

    #expect(request.url?.absoluteString == "https://api.funtranslations.com/translate/shakespeare.json")
    #expect(request.url?.query == nil)
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    #expect(request.httpBody == Data("text=Hello%20there".utf8))
  }

  @Test(arguments: [
    ("a+b", "text=a%2Bb"),
    ("a&b", "text=a%26b"),
    ("a=b", "text=a%3Db"),
    ("Pokémon", "text=Pok%C3%A9mon")
  ])
  func form_bodies_escape_characters_that_would_change_their_meaning(text: String, expected: String) throws {
    let request = try ShakespeareanTranslationRequest(text: text).makeURLRequest()

    #expect(request.httpBody == Data(expected.utf8))
  }

  @Test func form_bodies_encode_deterministically() {
    let body = HTTPRequestBody.form(["b": "2", "a": "1", "c": "3"])

    #expect(body.encoded() == Data("a=1&b=2&c=3".utf8))
  }
}
