import Foundation

/// A protocol that defines requirements for an HTTP request.
protocol HTTPRequest {
  /// The host of the API `URL`.
  var host: String { get }

  /// The path of the request.
  var path: [String] { get }

  /// The HTTP method of the request. Defaults to `.get`.
  var method: HTTPMethod { get }

  /// The body to include in the request. Defaults to `nil`.
  var body: HTTPRequestBody? { get }

  /// The headers added to the request.
  var headers: HTTPHeaders { get }

  /// The desired time interval before a timeout error is returned.
  var timeout: TimeInterval { get }

  /// Builds the `URLRequest` for this request.
  ///
  /// - Throws: ``APIError/invalidURL`` when the pieces do not form a valid `URL`.
  func makeURLRequest() throws -> URLRequest
}

extension HTTPRequest {
  var method: HTTPMethod { .get }

  var body: HTTPRequestBody? { nil }

  var headers: HTTPHeaders { ["Accept": "application/json"] }

  var timeout: TimeInterval { Constants.requestTimeout }

  func makeURLRequest() throws -> URLRequest {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = host
    urlComponents.path = "/" + path.joined(separator: "/")

    guard let url = urlComponents.url else {
      throw APIError.invalidURL
    }

    var urlRequest = URLRequest(url: url, timeoutInterval: timeout)
    urlRequest.httpMethod = method.rawValue

    headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

    if let body {
      urlRequest.httpBody = body.encoded()
      urlRequest.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
    }

    return urlRequest
  }
}
