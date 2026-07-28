import Foundation
import Pokespeare
import Testing

extension Pokespeare {
  static let stubDescription = "When several of these POKéMON gather, their electricity could build and cause lightning storms."

  static let stubSpriteURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png")!

  /// A stub SDK. Both endpoints succeed unless overridden.
  ///
  /// No protocol and no mock class: `Pokespeare` is a struct of closures, so substituting
  /// it is just passing different closures.
  static func stub(
    description: @escaping @Sendable (_ name: String) async throws -> String = { _ in stubDescription },
    sprite: @escaping @Sendable (_ name: String) async throws -> URL = { _ in stubSpriteURL }
  ) -> Self {
    .init(description: description, sprite: sprite)
  }

  /// A stub that must never be called.
  static func unimplemented(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
    .init(
      description: { name in
        Issue.record("Unexpected description(for: \(name))", sourceLocation: sourceLocation)
        throw CancellationError()
      },
      sprite: { name in
        Issue.record("Unexpected sprite(for: \(name))", sourceLocation: sourceLocation)
        throw CancellationError()
      }
    )
  }
}
