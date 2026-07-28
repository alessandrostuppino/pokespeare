import Foundation
import Testing
@testable import Pokespeare

class MockedSession: Session, @unchecked Sendable {
  private let _dataHandler: (URLRequest) async throws -> (Data, URLResponse)
  
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await _dataHandler(request)
  }
  
  init(dataHandler: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
    self._dataHandler = dataHandler
  }
}

extension MockedSession {
  static func failureSession(with error: any Error) -> MockedSession {
    .init { _ in
      throw error
    }
  }
}


extension MockedSession {
  /// A session that must never be reached.
  ///
  /// Records an issue and throws instead of trapping: a `fatalError` here would tear down
  /// the whole test process, losing the results of every other test in the run.
  static func unimplemented(
    sourceLocation: SourceLocation = #_sourceLocation
  ) -> MockedSession {
    .init { request in
      Issue.record(
        "Unexpected network call to \(request.url?.absoluteString ?? "nil")",
        sourceLocation: sourceLocation
      )

      throw UnimplementedSessionError()
    }
  }
}

/// Thrown by ``MockedSession/unimplemented(sourceLocation:)`` when it is unexpectedly called.
struct UnimplementedSessionError: Swift.Error {}
