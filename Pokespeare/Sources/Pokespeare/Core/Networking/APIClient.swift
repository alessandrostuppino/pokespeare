import Foundation

/// The single place where an `HTTPCodableRequest` becomes a decoded response.
///
/// Both managers used to carry their own copy of this logic — build the `URLRequest`, cast
/// the response, validate the status code, decode, wrap the failure — differing only in the
/// status code they treated specially. That difference is now the `statusCodeMapper`
/// parameter, so the transport lives here once.
struct APIClient: Sendable {
  /// Turns a non-success status code into a domain error, or returns `nil` to let the
  /// client raise ``APIError/unacceptableStatusCode(_:)``.
  typealias StatusCodeMapper = @Sendable (Int) -> (any Swift.Error)?

  private let session: any Session
  private let statusCodeMapper: StatusCodeMapper
  private let retryPolicy: RetryPolicy

  init(
    session: any Session,
    retryPolicy: RetryPolicy = RetryPolicy(),
    statusCodeMapper: @escaping StatusCodeMapper = { _ in nil }
  ) {
    self.session = session
    self.retryPolicy = retryPolicy
    self.statusCodeMapper = statusCodeMapper
  }

  /// Performs `request` and decodes its response body, retrying transient failures.
  ///
  /// Every failure leaves this method as an ``APIError`` — never as a bare `URLError` — so
  /// callers can tell a transport failure from a server failure from a decoding failure.
  func perform<R: HTTPCodableRequest>(_ request: R) async throws -> R.ResponseType {
    var attempt = 0

    while true {
      do {
        return try await performOnce(request)
      } catch let error as APIError where retryPolicy.shouldRetry(error, attempt: attempt) {
        // Throws on cancellation, which is what we want: a cancelled search stops here.
        try await Task.sleep(for: retryPolicy.delay(forAttempt: attempt))

        attempt += 1
      }
    }
  }

  private func performOnce<R: HTTPCodableRequest>(_ request: R) async throws -> R.ResponseType {
    let urlRequest = try request.makeURLRequest()

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.dataHandler(for: urlRequest)
    } catch let error as URLError {
      throw APIError.transport(error)
    } catch {
      throw APIError.transport(URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error]))
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard HTTPStatusCode.successRange ~= httpResponse.statusCode else {
      throw statusCodeMapper(httpResponse.statusCode) ?? APIError.unacceptableStatusCode(httpResponse.statusCode)
    }

    do {
      return try request.jsonDecoder.decode(R.ResponseType.self, from: data)
    } catch {
      throw APIError.decodingFailed(error)
    }
  }
}

/// The transport-level failures of ``APIClient``.
enum APIError: Swift.Error {
  /// The request could not be turned into a valid `URL`.
  case invalidURL

  /// The session itself failed: no connection, timeout, DNS, cancellation.
  case transport(URLError)

  /// The server answered with something that is not an `HTTPURLResponse`.
  case invalidResponse

  /// The server answered with a status code outside `200..<300` that the caller did not map.
  case unacceptableStatusCode(Int)

  /// The body could not be decoded into the expected model.
  case decodingFailed(any Swift.Error)
}

extension APIError: Equatable {
  /// - Note: two ``decodingFailed(_:)`` values compare equal regardless of the underlying
  ///   error, which is carried for diagnostics only.
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
      case (.invalidURL, .invalidURL),
        (.invalidResponse, .invalidResponse),
        (.decodingFailed, .decodingFailed):
        true
      case let (.transport(lhs), .transport(rhs)):
        lhs == rhs
      case let (.unacceptableStatusCode(lhs), .unacceptableStatusCode(rhs)):
        lhs == rhs
      default:
        false
    }
  }
}
