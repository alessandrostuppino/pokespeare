import Foundation
import Pokespeare
import SwiftData
import class UIKit.UIResponder
import class UIKit.UIApplication

@Observable
class SearchViewModel {

  // MARK: - Constants

  let title = "PokéSpeare"
  let warning = "Warning"
  let ok = "Ok"
  let cancel = "Cancel"
  let confirm = "Confirm"
  let confirmMessage = """
    Are you sure you want to delete all the search history?

    This will require the use of an internet connection even for the Pokémon already displayed.
    """
  let defaultErrorDescription = "Ops... Something went wrong!"
  let searchPlaceholder = "Type a Pokémon name"
  let search = "Search"
  let sectionHeader = "RECENTLY SEARCHED"

  // MARK: - Stored Properties

  /// The model conext used to persist data.
  var modelContext: ModelContext?

  /// The search text prompted by the user.
  var searchText = ""

  /// The detail of the Pokémon currently displayed.
  var pokemonDetail: Pokemon?

  /// Whether the alert for history clearing operation should be displayed.
  var historyAlertConfirmation = false

  /// The search history.
  private(set) var recentlySearched: [Pokemon] = []

  /// Whether the app is performing asynchronous operations.
  private(set) var isLoading = false

  /// The error returned by the SDK.
  private var sdkError: Pokespeare.Error?

  // MARK: - Computed Properties

  /// Whether the search button is visible.
  var isSearchButtonVisible: Bool {
    searchText.count > 2
  }

  /// Whether there is history to display.
  var hasHistory: Bool {
    !recentlySearched.isEmpty
  }

  /// Whether the view should display the alert with an error.
  ///
  /// - Note: C-15, addressed in phase 4. The setter discards `newValue` and always clears
  ///   the error, so `isErrorVisible = true` silently does nothing.
  var isErrorVisible: Bool {
    get {
      sdkError != nil
    }
    // swiftlint:disable:next unused_setter_value
    set {
      sdkError = nil
    }
  }

  /// The error description displayed inside the alert.
  var errorDescription: String {
    sdkError?.errorDescription ?? defaultErrorDescription
  }

  // MARK: - Interactions

  /// The user tapped the button to dismiss the alert.
  func didTapAlertButton() {
    reset()
  }

  /// The user tapped the search button.
  func didTapSearchButton() {
    dismissKeyboard()
    guard isSearchButtonVisible else { return }
    reset()

    if let pokemon = recentlySearched.enumerated().first(where: { $0.element.name.lowercased() == searchText.lowercased() }) {
      updatePokemon(pokemon)
      pokemonDetail = pokemon.element
      return
    }

    isLoading = true

    Task {
      do {
        let spriteUrl = try await Pokespeare.live.sprite(for: searchText)
        let description = try await Pokespeare.live.description(for: searchText)

        let pokemon = Pokemon(
          name: searchText.lowercased().capitalized,
          shakespeareanDescription: description,
          spriteUrl: spriteUrl
        )

        if let modelContext {
          modelContext.insert(pokemon)
          try? modelContext.save()

          recentlySearched.insert(pokemon, at: .zero)
        }

        pokemonDetail = pokemon

        isLoading = false
      } catch {
        isLoading = false
        guard let pokespeareError = error as? Pokespeare.Error else {
          sdkError = .unknown
          return
        }

        sdkError = pokespeareError
      }
    }
  }

  /// The user selected the given `pokemon` from the history.
  ///
  /// - Parameters: The tapped Pokémon item.
  func didTapPokemon(_ pokemon: Pokemon) {
    dismissKeyboard()
    reset()
    pokemonDetail = pokemon
  }

  /// The user cancelled the history deletion operation.
  func didTapCancelHistoryDeletion() {
    historyAlertConfirmation = false
  }

  /// The user confirmed the deletion of the history from memory.
  func didTapConfirmHistoryDeletion() {
    guard let modelContext else { return }

    recentlySearched.forEach { modelContext.delete($0) }
    recentlySearched.removeAll()
  }

  /// The user tapped the button to clear the history.
  func didTapClearHistoryButton() {
    dismissKeyboard()
    historyAlertConfirmation = true
  }

  // MARK: - Functions

  /// The method in charge of dismissing the keyboard.
  func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  /// Invoked when the search text changes, allows only letters and whitespaces characters.
  func searchTextDidChange() {
    let filtered = searchText.filter { $0.isLetter || $0.isWhitespace }
    searchText = filtered != searchText ? filtered : searchText
  }

  /// Invoked when the view appears, evaluates `modelContext` and fetches the history in memory.
  ///
  /// - Parameters: The model context retrieved of the view.
  func evaluateModelContext(_ mc: ModelContext) {
    modelContext = mc
    fetchHistory()
  }

  /// Initializes a `Pokespeare.PokemonViewModel` with the given `pokemon` then passed to the `Pokespeare.PokemonView`.
  ///
  /// - Parameters: The Pokémon source information.
  /// - Returns: An instance of `Pokespeare.PokemonViewModel`.
  func pokemonViewModel(for pokemon: Pokemon) -> PokemonViewModel {
    .init(name: pokemon.name, description: pokemon.shakespeareanDescription, spriteUrl: pokemon.spriteUrl)
  }

  /// Fetches the history from SwiftData persistency container.
  private func fetchHistory() {
    let fetchDescriptor = FetchDescriptor<Pokemon>(sortBy: [SortDescriptor(\.searchDate, order: .reverse)])
    guard let fetched = try? modelContext?.fetch(fetchDescriptor) else { return }
    recentlySearched = fetched
  }

  /// Refreshes the Pokémon inside both the list and the model context by recreate it to update the `searchDate`.
  /// - Parameter item: The item to update.
  private func updatePokemon(_ item: EnumeratedSequence<[Pokemon]>.Element) {
    let updatedPokemon = Pokemon(pokemon: item.element)
    recentlySearched.remove(at: item.offset)
    modelContext?.delete(item.element)

    recentlySearched.insert(updatedPokemon, at: .zero)
    modelContext?.insert(updatedPokemon)
    try? modelContext?.save()
  }

  /// Resets the values of `pokemonDetail` and `sdkError` before any operation.
  private func reset() {
    pokemonDetail = nil
    isErrorVisible = false
  }
}
