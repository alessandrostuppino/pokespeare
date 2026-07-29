import Foundation

/// A protocol that defines requirements for an HTTP request.
protocol HTTPRequest: URLRequestConvertible {
  /// The host of the API `URL`.
  var host: String { get }

  /// The path of the request.
  var path: [String] { get }

  /// The HTTP method of the request.
  var method: HTTPMethod { get }

  /// The query parameters to include in the request. Defaults to `nil`.
  var query: QueryParameters? { get }

  /// The body to include in the request. Defaults to `nil`.
  var body: HTTPBody? { get }

  /// The default headers added to all requests. Provides a default value for requests that accept json content.
  var defaultHeaders: HTTPHeaders { get }

  /// The custom header added to specific requests. Defaults to `[:]`.
  var customHeaders: HTTPHeaders { get }

  /// The desired time interval before a timeout error is returned.
  var timeout: TimeInterval { get }
}

extension HTTPRequest {
  var query: QueryParameters? { nil }

  var body: HTTPBody? { nil }

  var defaultHeaders: HTTPHeaders {
    [
      "Content-Type": "application/json",
      "Accept": "application/json"
    ]
  }

  var customHeaders: HTTPHeaders {
    [:]
  }

  var timeout: TimeInterval {
    Constants.requestTimeout
  }

  var urlRequest: URLRequest? {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = host
    urlComponents.path = "/" + path.joined(separator: "/")
    urlComponents.queryItems = query?.map { key, value in
      URLQueryItem(name: key.description, value: value.description)
    }

    guard let url = urlComponents.url else {
      return nil
    }

    var urlRequest = URLRequest(url: url, timeoutInterval: timeout)
    urlRequest.httpMethod = method.rawValue

    if method.bodyAllowed {
      if let body, let httpBody = try? JSONSerialization.data(withJSONObject: body) {
        urlRequest.httpBody = httpBody
      } else {
        urlRequest.httpBody = Data("{}".utf8)
      }
    }

    defaultHeaders.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    customHeaders.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

    return urlRequest
  }
}
