import Foundation
import Pokespeare
import SwiftData
import Testing
@testable import PokeApp

@MainActor
// Each test stands up its own SwiftData store; building several concurrently crashes the
// test process.
@Suite("Search View Model", .serialized)
struct SearchViewModelTests {

  // MARK: - Search

  @MainActor
  @Suite("Search")
  struct SearchTests {
    @Test func a_successful_search_publishes_the_pokemon_and_clears_loading() async throws {
      let viewModel = SearchViewModel(modelContext: try TemporaryStore.makeContext(), pokespeare: .stub())
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
        modelContext: try TemporaryStore.makeContext(),
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
      let viewModel = SearchViewModel(modelContext: try TemporaryStore.makeContext(), pokespeare: .unimplemented())
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
        modelContext: try TemporaryStore.makeContext(),
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

      let viewModel = SearchViewModel(
        modelContext: try TemporaryStore.makeContext(),
        pokespeare: .stub(description: { _ in throw Sample() })
      )
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.isErrorVisible)
      #expect(viewModel.errorDescription == Pokespeare.Error.unknown.errorDescription!)
    }

    @Test func dismissing_the_alert_clears_the_error() async throws {
      let viewModel = SearchViewModel(
        modelContext: try TemporaryStore.makeContext(),
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
        modelContext: try TemporaryStore.makeContext(),
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
        modelContext: try TemporaryStore.makeContext(),
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

  // MARK: - History

  @MainActor
  @Suite("History")
  struct HistoryTests {
    @Test func a_successful_search_is_persisted_and_survives_a_new_view_model() async throws {
      let context = try TemporaryStore.makeContext()
      let viewModel = SearchViewModel(modelContext: context, pokespeare: .stub())
      viewModel.searchText = "pikachu"

      await viewModel.performSearchAndWait()

      #expect(viewModel.recentlySearched.map(\.name) == ["Pikachu"])

      // A fresh view model on the same store reads the history back.
      let reopened = SearchViewModel(modelContext: context, pokespeare: .unimplemented())

      #expect(reopened.recentlySearched.map(\.name) == ["Pikachu"])
      #expect(reopened.hasHistory)
    }

    /// Searching something already in the history must not hit the network, and must not
    /// create a second row: `name` is the unique key.
    @Test func searching_a_known_pokemon_reuses_the_stored_entry() async throws {
      let context = try TemporaryStore.makeContext()
      let viewModel = SearchViewModel(modelContext: context, pokespeare: .stub())
      viewModel.searchText = "pikachu"
      await viewModel.performSearchAndWait()

      let stored = try #require(viewModel.recentlySearched.first)
      let originalDate = stored.searchDate

      // The stub would record an issue if the SDK were called again.
      let offline = SearchViewModel(modelContext: context, pokespeare: .unimplemented())
      offline.searchText = "PIKACHU"
      await offline.performSearchAndWait()

      #expect(offline.recentlySearched.count == 1)
      #expect(offline.pokemonDetail?.name == "Pikachu")
      #expect(try #require(offline.recentlySearched.first).searchDate > originalDate)
    }

    @Test func the_history_is_ordered_by_most_recent_search() async throws {
      let context = try TemporaryStore.makeContext()
      let viewModel = SearchViewModel(modelContext: context, pokespeare: .stub())

      for name in ["bulbasaur", "charmander", "squirtle"] {
        viewModel.searchText = name
        await viewModel.performSearchAndWait()
      }

      #expect(viewModel.recentlySearched.map(\.name) == ["Squirtle", "Charmander", "Bulbasaur"])

      viewModel.searchText = "bulbasaur"
      await viewModel.performSearchAndWait()

      #expect(viewModel.recentlySearched.map(\.name) == ["Bulbasaur", "Squirtle", "Charmander"])
    }

    @Test func clearing_the_history_empties_the_store_too() async throws {
      let context = try TemporaryStore.makeContext()
      let viewModel = SearchViewModel(modelContext: context, pokespeare: .stub())
      viewModel.searchText = "pikachu"
      await viewModel.performSearchAndWait()

      viewModel.didTapConfirmHistoryDeletion()

      #expect(viewModel.recentlySearched.isEmpty)
      #expect(viewModel.hasHistory == false)
      #expect(viewModel.historyAlertConfirmation == false)

      let reopened = SearchViewModel(modelContext: context, pokespeare: .unimplemented())

      #expect(reopened.recentlySearched.isEmpty)
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
    func only_letters_and_whitespace_survive(input: String, expected: String) throws {
      let viewModel = SearchViewModel(modelContext: try TemporaryStore.makeContext(), pokespeare: .unimplemented())
      viewModel.searchText = input

      viewModel.searchTextDidChange()

      #expect(viewModel.searchText == expected)
    }

    @Test(arguments: [("pi", false), ("pik", true), ("", false)])
    func the_search_button_needs_at_least_three_characters(input: String, expected: Bool) throws {
      let viewModel = SearchViewModel(modelContext: try TemporaryStore.makeContext(), pokespeare: .unimplemented())
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
