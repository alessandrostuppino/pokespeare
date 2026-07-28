import SwiftData
import Foundation

@Model
final class Pokemon: Identifiable {
  @Attribute(.unique)
  var id: String

  var name: String

  var shakespeareanDescription: String

  var spriteUrl: URL?

  var searchDate: Date

  init(name: String, shakespeareanDescription: String, spriteUrl: URL?) {
    self.id = UUID().uuidString
    self.name = name.capitalized
    self.shakespeareanDescription = shakespeareanDescription
    self.spriteUrl = spriteUrl
    self.searchDate = Date()
  }

  convenience init(pokemon: Pokemon) {
    self.init(name: pokemon.name, shakespeareanDescription: pokemon.shakespeareanDescription, spriteUrl: pokemon.spriteUrl)
  }
}
