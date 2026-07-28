import Foundation
import Testing
@testable import Pokespeare

@Suite("Translation Manager")
struct TranslationManagerTests {
  @Suite("Unit Tests")
  struct UnitTests {
    @Test func translation_ok() async throws {
      let expected = "Translated text"
      let result = try await TranslationManager.live(session: MockedSession.translationSuccessSession(with: expected)).translation(for: expected)
      
      #expect(result == expected)
    }
    
    @Test func translation_ko() async throws {
      let expected = URLError(.badURL)
      let manager = TranslationManager.live(session: MockedSession.failureSession(with: expected))

      await #expect(throws: expected) {
        _ = try await manager.translation(for: "Whatever text")
      }
    }
    
    @Test func translation_ko_rate_limit() async throws {
      let rateLimitReachedError = TranslationManager.Error.rateLimitReached
      let expectedError = URLError(.unknown, userInfo: ["error" : rateLimitReachedError])
      let manager = TranslationManager.live(session: MockedSession.failureSession(with: expectedError))

      await #expect(throws: expectedError) {
        _ = try await manager.translation(for: "Whatever text")
      }
    }
  }
  
  @Suite("Integration Tests")
  struct IntegrationTests {
    @Test func translation_integration() async throws {
      let text = "You gave Mr. Tim a hearty meal, but unfortunately what he ate made him die."
      let expected = "Thee did giveth mr. Tim a hearty meal,  but unfortunately what he did doth englut did maketh him kicketh the bucket."
      let translated = try await TranslationManager.live().translation(for: text)
      
      #expect(translated == expected)
    }
    
    @Test func empty_translation_integration() async throws {
      let expected = ""
      let translated = try await TranslationManager.live().translation(for: "")
      
      #expect(translated == expected)
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

