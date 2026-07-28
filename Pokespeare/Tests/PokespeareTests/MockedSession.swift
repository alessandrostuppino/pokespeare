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

// MARK: - Response Builders

extension MockedSession {
  /// A session answering with the given status code and raw body.
  static func responding(statusCode: Int, body: Data = Data()) -> MockedSession {
    .init { request in
      (
        body,
        HTTPURLResponse(
          url: request.url ?? URL(string: "about:blank")!,
          statusCode: statusCode,
          httpVersion: nil,
          headerFields: nil
        )!
      )
    }
  }

  /// A session answering `200` with the JSON encoding of the given value.
  static func responding<Body: Encodable>(with body: Body, statusCode: Int = 200) throws -> MockedSession {
    try responding(statusCode: statusCode, body: JSONEncoder().encode(body))
  }

  /// A session answering with a `URLResponse` that is not an `HTTPURLResponse`.
  static func respondingWithoutHTTPResponse() -> MockedSession {
    .init { request in
      (
        Data(),
        URLResponse(
          url: request.url ?? URL(string: "about:blank")!,
          mimeType: nil,
          expectedContentLength: 0,
          textEncodingName: nil
        )
      )
    }
  }

  /// A session answering `200` with a body that is not valid JSON for the expected model.
  static func respondingWithMalformedBody() -> MockedSession {
    responding(statusCode: 200, body: Data("not json at all".utf8))
  }

  /// A session that captures the `URLRequest` it receives and answers `200` with an empty body.
  static func capturing(_ captured: RequestBox) -> MockedSession {
    .init { request in
      captured.value = request

      return (
        Data(),
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      )
    }
  }
}

/// A holder used to read back the `URLRequest` a manager actually produced.
final class RequestBox: @unchecked Sendable {
  var value: URLRequest?
}
