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
  ///
  /// Readable internally so tests can await a search that is otherwise fire-and-forget.
  private(set) var searchTask: Task<Void, Never>?

  /// The model context used to persist the history.
  ///
  /// Required, not an optional set later from `onAppear`: every persistence path used to
  /// be a silent no-op whenever it happened to be `nil`.
  private let modelContext: ModelContext

  init(modelContext: ModelContext, pokespeare: Pokespeare = .live) {
    self.modelContext = modelContext
    self.pokespeare = pokespeare

    fetchHistory()
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
  /// Setting it to `false` dismisses the alert by clearing the error. Setting it to `true`
  /// is not meaningful — an alert needs an error to show — so it is ignored rather than
  /// silently treated as a dismissal, which is what the previous setter did.
  var isErrorVisible: Bool {
    get {
      sdkError != nil
    }
    set {
      guard !newValue else { return }

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

    if let pokemon = recentlySearched.first(where: { $0.name.lowercased() == searchText.lowercased() }) {
      markAsJustSearched(pokemon)
      pokemonDetail = pokemon
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
    recentlySearched.forEach { modelContext.delete($0) }
    recentlySearched.removeAll()

    save()
    historyAlertConfirmation = false
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

  /// Initializes a `Pokespeare.PokemonViewModel` with the given `pokemon` then passed to the `Pokespeare.PokemonView`.
  ///
  /// - Parameters: The Pokémon source information.
  /// - Returns: An instance of `Pokespeare.PokemonViewModel`.
  func pokemonViewModel(for pokemon: Pokemon) -> PokemonViewModel {
    .init(name: pokemon.name, description: pokemon.shakespeareanDescription, spriteUrl: pokemon.spriteUrl)
  }

  /// Stores `pokemon` in the history, both in memory and in the model context.
  private func persist(_ pokemon: Pokemon) {
    modelContext.insert(pokemon)
    recentlySearched.insert(pokemon, at: .zero)

    save()
  }

  /// Fetches the history from SwiftData persistency container.
  private func fetchHistory() {
    let fetchDescriptor = FetchDescriptor<Pokemon>(sortBy: [SortDescriptor(\.searchDate, order: .reverse)])

    guard let fetched = try? modelContext.fetch(fetchDescriptor) else { return }

    recentlySearched = fetched
  }

  /// Moves `pokemon` back to the top of the history.
  ///
  /// A plain mutation: the entry used to be deleted and recreated just to refresh its
  /// timestamp, which threw away the row's identity on every repeated search.
  private func markAsJustSearched(_ pokemon: Pokemon) {
    pokemon.searchDate = Date()
    recentlySearched.sort { $0.searchDate > $1.searchDate }

    save()
  }

  /// Commits pending changes to the store.
  private func save() {
    try? modelContext.save()
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
