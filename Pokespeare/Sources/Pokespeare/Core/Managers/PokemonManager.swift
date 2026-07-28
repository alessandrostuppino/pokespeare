import Foundation

struct PokemonManager {
  enum Error: Swift.Error, Equatable {
    case networkError(URLError)
    case pokemonNotFound
  }

  private var _description: @Sendable (String) async throws -> String?
  private var _sprite: @Sendable (String) async throws -> URL?

  func sprite(for pokemon: String) async throws -> URL? {
    try await self._sprite(pokemon)
  }

  func description(for pokemon: String) async throws -> String? {
    try await self._description(pokemon)
  }
}

// MARK: - Live Implementation

extension PokemonManager {
  static func live(session: Session = URLSession.shared) -> Self {
    .init(
      _description: { pokemon in
        let response = try await pokemonRequest(request: PokemonSpeciesRequest(pokemonName: pokemon), session: session)

        return response.flavorTextEntries
          .first { $0.language == defaultLanguage }
          .map(\.flavorText)?
          .replacingOccurrences(of: "\n", with: " ")
          .replacingOccurrences(of: "\u{c}", with: " ")
      },
      _sprite: { pokemon in
        let response = try await pokemonRequest(request: PokemonDetailRequest(pokemonName: pokemon), session: session)

        return URL(string: response.sprite)
      }
    )
  }

  fileprivate static func pokemonRequest<R: HTTPCodableRequest>(request: R, session: Session) async throws -> R.ResponseType {
    guard let url = request.urlRequest else {
      throw Error.networkError(.init(.badURL))
    }

    let (data, response) = try await session.dataHandler(for: url)

    guard let response = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    guard (200..<300) ~= response.statusCode else {
      throw response.statusCode == 404 ? Error.pokemonNotFound : URLError(.badServerResponse)
    }

    do {
      return try request.jsonDecoder.decode(R.ResponseType.self, from: data)
    } catch {
      throw Error.networkError(error as? URLError ?? URLError(.unknown, userInfo: ["error": error]))
    }
  }
}
