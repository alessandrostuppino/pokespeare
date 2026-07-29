/// The request of the `https://api.funtranslations.com/translate/shakespeare.json` endpoint.
struct ShakespeareanTranslationRequest: HTTPCodableRequest {
  typealias ResponseType = ShakespeareanTranslationResponse

  var host = Constants.Host.translation

  var path = [ "translate", "shakespeare.json" ]

  var method = HTTPMethod.post

  /// The text travels in the body rather than in the query string: a Pokémon description
  /// is long enough to risk URL length limits, and query strings end up in access logs.
  var body: HTTPRequestBody? {
    .form([ "text": text ])
  }

  /// The text to translate in Shakespearean.
  var text: String
}
