import Foundation

/// The response of the `https://api.funtranslations.com/translate/shakespeare.json?text={description}` endpoint.
struct ShakespeareanTranslationResponse: Codable {
  enum ContentsKeys: String, CodingKey {
    case translated
    case original = "text"
  }

  enum CodingKeys: CodingKey {
    case contents
  }

  /// The translated description.
  let translated: String

  /// The original description.
  let original: String

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let contentsContainer = try container.nestedContainer(keyedBy: ContentsKeys.self, forKey: .contents)
    translated = try contentsContainer.decode(String.self, forKey: .translated)
    original = try contentsContainer.decode(String.self, forKey: .original)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var contentsContainer = container.nestedContainer(keyedBy: ContentsKeys.self, forKey: .contents)
    try contentsContainer.encode(translated, forKey: .translated)
    try contentsContainer.encode(original, forKey: .original)
  }

  internal init(translated: String, original: String) {
    self.translated = translated
    self.original = original
  }
}
