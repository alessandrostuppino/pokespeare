import Foundation

/// When and how often ``APIClient`` retries a failed request.
struct RetryPolicy: Sendable {
  /// How many extra attempts to make after the first one fails.
  var maxRetries: Int

  /// The wait before the first retry. Doubles on each subsequent one.
  var baseDelay: Duration

  init(maxRetries: Int = 2, baseDelay: Duration = .milliseconds(300)) {
    self.maxRetries = maxRetries
    self.baseDelay = baseDelay
  }

  /// Never retries. Useful for tests and for callers that want to fail fast.
  static let never = RetryPolicy(maxRetries: 0)

  /// Whether `error` is worth another attempt.
  ///
  /// Only failures that a later attempt could plausibly survive: a dropped connection, a
  /// timeout, a name lookup that failed, or a server-side error. A 404 or a malformed body
  /// will fail identically every time, and errors the caller mapped to its own domain type
  /// never reach here at all.
  func shouldRetry(_ error: APIError, attempt: Int) -> Bool {
    guard attempt < maxRetries else {
      return false
    }

    return switch error {
      case let .transport(urlError):
        urlError.isTransient
      case let .unacceptableStatusCode(statusCode):
        HTTPStatusCode.serverErrorRange ~= statusCode
      case .invalidURL, .invalidResponse, .decodingFailed:
        false
    }
  }

  /// Exponential backoff: `baseDelay`, then double it for each further attempt.
  func delay(forAttempt attempt: Int) -> Duration {
    baseDelay * (1 << attempt)
  }
}

private extension URLError {
  /// Whether the failure could plausibly go away on its own.
  var isTransient: Bool {
    switch code {
      case .timedOut, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        true
      default:
        false
    }
  }
}
