/// The request of the `https://api.funtranslations.com/translate/shakespeare.json?text={text}` endpoint.
struct ShakespeareanTranslationRequest: HTTPCodableRequest {
  typealias ResponseType = ShakespeareanTranslationResponse

  var host = Constants.Host.translation

  var path = [ "translate", "shakespeare.json" ]

  var method = HTTPMethod.post

  var query: QueryParameters? {
    [ "text": text ]
  }

  /// The text to translate in Shakespearean.
  var text: String
}
