import Foundation

/// The body of an HTTP request.
///
/// Typed rather than `[String: Any]`: the encoding and the `Content-Type` always agree, and
/// the body cannot carry a value that does not survive serialisation.
enum HTTPRequestBody {
  /// `application/x-www-form-urlencoded` key/value pairs.
  case form([String: String])

  var contentType: String {
    switch self {
      case .form:
        "application/x-www-form-urlencoded"
    }
  }

  func encoded() -> Data {
    switch self {
      case let .form(fields):
        // Sorted so the same body always encodes to the same bytes.
        let encoded = fields
          .sorted { $0.key < $1.key }
          .map { "\($0.key.formURLEncoded)=\($0.value.formURLEncoded)" }
          .joined(separator: "&")

        return Data(encoded.utf8)
    }
  }
}

private extension String {
  /// Percent-encodes the receiver for use in a form body.
  ///
  /// `+` has to be escaped explicitly: it is legal in a query string but means a space in a
  /// form body, so leaving it would silently corrupt any text containing one.
  var formURLEncoded: String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "+&=")

    return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
  }
}
