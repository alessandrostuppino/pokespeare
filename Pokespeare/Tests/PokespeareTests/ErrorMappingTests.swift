import Foundation
import Testing
@testable import Pokespeare

/// Tests for the error pipeline.
///
/// These started life in phase 1 as characterization tests pinning down the defects
/// recorded in the audit. Phase 2 flipped the expectations together with the code, so the
/// diff of that commit is the list of user-visible behaviours that changed.
@Suite("Error Mapping")
struct ErrorMappingTests {

  // MARK: - Transport layer

  @Suite("APIClient transport")
  struct TransportTests {
    @Test func http_404_is_mapped_by_the_status_code_mapper() async throws {
      let manager = PokemonManager.live(session: MockedSession.responding(statusCode: 404))

      await #expect(throws: PokemonManager.Error.pokemonNotFound) {
        _ = try await manager.description(for: "picatchu")
      }
    }

    /// Was C-01: a server failure used to escape as a bare `URLError(.badServerResponse)`,
    /// indistinguishable from every other network problem. It now carries its status code.
    @Test func http_500_keeps_its_status_code() async throws {
      let manager = PokemonManager.live(session: MockedSession.responding(statusCode: 500))

      await #expect(throws: APIError.unacceptableStatusCode(500)) {
        _ = try await manager.description(for: "pikachu")
      }
    }

    @Test func non_http_response_is_reported_as_an_invalid_response() async throws {
      let manager = PokemonManager.live(session: MockedSession.respondingWithoutHTTPResponse())

      await #expect(throws: APIError.invalidResponse) {
        _ = try await manager.sprite(for: "pikachu")
      }
    }

    @Test func malformed_body_is_reported_as_a_decoding_failure() async throws {
      let manager = PokemonManager.live(session: MockedSession.respondingWithMalformedBody())

      let error = await #expect(throws: APIError.self) {
        _ = try await manager.sprite(for: "pikachu")
      }

      guard case let .decodingFailed(underlying) = try #require(error) else {
        Issue.record("Expected a decodingFailed, got \(String(describing: error))")
        return
      }

      #expect(underlying is DecodingError)
    }

    /// Was C-01: session failures used to travel as bare `URLError`s that nothing upstream
    /// recognised. They are now wrapped, and the original code survives.
    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .cannotFindHost])
    func session_failures_are_wrapped_without_losing_their_code(code: URLError.Code) async throws {
      let manager = PokemonManager.live(session: MockedSession.failureSession(with: URLError(code)))

      await #expect(throws: APIError.transport(URLError(code))) {
        _ = try await manager.sprite(for: "pikachu")
      }
    }
  }

  // MARK: - Domain layer

  @Suite("Missing payload")
  struct MissingPayloadTests {
    /// Was C-05: all three cases used to collapse into a `nil` return that the SDK reported
    /// as "no Pokémon with that name". Each has its own error now.
    @Test func species_without_any_flavor_text_is_reported_as_description_unavailable() async throws {
      let session = try MockedSession.responding(with: PokemonSpeciesResponse(flavorTextEntries: []))
      let manager = PokemonManager.live(session: session)

      await #expect(throws: PokemonManager.Error.descriptionUnavailable("pikachu")) {
        _ = try await manager.description(for: "pikachu")
      }
    }

    @Test func species_without_an_english_entry_is_reported_separately() async throws {
      let response = PokemonSpeciesResponse(
        flavorTextEntries: [.init(flavorText: "Descrizione italiana", language: "it")]
      )
      let manager = PokemonManager.live(session: try MockedSession.responding(with: response))

      await #expect(throws: PokemonManager.Error.englishDescriptionUnavailable("pikachu")) {
        _ = try await manager.description(for: "pikachu")
      }
    }

    @Test func unusable_sprite_url_is_reported_as_sprite_unavailable() async throws {
      let manager = PokemonManager.live(session: try MockedSession.responding(with: PokemonDetailResponse(sprite: "")))

      await #expect(throws: PokemonManager.Error.spriteUnavailable) {
        _ = try await manager.sprite(for: "pikachu")
      }
    }

    @Test func flavor_text_control_characters_are_normalised() async throws {
      let response = PokemonSpeciesResponse(
        flavorTextEntries: [.init(flavorText: "Line one\nline\u{c}two", language: "en")]
      )
      let manager = PokemonManager.live(session: try MockedSession.responding(with: response))

      #expect(try await manager.description(for: "pikachu") == "Line one line two")
    }
  }

  // MARK: - Pokespeare.Error.from

  @Suite("Pokespeare.Error.from")
  struct FromTests {
    /// Was C-25: an error the SDK raised itself used to be swallowed and rewritten, because
    /// `from` did not recognise its own type. It now passes through untouched.
    @Test func a_pokespeare_error_passes_through_unchanged() {
      #expect(Pokespeare.Error.from(error: Pokespeare.Error.spriteUnavailable) == .spriteUnavailable)
    }

    @Test(arguments: [
      (PokemonManager.Error.pokemonNotFound, Pokespeare.Error.pokemonNotFound),
      (.descriptionUnavailable("pikachu"), .descriptionUnavailable("pikachu")),
      (.englishDescriptionUnavailable("pikachu"), .englishDescriptionUnavailable("pikachu")),
      (.spriteUnavailable, .spriteUnavailable)
    ])
    func pokemon_manager_errors_map_one_to_one(input: PokemonManager.Error, expected: Pokespeare.Error) {
      #expect(Pokespeare.Error.from(error: input) == expected)
    }

    @Test(arguments: [
      (TranslationManager.Error.rateLimitReached, Pokespeare.Error.rateLimitExceeded),
      (.invalidQueryText("text"), .translationFailed("text"))
    ])
    func translation_manager_errors_map_one_to_one(input: TranslationManager.Error, expected: Pokespeare.Error) {
      #expect(Pokespeare.Error.from(error: input) == expected)
    }

    /// Was C-01: every transport error used to collapse onto `URLError(.unknown)`, so the
    /// alert always showed code -1. The real code now survives the mapping.
    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .cannotFindHost, .networkConnectionLost])
    func transport_errors_keep_their_code(code: URLError.Code) {
      #expect(Pokespeare.Error.from(error: APIError.transport(URLError(code))) == .networkError(URLError(code)))
    }

    @Test func an_unacceptable_status_code_is_carried_in_the_user_info() throws {
      let mapped = Pokespeare.Error.from(error: APIError.unacceptableStatusCode(503))

      guard case let .networkError(urlError) = mapped else {
        Issue.record("Expected a networkError, got \(mapped)")
        return
      }

      #expect(urlError.code == .badServerResponse)
      #expect(urlError.userInfo[Pokespeare.Error.statusCodeKey] as? Int == 503)
    }

    @Test func a_bare_url_error_is_still_recognised() {
      #expect(Pokespeare.Error.from(error: URLError(.timedOut)) == .networkError(URLError(.timedOut)))
    }

    /// Was C-01: an unrelated error used to be reported as a network problem, which is why
    /// `.unknown` was declared but never produced.
    @Test func unrelated_errors_fall_back_to_unknown() {
      struct Sample: Swift.Error {}

      #expect(Pokespeare.Error.from(error: Sample()) == .unknown)
    }
  }

  // MARK: - End to end, as the user sees it

  @Suite("User facing outcome")
  struct UserFacingTests {
    /// Was C-01: being offline and a 500 response used to produce the identical message.
    @Test func a_server_failure_and_being_offline_are_now_distinguishable() async throws {
      let serverFailure = Pokespeare.live(
        pokemonManager: .live(session: MockedSession.responding(statusCode: 500)),
        translationManager: .live(session: MockedSession.unimplemented())
      )
      let offline = Pokespeare.live(
        pokemonManager: .live(session: MockedSession.failureSession(with: URLError(.notConnectedToInternet))),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      let serverError = await #expect(throws: Pokespeare.Error.self) {
        _ = try await serverFailure.description(for: "pikachu")
      }
      let offlineError = await #expect(throws: Pokespeare.Error.self) {
        _ = try await offline.description(for: "pikachu")
      }

      #expect(try #require(offlineError) == .networkError(URLError(.notConnectedToInternet)))
      #expect(try #require(serverError) != #require(offlineError))
    }

    /// Was C-25: an existing Pokémon with no english description used to surface as
    /// "something went wrong, code -1". It now says what actually happened.
    @Test func missing_english_description_reaches_the_user_as_itself() async throws {
      let response = PokemonSpeciesResponse(
        flavorTextEntries: [.init(flavorText: "Descrizione italiana", language: "it")]
      )
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: try MockedSession.responding(with: response)),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      let error = await #expect(throws: Pokespeare.Error.self) {
        _ = try await sdk.description(for: "pikachu")
      }

      #expect(try #require(error) == .englishDescriptionUnavailable("pikachu"))
      #expect(try #require(error).errorDescription?.contains("no english description") == true)
    }

    /// Was C-25: `spriteUnavailable` was equally undeliverable.
    @Test func missing_sprite_reaches_the_user_as_itself() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: try MockedSession.responding(with: PokemonDetailResponse(sprite: ""))),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      await #expect(throws: Pokespeare.Error.spriteUnavailable) {
        _ = try await sdk.sprite(for: "pikachu")
      }
    }

    @Test func unknown_pokemon_is_reported_as_pokemon_not_found() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: MockedSession.responding(statusCode: 404)),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      await #expect(throws: Pokespeare.Error.pokemonNotFound) {
        _ = try await sdk.sprite(for: "picatchu")
      }
    }

    @Test func every_error_carries_a_message() {
      let errors: [Pokespeare.Error] = [
        .networkError(URLError(.timedOut)),
        .pokemonNotFound,
        .descriptionUnavailable("pikachu"),
        .englishDescriptionUnavailable("pikachu"),
        .translationFailed("text"),
        .spriteUnavailable,
        .rateLimitExceeded,
        .unknown
      ]

      for error in errors {
        #expect(error.errorDescription?.isEmpty == false)
        // LocalizedError conformance: `localizedDescription` must return the same message.
        #expect(error.localizedDescription == error.errorDescription)
      }
    }
  }
}
