/// The supported HTTP methods.
public enum HTTPMethod: String {
  case connect = "CONNECT"
  
  case delete = "DELETE"
  
  case get = "GET"
  
  case head = "HEAD"
  
  case options = "OPTIONS"
  
  case patch = "PATCH"
  
  case post = "POST"
  
  case put = "PUT"
  
  case trace = "TRACE"
}

extension HTTPMethod {
  /// Whether the method allows request body.
  var bodyAllowed: Bool {
    return switch self {
      case .connect, .get, .head, .options, .trace: false
      case .delete, .patch, .post, .put: true
    }
  }
}
