import Foundation

extension Pokespeare {
  /// The errors thrown by the exposed services.
  public enum Error: Swift.Error, Equatable {
    /// Thrown when there is a network error. The associated `URLError` carries the real
    /// underlying code, so callers can distinguish being offline from a server failure.
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
  }
}

// MARK: - LocalizedError

extension Pokespeare.Error: LocalizedError {
  /// Human-readable description of the error.
  ///
  /// Conforming to `LocalizedError` means `localizedDescription` returns this text too,
  /// so callers that only know about `any Error` still get the message.
  public var errorDescription: String? {
    switch self {
      case let .networkError(urlError):
        String(
          localized: "Ops... Something went wrong!\nPlease try again in a few minutes.\n(Error code: \(urlError.errorCode))",
          bundle: .module
        )
      case .pokemonNotFound:
        String(
          localized: "It seems that there's no Pokémon with that name.\nPlease try with a different one.",
          bundle: .module
        )
      case let .descriptionUnavailable(pokemonName):
        String(localized: "No description available for the Pokémon named \(pokemonName).", bundle: .module)
      case let .englishDescriptionUnavailable(pokemonName):
        String(
          localized: "It seems that there's no description available in your language for the Pokémon named \(pokemonName).",
          bundle: .module
        )
      case let .translationFailed(text):
        String(
          localized: "The translation of the description into Shakespearean style failed.\nDescription: \(text).",
          bundle: .module
        )
      case .spriteUnavailable:
        String(localized: "It seems that there's no sprite available for the prompted Pokémon.", bundle: .module)
      case .rateLimitExceeded:
        String(
          localized: "Maybe you looked for too many Pokémon.\nPlease wait some time before trying again.",
          bundle: .module
        )
      case .unknown:
        String(localized: "Ops... Something went wrong!\nPlease try again in a few minutes.", bundle: .module)
    }
  }
}

// MARK: - Mapping

extension Pokespeare.Error {
  /// Maps any error raised inside the SDK onto the public error surface.
  ///
  /// The ordering matters: a `Pokespeare.Error` raised by the SDK itself must pass through
  /// untouched, otherwise it gets rewritten into something meaningless.
  static func from(error: any Swift.Error) -> Self {
    switch error {
      case let error as Pokespeare.Error:
        error
      case let error as PokemonManager.Error:
        from(error: error)
      case let error as TranslationManager.Error:
        from(error: error)
      case let error as APIError:
        from(error: error)
      case let error as URLError:
        .networkError(error)
      default:
        .unknown
    }
  }

  static func from(error: PokemonManager.Error) -> Self {
    switch error {
      case .pokemonNotFound:
        .pokemonNotFound
      case let .descriptionUnavailable(name):
        .descriptionUnavailable(name)
      case let .englishDescriptionUnavailable(name):
        .englishDescriptionUnavailable(name)
      case .spriteUnavailable:
        .spriteUnavailable
    }
  }

  static func from(error: TranslationManager.Error) -> Self {
    switch error {
      case let .invalidQueryText(text):
        .translationFailed(text)
      case .rateLimitReached:
        .rateLimitExceeded
    }
  }

  static func from(error: APIError) -> Self {
    switch error {
      case .invalidURL:
        .networkError(URLError(.badURL))
      case let .transport(urlError):
        .networkError(urlError)
      case .invalidResponse:
        .networkError(URLError(.badServerResponse))
      case let .unacceptableStatusCode(statusCode):
        .networkError(URLError(.badServerResponse, userInfo: [statusCodeKey: statusCode]))
      case .decodingFailed:
        .networkError(URLError(.cannotDecodeContentData))
    }
  }

  /// `userInfo` key carrying the HTTP status code of a rejected response.
  static let statusCodeKey = "PokespeareHTTPStatusCode"
}
