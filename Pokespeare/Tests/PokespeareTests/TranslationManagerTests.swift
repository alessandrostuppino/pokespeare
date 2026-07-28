import Foundation
import Testing
@testable import Pokespeare

@Suite("Translation Manager")
struct TranslationManagerTests {
  @Suite("Unit Tests")
  struct UnitTests {
    @Test func translation_ok() async throws {
      let expected = "Translated text"
      let manager = TranslationManager.live(session: MockedSession.translationSuccessSession(with: expected))
      let result = try await manager.translation(for: expected)

      #expect(result == expected)
    }

    @Test func translation_ko() async throws {
      let manager = TranslationManager.live(session: MockedSession.failureSession(with: URLError(.badURL)))

      await #expect(throws: APIError.transport(URLError(.badURL))) {
        _ = try await manager.translation(for: "Whatever text")
      }
    }

    @Test func translation_ko_rate_limit() async throws {
      let manager = TranslationManager.live(session: MockedSession.responding(statusCode: 429))

      await #expect(throws: TranslationManager.Error.rateLimitReached) {
        _ = try await manager.translation(for: "Whatever text")
      }
    }

    /// The free tier allows 5 calls per hour: an empty string is rejected before the call.
    @Test(arguments: ["", "   ", "\n\t"])
    func blank_text_is_rejected_without_a_network_call(text: String) async throws {
      let manager = TranslationManager.live(session: MockedSession.unimplemented())

      await #expect(throws: TranslationManager.Error.invalidQueryText(text)) {
        _ = try await manager.translation(for: text)
      }
    }
  }

  @Suite(
    "Integration Tests",
    .tags(.integration),
    .disabled(if: !IntegrationTests.isEnabled, IntegrationTests.skipReason)
  )
  struct LiveAPITests {
    @Test func translation_integration() async throws {
      let text = "You gave Mr. Tim a hearty meal, but unfortunately what he ate made him die."
      let expected = "Thee did giveth mr. Tim a hearty meal,  but unfortunately what he did doth englut did maketh him kicketh the bucket."
      let translated = try await TranslationManager.live().translation(for: text)

      #expect(translated == expected)
    }

    @Test func empty_translation_integration() async throws {
      await #expect(throws: TranslationManager.Error.invalidQueryText("")) {
        _ = try await TranslationManager.live().translation(for: "")
      }
    }
  }
}

extension MockedSession {
  static func translationSuccessSession(with text: String) -> MockedSession {
    .init { _ in
      (
        try! JSONEncoder().encode(ShakespeareanTranslationResponse(translated: text, original: text)),
        HTTPURLResponse(url: URL(string: "about:blank")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      )
    }
  }
}
