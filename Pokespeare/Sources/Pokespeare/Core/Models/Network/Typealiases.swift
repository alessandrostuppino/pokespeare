import Foundation

/// Typealias for a dictionary representing request headers.
public typealias HTTPHeaders = [String: String]

/// Typealias for a dictionary representing request parameters.
public typealias QueryParameters = [String: LosslessStringConvertible]

/// Typealias for a dictionary representing the object passed as body request.
public typealias HTTPBody = [String: Any]