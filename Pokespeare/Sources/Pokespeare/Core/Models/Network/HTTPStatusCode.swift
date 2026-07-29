/// The HTTP status codes the SDK treats specially, named rather than spelled inline.
enum HTTPStatusCode {
  static let notFound = 404
  static let tooManyRequests = 429

  /// The range treated as success.
  static let successRange = 200..<300

  /// The range the server blames on itself, and which a retry could survive.
  static let serverErrorRange = 500..<600
}
