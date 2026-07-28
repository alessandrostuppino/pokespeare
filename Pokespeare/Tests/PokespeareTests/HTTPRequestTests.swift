import Foundation
import Testing
@testable import Pokespeare

@Suite("HTTP Request Building")
struct HTTPRequestTests {
  @Test func pokemon_detail_request_builds_the_expected_url() throws {
    let request = try #require(PokemonDetailRequest(pokemonName: "pikachu").urlRequest)

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon/pikachu")
    #expect(request.httpMethod == "GET")
  }

  @Test func pokemon_species_request_builds_the_expected_url() throws {
    let request = try #require(PokemonSpeciesRequest(pokemonName: "pikachu").urlRequest)

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon-species/pikachu")
    #expect(request.httpMethod == "GET")
  }

  @Test func default_headers_and_timeout_are_applied() throws {
    let request = try #require(PokemonDetailRequest(pokemonName: "pikachu").urlRequest)

    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(request.timeoutInterval == 30)
  }

  @Test func get_requests_carry_no_body() throws {
    let request = try #require(PokemonDetailRequest(pokemonName: "pikachu").urlRequest)

    #expect(request.httpBody == nil)
  }

  @Test func translation_request_sends_the_text_as_a_query_parameter() throws {
    let request = try #require(ShakespeareanTranslationRequest(text: "Hello there").urlRequest)
    let url = try #require(request.url)
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

    #expect(components.host == "api.funtranslations.com")
    #expect(components.path == "/translate/shakespeare.json")
    #expect(components.queryItems == [URLQueryItem(name: "text", value: "Hello there")])
    #expect(request.httpMethod == "POST")
  }

  /// Documents C-19: the text travels in the query string while the body is filled with an
  /// empty JSON object, so long descriptions risk hitting URL length limits and end up in
  /// server access logs.
  @Test func translation_request_sends_an_empty_json_body() throws {
    let request = try #require(ShakespeareanTranslationRequest(text: "Hello there").urlRequest)

    #expect(request.httpBody == Data("{}".utf8))
  }

  @Test func special_characters_in_the_pokemon_name_are_percent_encoded() throws {
    let request = try #require(PokemonDetailRequest(pokemonName: "mr mime").urlRequest)

    #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon/mr%20mime")
  }
}
