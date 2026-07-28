import Foundation

extension Pokespeare {
  /// The errors thrown by the exposed services.
  public enum Error: Swift.Error, Equatable {
    /// Thrown when there is a network error.
    case networkError(URLError)

    /// Thrown when no Pokémon has been found with the provided `name`.
    case pokemonNotFound

    /// Thrown when the fetched Pokémon has no descriptions available.
    case descriptionUnavailable(String)

    /// Thrown when the list of descriptions doesn't have any english version.
    case englishDescriptionUnavailable(String)

    /// Thrown when the translation failed.
    case translationFailed(String)

    /// Thrown when the fetched Pokémon has no sprite available.
    case spriteUnavailable

    /// Thrown when the user exceeds the rate limit with the translation service.
    case rateLimitExceeded

    /// Fallbacks any unhandled error.
    case unknown

    /// Human-readable description of the error.
    public var errorDescription: String {
      switch self {
        case let .networkError(urlError):
          "Ops... Something went wrong!\nPlease try again in a few minutes.\n(Error code: \(urlError.errorCode))"
        case .pokemonNotFound:
          "It seems that there's no Pokémon with that name.\nPlease try with a different one."
        case let .descriptionUnavailable(pokemonName):
          "No description available for the Pokémon named \(pokemonName)."
        case let .englishDescriptionUnavailable(pokemonName):
          "It seems that there's no english description for the Pokémon named \(pokemonName)."
        case let .translationFailed(text):
          "The translation of the description into Shakespearean style failed.\nDescription: \(text)."
        case .spriteUnavailable:
          "It seems that there's no sprite available for the prompted Pokémon."
        case .rateLimitExceeded:
          "Maybe you looked for too many Pokémon.\nPlease wait some time before trying again."
        case .unknown:
          "Ops... Something went wrong!\nPlease try again in a few minutes."
      }
    }
  }
}

extension Pokespeare.Error {
  static func from(error: any Error) -> Self {
    return if let pokemonManagerError = error as? PokemonManager.Error {
      Pokespeare.Error.from(error: pokemonManagerError)
    } else if let translationManagerError = error as? TranslationManager.Error {
      Pokespeare.Error.from(error: translationManagerError)
    } else {
      Pokespeare.Error.networkError(.init(.unknown))
    }
  }

  static func from(error: PokemonManager.Error) -> Self {
    switch error {
      case let .networkError(urlError) where urlError.code == .unknown && urlError.userInfo.isEmpty:
        .pokemonNotFound
      case let .networkError(urlError):
        .networkError(urlError)
      case .pokemonNotFound:
        .pokemonNotFound
    }
  }

  static func from(error: TranslationManager.Error) -> Self {
    switch error {
      case let .networkError(urlError):
        .networkError(urlError)
      case let .invalidQueryText(text):
        .translationFailed(text)
      case .rateLimitReached:
        .rateLimitExceeded
    }
  }
}
