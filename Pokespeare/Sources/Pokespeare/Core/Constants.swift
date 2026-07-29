import Foundation

/// The SDK-wide constants, namespaced so they do not sit at module scope.
enum Constants {
  /// The language used when the user's own is not available.
  static let fallbackLanguage = "en"

  /// The languages to look for in a Pokémon description, most preferred first.
  ///
  /// PokeAPI keys its flavor text by language code, so an italian device gets the italian
  /// description when there is one instead of always falling back to english.
  static var preferredLanguages: [String] {
    guard
      let language = Locale.current.language.languageCode?.identifier,
      language != fallbackLanguage
    else {
      return [fallbackLanguage]
    }

    return [language, fallbackLanguage]
  }

  /// The time a request is given before it fails.
  static let requestTimeout: TimeInterval = 30

  enum Host {
    /// The base URL for PokeAPI services.
    static let pokeAPI = "pokeapi.co"

    /// The URL for the translation service.
    static let translation = "api.funtranslations.com"
  }
}
