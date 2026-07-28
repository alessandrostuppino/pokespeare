import Foundation

/// A protocol that defines requirements for an object that can be converted into a `URLRequest`.
protocol URLRequestConvertible {
  /// The `URLRequest` representation of the object.
  var urlRequest: URLRequest? { get }
}
