import Foundation
import SwiftData

@Model
final class Pokemon {
  /// The name of the Pokémon, and the natural key of the history.
  ///
  /// The uniqueness constraint lives here rather than on a generated identifier, where it
  /// could never fail: two searches for the same Pokémon are the same history entry.
  @Attribute(.unique)
  var name: String

  var shakespeareanDescription: String

  var spriteUrl: URL?

  /// When the Pokémon was last searched for. Drives the ordering of the history.
  var searchDate: Date

  init(name: String, shakespeareanDescription: String, spriteUrl: URL?) {
    self.name = name.capitalized
    self.shakespeareanDescription = shakespeareanDescription
    self.spriteUrl = spriteUrl
    self.searchDate = Date()
  }
}
