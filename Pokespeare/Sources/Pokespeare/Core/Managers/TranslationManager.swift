import Foundation

struct TranslationManager: Sendable {
  /// The domain failures of the FunTranslations endpoint.
  ///
  /// Transport failures leave the manager as ``APIError``.
  enum Error: Swift.Error, Equatable {
    /// There is nothing to translate.
    case invalidQueryText(String)

    /// The service rejected the call because the caller ran out of quota.
    case rateLimitReached
  }

  private var _translation: @Sendable (_ text: String) async throws -> String

  func translation(for text: String) async throws -> String {
    try await self._translation(text)
  }
}

// MARK: - Live Implementation

extension TranslationManager {
  static func live(
    session: any Session = URLSession.pokespeare,
    retryPolicy: RetryPolicy = RetryPolicy()
  ) -> Self {
    let client = APIClient(session: session, retryPolicy: retryPolicy) { statusCode in
      statusCode == HTTPStatusCode.tooManyRequests ? Error.rateLimitReached : nil
    }

    return .init(
      _translation: { text in
        // The free tier allows 5 calls per hour: never spend one on an empty string.
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          throw Error.invalidQueryText(text)
        }

        let response = try await client.perform(ShakespeareanTranslationRequest(text: text))

        return response.translated
      }
    )
  }
}
