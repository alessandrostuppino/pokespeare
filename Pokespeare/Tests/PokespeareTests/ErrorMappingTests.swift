import Foundation
import Testing
@testable import Pokespeare

/// Characterization tests for the error pipeline.
///
/// They pin down the behaviour the SDK has **today**, including the defects recorded in the
/// audit (C-01, C-04, C-05). Phase 2 changes these expectations together with the code, so
/// the diff of that commit shows exactly which user-visible behaviour changed.
@Suite("Error Mapping")
struct ErrorMappingTests {

  // MARK: - Transport layer

  @Suite("Manager transport")
  struct TransportTests {
    @Test func http_404_is_reported_as_pokemon_not_found() async throws {
      let manager = PokemonManager.live(session: MockedSession.responding(statusCode: 404))

      await #expect(throws: PokemonManager.Error.pokemonNotFound) {
        _ = try await manager.description(for: "picatchu")
      }
    }

    /// C-01: a server failure escapes as a bare `URLError` instead of a `PokemonManager.Error`,
    /// so the SDK layer above cannot recognise it.
    @Test func http_500_escapes_as_a_bare_url_error() async throws {
      let manager = PokemonManager.live(session: MockedSession.responding(statusCode: 500))

      await #expect(throws: URLError(.badServerResponse)) {
        _ = try await manager.description(for: "pikachu")
      }
    }

    /// C-01: same for a response that is not an `HTTPURLResponse`.
    @Test func non_http_response_escapes_as_a_bare_url_error() async throws {
      let manager = PokemonManager.live(session: MockedSession.respondingWithoutHTTPResponse())

      await #expect(throws: URLError(.badServerResponse)) {
        _ = try await manager.sprite(for: "pikachu")
      }
    }

    @Test func malformed_body_is_wrapped_as_an_unknown_network_error() async throws {
      let manager = PokemonManager.live(session: MockedSession.respondingWithMalformedBody())

      let error = await #expect(throws: PokemonManager.Error.self) {
        _ = try await manager.sprite(for: "pikachu")
      }

      guard case let .networkError(urlError) = try #require(error) else {
        Issue.record("Expected a networkError, got \(String(describing: error))")
        return
      }

      #expect(urlError.code == .unknown)
      #expect(urlError.userInfo["error"] != nil)
    }

    /// C-01: transport errors raised by the session itself (offline, timeout) are not wrapped
    /// either, so they reach the SDK layer as bare `URLError`s.
    @Test func session_failures_are_not_wrapped() async throws {
      let offline = URLError(.notConnectedToInternet)
      let manager = PokemonManager.live(session: MockedSession.failureSession(with: offline))

      await #expect(throws: offline) {
        _ = try await manager.sprite(for: "pikachu")
      }
    }
  }

  // MARK: - Domain layer

  @Suite("Missing payload")
  struct MissingPayloadTests {
    /// C-05: a species with no flavor text at all yields `nil`, indistinguishable from the
    /// other two "missing" cases.
    @Test func species_without_any_flavor_text_returns_nil() async throws {
      let session = try MockedSession.responding(with: PokemonSpeciesResponse(flavorTextEntries: []))
      let manager = PokemonManager.live(session: session)

      #expect(try await manager.description(for: "pikachu") == nil)
    }

    /// C-05: a species that exists but has no english entry also yields `nil`, which the SDK
    /// then reports to the user as "no Pokémon with that name".
    @Test func species_without_an_english_entry_returns_nil() async throws {
      let response = PokemonSpeciesResponse(
        flavorTextEntries: [.init(flavorText: "Descrizione italiana", language: "it")]
      )
      let manager = PokemonManager.live(session: try MockedSession.responding(with: response))

      #expect(try await manager.description(for: "pikachu") == nil)
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
    @Test func pokemon_manager_not_found_maps_to_pokemon_not_found() {
      #expect(Pokespeare.Error.from(error: PokemonManager.Error.pokemonNotFound) == .pokemonNotFound)
    }

    @Test func pokemon_manager_network_error_preserves_the_code() {
      let mapped = Pokespeare.Error.from(error: PokemonManager.Error.networkError(URLError(.timedOut)))

      #expect(mapped == .networkError(URLError(.timedOut)))
    }

    /// C-04: "Pokémon not found" is inferred from the fact that `userInfo` happens to be
    /// empty — an invisible coupling between two files.
    @Test func unknown_url_error_without_user_info_is_reinterpreted_as_not_found() {
      let mapped = Pokespeare.Error.from(error: PokemonManager.Error.networkError(URLError(.unknown)))

      #expect(mapped == .pokemonNotFound)
    }

    @Test func translation_rate_limit_maps_to_rate_limit_exceeded() {
      #expect(Pokespeare.Error.from(error: TranslationManager.Error.rateLimitReached) == .rateLimitExceeded)
    }

    @Test func translation_invalid_query_maps_to_translation_failed() {
      let mapped = Pokespeare.Error.from(error: TranslationManager.Error.invalidQueryText("text"))

      #expect(mapped == .translationFailed("text"))
    }

    /// C-01: a `URLError` that did not come from a manager is not recognised, so the real
    /// code is discarded and replaced with `.unknown`.
    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .badServerResponse, .cannotFindHost])
    func bare_url_errors_lose_their_code(code: URLError.Code) {
      let mapped = Pokespeare.Error.from(error: URLError(code))

      #expect(mapped == .networkError(URLError(.unknown)))
    }

    /// C-01: an unrelated error is reported as a network error rather than as `.unknown`,
    /// which is why the `.unknown` case is never produced.
    @Test func unrelated_errors_are_reported_as_network_errors() {
      struct Sample: Swift.Error {}

      #expect(Pokespeare.Error.from(error: Sample()) == .networkError(URLError(.unknown)))
    }
  }

  // MARK: - End to end, as the user sees it

  @Suite("User facing outcome")
  struct UserFacingTests {
    /// C-01, end to end: a server failure reaches the alert as error code -1, the same
    /// message the user gets when the device is offline.
    @Test func server_failure_is_shown_as_error_code_minus_one() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: MockedSession.responding(statusCode: 500)),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      let error = await #expect(throws: Pokespeare.Error.self) {
        _ = try await sdk.description(for: "pikachu")
      }

      #expect(try #require(error) == .networkError(URLError(.unknown)))
      #expect(try #require(error).errorDescription.contains("Error code: -1"))
    }

    /// C-01: being offline produces the very same error, so the two are indistinguishable.
    @Test func offline_produces_the_same_error_as_a_server_failure() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: MockedSession.failureSession(with: URLError(.notConnectedToInternet))),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      let error = await #expect(throws: Pokespeare.Error.self) {
        _ = try await sdk.sprite(for: "pikachu")
      }

      #expect(try #require(error) == .networkError(URLError(.unknown)))
    }

    /// C-25: the `guard` in `Pokespeare.live` throws `.pokemonNotFound`, but that `throw`
    /// sits inside the very `do` block whose `catch` funnels everything through
    /// `Error.from(error:)`, which does not recognise `Pokespeare.Error` and rewrites it as
    /// `.networkError(.unknown)`. The Pokémon exists, has no english description, and the
    /// user is told the network failed.
    @Test func missing_english_description_is_swallowed_into_an_unknown_network_error() async throws {
      let response = PokemonSpeciesResponse(
        flavorTextEntries: [.init(flavorText: "Descrizione italiana", language: "it")]
      )
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: try MockedSession.responding(with: response)),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      await #expect(throws: Pokespeare.Error.networkError(URLError(.unknown))) {
        _ = try await sdk.description(for: "pikachu")
      }
    }

    /// C-25: the same trap makes `spriteUnavailable` undeliverable. Together with
    /// `descriptionUnavailable` and `englishDescriptionUnavailable`, three of the eight
    /// public error cases can never reach the user.
    @Test func missing_sprite_is_swallowed_into_an_unknown_network_error() async throws {
      let sdk = Pokespeare.live(
        pokemonManager: .live(session: try MockedSession.responding(with: PokemonDetailResponse(sprite: ""))),
        translationManager: .live(session: MockedSession.unimplemented())
      )

      await #expect(throws: Pokespeare.Error.networkError(URLError(.unknown))) {
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
  }
}
