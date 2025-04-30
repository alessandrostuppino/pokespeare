import Foundation

protocol Session: Sendable {
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: Session {
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await data(for: request)
  }
}
