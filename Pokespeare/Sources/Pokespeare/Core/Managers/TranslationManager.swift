import Foundation

struct TranslationManager {
  enum Error: Swift.Error, Equatable {
    case networkError(URLError)

    case invalidQueryText(String)
    case rateLimitReached
  }

  private var _translation: @Sendable (_ text: String) async throws -> String

  func translation(for text: String) async throws -> String {
    try await self._translation(text)
  }
}

// MARK: - Live Implementation

extension TranslationManager {
  static func live(session: Session = URLSession.shared) -> Self {
    .init(
      _translation: { text in
        let request = ShakespeareanTranslationRequest(text: text)
        guard let url = request.urlRequest else {
          throw Error.networkError(.init(.badURL, userInfo: ["error": "Invalid URL \(request.urlRequest?.url?.absoluteString ?? "nil")"]))
        }

        let (data, response) = try await session.dataHandler(for: url)

        guard let response = response as? HTTPURLResponse else {
          throw URLError(.badServerResponse)
        }

        guard (200..<300) ~= response.statusCode else {
          throw response.statusCode == 429 ? Error.rateLimitReached : URLError(.badServerResponse)
        }

        do {
          let decoded = try request.jsonDecoder.decode(ShakespeareanTranslationRequest.ResponseType.self, from: data)

          return decoded.translated
        } catch {
          throw Error.networkError(error as? URLError ?? URLError(.unknown, userInfo: ["error": error]))
        }
      }
    )
  }
}
