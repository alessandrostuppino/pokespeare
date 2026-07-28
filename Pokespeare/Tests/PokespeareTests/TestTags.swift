import Foundation
import Testing

extension Tag {
  /// Marks tests that hit the live third-party APIs.
  ///
  /// These are non-deterministic by nature: they depend on network availability, on the
  /// remote services staying up, and on rate limits (FunTranslations allows 5 calls per
  /// hour and 60 per day). They are skipped unless `RUN_INTEGRATION_TESTS` is set, so the
  /// default suite stays deterministic and usable on CI.
  @Tag static var integration: Self
}

enum IntegrationTests {
  /// Whether the suites tagged `.integration` should run.
  static var isEnabled: Bool {
    ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] != nil
  }

  /// The message shown when an integration suite is skipped.
  static let skipReason: Comment = "Hits live APIs. Set RUN_INTEGRATION_TESTS=1 to run."
}
