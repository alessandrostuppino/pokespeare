import Foundation

/// The response of the `https://pokeapi.co/api/v2/pokemon-species/{name}` endpoint.
struct PokemonSpeciesResponse: Codable {
  enum CodingKeys: String, CodingKey {
		case flavorTextEntries = "flavor_text_entries"
	}
	
	/// The list of descriptions of the Pokémon for each `language`.
	let flavorTextEntries: [FlavorTextEntry]
  
  internal init(flavorTextEntries: [FlavorTextEntry]) {
    self.flavorTextEntries = flavorTextEntries
  }
}

extension PokemonSpeciesResponse {
	/// A type representing the description of a Pokémon for a specific `language`.
  struct FlavorTextEntry: Codable {
    enum CodingKeys: String, CodingKey {
			case flavorText = "flavor_text"
			case language
		}
		
		enum LanguageCodingKeys: CodingKey {
			case name
		}
		
		/// The description of the Pokémon.
		let flavorText: String
		
		/// The language of the description.
		let language: String
		
		init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.flavorText = try container.decode(String.self, forKey: .flavorText)
			
			let languageContainer = try container.nestedContainer(keyedBy: LanguageCodingKeys.self, forKey: .language)
			self.language = try languageContainer.decode(String.self, forKey: .name)
		}
    
    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(flavorText, forKey: .flavorText)
      var languageContainer = container.nestedContainer(keyedBy: LanguageCodingKeys.self, forKey: .language)
      try languageContainer.encode(language, forKey: .name)
    }
    
    internal init(flavorText: String, language: String) {
      self.flavorText = flavorText
      self.language = language
    }
	}
}
