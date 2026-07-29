/// The request of the `https://pokeapi.co/api/v2/pokemon/{name}` endpoint.
struct PokemonDetailRequest: HTTPCodableRequest {
  typealias ResponseType = PokemonDetailResponse

  var host = Constants.Host.pokeAPI

  var path: [String] {
    [ "api", "v2", "pokemon", pokemonName ]
  }

  var method = HTTPMethod.get

  /// The name of the Pokémon to fetch the detail of.
  var pokemonName: String
}
