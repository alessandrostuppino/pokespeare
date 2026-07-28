import Foundation
import Pokespeare
import SwiftData
import Testing
@testable import PokeApp

@MainActor
@Suite("Search View Model")
struct SearchViewModelTests {

  // MARK: - Search

  @MainActor
  @Suite("Search")
  struct SearchTests {
    @Test func a_successful_search_publishes_the_pokemon_and_clears_loading() async throws {
      let viewModel = SearchViewModel(pokespeare: .stub())
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.pokemonDetail?.name == "Pikachu")
      #expect(viewModel.pokemonDetail?.shakespeareanDescription == Pokespeare.stubDescription)
      #expect(viewModel.pokemonDetail?.spriteUrl == Pokespeare.stubSpriteURL)
      #expect(viewModel.isLoading == false)
      #expect(viewModel.isErrorVisible == false)
    }

    @Test func the_two_endpoints_are_called_concurrently() async throws {
      let calls = CallRecorder()
      let viewModel = SearchViewModel(
        pokespeare: .stub(
          description: { _ in
            await calls.record("description-start")
            try await Task.sleep(for: .milliseconds(50))
            await calls.record("description-end")
            return Pokespeare.stubDescription
          },
          sprite: { _ in
            await calls.record("sprite-start")
            try await Task.sleep(for: .milliseconds(50))
            await calls.record("sprite-end")
            return Pokespeare.stubSpriteURL
          }
        )
      )
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      // Serialised, one call would finish before the other starts. Overlapping starts are
      // the observable signature of `async let`.
      let recorded = await calls.events
      #expect(recorded.prefix(2).allSatisfy { $0.hasSuffix("-start") })
    }

    @Test func a_search_shorter_than_three_characters_does_nothing() async throws {
      let viewModel = SearchViewModel(pokespeare: .unimplemented())
      viewModel.searchText = "pi"

      await viewModel.performSearchAndWait()

      #expect(viewModel.pokemonDetail == nil)
      #expect(viewModel.isLoading == false)
    }
  }

  // MARK: - Errors

  @MainActor
  @Suite("Errors")
  struct ErrorTests {
    @Test func an_sdk_error_is_surfaced_on_the_alert_with_its_own_message() async throws {
      let viewModel = SearchViewModel(
        pokespeare: .stub(description: { _ in throw Pokespeare.Error.pokemonNotFound })
      )
      viewModel.searchText = "picatchu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.isErrorVisible)
      #expect(viewModel.errorDescription == Pokespeare.Error.pokemonNotFound.errorDescription!)
      #expect(viewModel.isLoading == false)
      #expect(viewModel.pokemonDetail == nil)
    }

    @Test func a_non_sdk_error_falls_back_to_the_unknown_message() async throws {
      struct Sample: Swift.Error {}

      let viewModel = SearchViewModel(pokespeare: .stub(description: { _ in throw Sample() }))
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.isErrorVisible)
      #expect(viewModel.errorDescription == Pokespeare.Error.unknown.errorDescription!)
    }

    @Test func dismissing_the_alert_clears_the_error() async throws {
      let viewModel = SearchViewModel(
        pokespeare: .stub(description: { _ in throw Pokespeare.Error.pokemonNotFound })
      )
      viewModel.searchText = "picatchu"
      await viewModel.performSearchAndWait()

      viewModel.didTapAlertButton()

      #expect(viewModel.isErrorVisible == false)
    }

    /// A cancelled search is a normal outcome of typing a new one, not a failure.
    @Test func a_cancellation_does_not_raise_an_alert() async throws {
      let viewModel = SearchViewModel(
        pokespeare: .stub(description: { _ in throw Pokespeare.Error.networkError(URLError(.cancelled)) })
      )
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.isErrorVisible == false)
    }
  }

  // MARK: - Concurrency

  @MainActor
  @Suite("Concurrency")
  struct ConcurrencyTests {
    /// The defect this guards against: the slower, older search completing last and
    /// overwriting the newer result.
    @Test func a_new_search_cancels_the_previous_one() async throws {
      let viewModel = SearchViewModel(
        pokespeare: .stub(
          description: { name in
            if name == "slowpoke" {
              try await Task.sleep(for: .milliseconds(200))
            }
            return "Description of \(name)"
          }
        )
      )

      viewModel.searchText = "slowpoke"
      viewModel.didTapSearchButton()

      viewModel.searchText = "pikachu"
      await viewModel.performSearchAndWait()

      try await Task.sleep(for: .milliseconds(300))

      #expect(viewModel.pokemonDetail?.name == "Pikachu")
    }
  }

  // MARK: - Input

  @MainActor
  @Suite("Input")
  struct InputTests {
    @Test(arguments: [
      ("pika4chu!", "pikachu"),
      ("mr mime", "mr mime"),
      ("123", ""),
      ("Pikachu", "Pikachu")
    ])
    func only_letters_and_whitespace_survive(input: String, expected: String) {
      let viewModel = SearchViewModel(pokespeare: .unimplemented())
      viewModel.searchText = input

      viewModel.searchTextDidChange()

      #expect(viewModel.searchText == expected)
    }

    @Test(arguments: [("pi", false), ("pik", true), ("", false)])
    func the_search_button_needs_at_least_three_characters(input: String, expected: Bool) {
      let viewModel = SearchViewModel(pokespeare: .unimplemented())
      viewModel.searchText = input

      #expect(viewModel.isSearchButtonVisible == expected)
    }
  }
}

// MARK: - Helpers

private extension SearchViewModel {
  /// Starts a search and waits for it to settle.
  ///
  /// `didTapSearchButton` is fire-and-forget by design, so tests need a way to await it.
  func performSearchAndWait() async {
    didTapSearchButton()
    await searchTask?.value
  }
}

/// Records the order in which the stubbed endpoints were entered and left.
actor CallRecorder {
  private(set) var events: [String] = []

  func record(_ event: String) {
    events.append(event)
  }
}
