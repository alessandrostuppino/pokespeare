import Foundation
import SwiftData
@testable import PokeApp

/// A throwaway SwiftData store, so tests exercise the real persistence code without
/// touching the app's store or leaking state between runs.
///
/// - Note: this is deliberately **not** `isStoredInMemoryOnly`. On the current toolchain
///   (Xcode 26.4 / iOS 26.4) any `fetch` against an in-memory container traps with
///   `SIGTRAP` inside SwiftData, while the same fetch against a file-backed store works.
///   Each call therefore gets its own file under the temporary directory, which the system
///   reclaims on its own.
@MainActor
enum TemporaryStore {
  /// Keeps every container built during the run alive.
  ///
  /// A `ModelContext` does not keep its container from being deallocated, and using a
  /// context whose container is gone traps. Holding them here for the lifetime of the test
  /// process is the simplest way to let call sites stay one-liners.
  private static var containers: [ModelContainer] = []

  static func makeContext() throws -> ModelContext {
    let url = URL.temporaryDirectory.appending(path: "PokeAppTests-\(UUID().uuidString).store")
    let schema = Schema([Pokemon.self])
    let container = try ModelContainer(
      for: schema,
      configurations: [ModelConfiguration(schema: schema, url: url)]
    )

    containers.append(container)

    return container.mainContext
  }
}
