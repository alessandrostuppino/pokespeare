/// The request of the `https://pokeapi.co/api/v2/pokemon-species/{name}` endpoint.
struct PokemonSpeciesRequest: HTTPCodableRequest {
  typealias ResponseType = PokemonSpeciesResponse

  var host = Constants.Host.pokeAPI

  var path: [String] {
    [ "api", "v2", "pokemon-species", pokemonName ]
  }

  var method = HTTPMethod.get

  /// The name of the Pokémon to fetch the species of.
  var pokemonName: String
}
