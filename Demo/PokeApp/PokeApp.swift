import Foundation
import SwiftData
import SwiftUI

@main
struct PokeApp: App {
  /// Built here rather than through `.modelContainer(for:)` so the search view model can
  /// take its context as a constructor dependency instead of receiving it from `onAppear`.
  private let modelContainer: ModelContainer

  init() {
    modelContainer = Self.makeModelContainer()
  }

  var body: some Scene {
    WindowGroup {
      SearchView(viewModel: SearchViewModel(modelContext: modelContainer.mainContext))
    }
    .modelContainer(modelContainer)
  }

  /// Opens the history store, rebuilding it from scratch if the existing one cannot be read.
  ///
  /// The history is a cache of past searches, not user-authored content: discarding it
  /// costs a few network calls, while refusing to launch costs the whole app. A schema
  /// change SwiftData cannot migrate must not become a crash loop after an update.
  private static func makeModelContainer() -> ModelContainer {
    let url = URL.applicationSupportDirectory.appending(path: "PokeApp.store")
    let schema = Schema([Pokemon.self])
    let configuration = ModelConfiguration(schema: schema, url: url)

    if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
      return container
    }

    // SQLite keeps its write-ahead log alongside the store; leaving those behind would
    // make the retry fail for the same reason.
    for path in [url, url.appendingPathExtension("shm"), url.appendingPathExtension("wal")] {
      try? FileManager.default.removeItem(at: path)
    }

    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Could not create the model container: \(error)")
    }
  }
}
