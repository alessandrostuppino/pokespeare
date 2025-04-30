import SwiftData
import SwiftUI

@main
struct PokeApp: App {
  var body: some Scene {
    WindowGroup {
      SearchView()
    }
    .modelContainer(for: Pokemon.self)
  }
}
