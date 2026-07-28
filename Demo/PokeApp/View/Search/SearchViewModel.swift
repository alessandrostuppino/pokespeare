import Foundation
import Pokespeare
import SwiftData
import class UIKit.UIResponder
import class UIKit.UIApplication

@MainActor
@Observable
final class SearchViewModel {

  // MARK: - Dependencies

  /// The SDK instance used to fetch Pokémon data.
  ///
  /// Injected rather than reached for statically, so tests can drive this view model with
  /// a stub. `Pokespeare` is already a struct of closures, so a stub needs no protocol.
  private let pokespeare: Pokespeare

  /// The in-flight search, kept so a new one can cancel it.
  private var searchTask: Task<Void, Never>?

  init(pokespeare: Pokespeare = .live) {
    self.pokespeare = pokespeare
  }

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

    // A previous search must not win the race and overwrite this one's result.
    searchTask?.cancel()

    let name = searchText
    isLoading = true

    searchTask = Task { [weak self] in
      await self?.search(for: name)
    }
  }

  /// Fetches sprite and description for `name` and records the result.
  private func search(for name: String) async {
    // A cancelled search must not clear the spinner: a newer one already turned it on.
    defer {
      if !Task.isCancelled {
        isLoading = false
      }
    }

    do {
      // Two independent PokeAPI endpoints: no reason to wait for one before starting
      // the other.
      async let spriteUrl = pokespeare.sprite(for: name)
      async let description = pokespeare.description(for: name)

      let pokemon = Pokemon(
        name: name.lowercased().capitalized,
        shakespeareanDescription: try await description,
        spriteUrl: try await spriteUrl
      )

      guard !Task.isCancelled else { return }

      persist(pokemon)
      pokemonDetail = pokemon
    } catch {
      guard !Task.isCancelled, !error.isCancellation else { return }

      sdkError = error as? Pokespeare.Error ?? .unknown
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

  /// Stores `pokemon` in the history, both in memory and in the model context.
  private func persist(_ pokemon: Pokemon) {
    guard let modelContext else { return }

    modelContext.insert(pokemon)
    try? modelContext.save()

    recentlySearched.insert(pokemon, at: .zero)
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

private extension Error {
  /// Whether this error means "the work was cancelled" rather than "the work failed".
  ///
  /// A cancelled search is a normal outcome of typing a new one: it must not raise an alert.
  var isCancellation: Bool {
    if self is CancellationError {
      return true
    }

    if let urlError = self as? URLError {
      return urlError.code == .cancelled
    }

    if case let .networkError(urlError) = self as? Pokespeare.Error {
      return urlError.code == .cancelled
    }

    return false
  }
}
