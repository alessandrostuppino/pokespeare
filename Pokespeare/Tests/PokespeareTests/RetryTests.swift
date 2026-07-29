import Foundation
import Testing
@testable import Pokespeare

@Suite("Retry")
struct RetryTests {
  /// Fast enough that a test does not pay for the backoff.
  private static let policy = RetryPolicy(maxRetries: 2, baseDelay: .milliseconds(1))

  @Test func a_transient_failure_is_retried_until_it_succeeds() async throws {
    let attempts = AttemptCounter()
    let response = PokemonDetailResponse(sprite: "https://example.com/pikachu.png")
    let body = try JSONEncoder().encode(response)

    let session = MockedSession { request in
      let attempt = await attempts.next()

      guard attempt > 1 else {
        throw URLError(.networkConnectionLost)
      }

      return (body, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }

    let manager = PokemonManager.live(session: session, retryPolicy: Self.policy)

    #expect(try await manager.sprite(for: "pikachu") == URL(string: "https://example.com/pikachu.png"))
    #expect(await attempts.count == 3)
  }

  @Test func retries_give_up_after_the_limit() async throws {
    let attempts = AttemptCounter()
    let session = MockedSession { _ in
      _ = await attempts.next()

      throw URLError(.timedOut)
    }
    let manager = PokemonManager.live(session: session, retryPolicy: Self.policy)

    await #expect(throws: APIError.transport(URLError(.timedOut))) {
      _ = try await manager.sprite(for: "pikachu")
    }

    // The first attempt plus maxRetries.
    #expect(await attempts.count == 3)
  }

  @Test func server_errors_are_retried() async throws {
    let attempts = AttemptCounter()
    let session = MockedSession { request in
      _ = await attempts.next()

      return (Data(), HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!)
    }
    let manager = PokemonManager.live(session: session, retryPolicy: Self.policy)

    await #expect(throws: APIError.unacceptableStatusCode(503)) {
      _ = try await manager.sprite(for: "pikachu")
    }

    #expect(await attempts.count == 3)
  }

  /// A 404 fails identically every time, and spending retries on it would delay the "no
  /// such Pokémon" message for no reason.
  @Test func a_not_found_is_not_retried() async throws {
    let attempts = AttemptCounter()
    let session = MockedSession { request in
      _ = await attempts.next()

      return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
    }
    let manager = PokemonManager.live(session: session, retryPolicy: Self.policy)

    await #expect(throws: PokemonManager.Error.pokemonNotFound) {
      _ = try await manager.sprite(for: "picatchu")
    }

    #expect(await attempts.count == 1)
  }

  @Test func a_malformed_body_is_not_retried() async throws {
    let attempts = AttemptCounter()
    let session = MockedSession { request in
      _ = await attempts.next()

      return (
        Data("not json".utf8),
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      )
    }
    let manager = PokemonManager.live(session: session, retryPolicy: Self.policy)

    await #expect(throws: APIError.self) {
      _ = try await manager.sprite(for: "pikachu")
    }

    #expect(await attempts.count == 1)
  }

  /// The translation service rate limit is not a transient failure: hammering it would only
  /// burn more of the hourly budget.
  @Test func a_rate_limit_is_not_retried() async throws {
    let attempts = AttemptCounter()
    let session = MockedSession { request in
      _ = await attempts.next()

      return (Data(), HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!)
    }
    let manager = TranslationManager.live(session: session, retryPolicy: Self.policy)

    await #expect(throws: TranslationManager.Error.rateLimitReached) {
      _ = try await manager.translation(for: "Some text")
    }

    #expect(await attempts.count == 1)
  }

  @Test func the_backoff_doubles_on_each_attempt() {
    let policy = RetryPolicy(maxRetries: 3, baseDelay: .milliseconds(100))

    #expect(policy.delay(forAttempt: 0) == .milliseconds(100))
    #expect(policy.delay(forAttempt: 1) == .milliseconds(200))
    #expect(policy.delay(forAttempt: 2) == .milliseconds(400))
  }
}

/// Counts how many times a mocked session was entered.
actor AttemptCounter {
  private(set) var count = 0

  func next() -> Int {
    defer { count += 1 }

    return count
  }
}
