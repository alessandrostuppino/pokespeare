import Foundation

protocol Session: Sendable {
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: Session {
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await data(for: request)
  }

  /// The session the SDK uses by default.
  ///
  /// Separate from `URLSession.shared` so the cache belongs to the SDK rather than to
  /// whatever else the host app does with the shared session. PokeAPI serves cacheable
  /// responses, so looking the same Pokémon up twice does not have to hit the network.
  static let pokespeare: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(
      memoryCapacity: 4 * 1024 * 1024,
      diskCapacity: 32 * 1024 * 1024,
      diskPath: "pokespeare"
    )
    configuration.requestCachePolicy = .useProtocolCachePolicy

    return URLSession(configuration: configuration)
  }()
}
