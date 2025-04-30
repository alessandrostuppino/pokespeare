import Foundation
@testable import Pokespeare

class MockedSession: Session, @unchecked Sendable {
  private let _dataHandler: (URLRequest) async throws -> (Data, URLResponse)
  
  func dataHandler(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await _dataHandler(request)
  }
  
  init(dataHandler: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
    self._dataHandler = dataHandler
  }
}

extension MockedSession {
  static func failureSession(with error: any Error) -> MockedSession {
    .init { _ in
      throw error
    }
  }
}


extension MockedSession {
  static var unimplemented: MockedSession {
    .init { _ in
      fatalError("Unimplemented")
    }
  }
}
