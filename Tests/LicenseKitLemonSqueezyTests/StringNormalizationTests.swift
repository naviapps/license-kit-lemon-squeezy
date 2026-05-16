import XCTest

@testable import LicenseKitLemonSqueezy

final class StringNormalizationTests: XCTestCase {
  func testLemonSqueezyTrimmedNonEmptyReturnsTrimmedValue() {
    XCTAssertEqual("  value \n".lemonSqueezyTrimmedNonEmpty, "value")
  }

  func testLemonSqueezyTrimmedNonEmptyReturnsNilForBlankValue() {
    XCTAssertNil("".lemonSqueezyTrimmedNonEmpty)
    XCTAssertNil(" \n\t ".lemonSqueezyTrimmedNonEmpty)
    XCTAssertNil("\u{00A0}".lemonSqueezyTrimmedNonEmpty)
  }

  func testLemonSqueezyTrimmedNonEmptyPreservesInternalWhitespace() {
    XCTAssertEqual("  alpha  beta  ".lemonSqueezyTrimmedNonEmpty, "alpha  beta")
  }
}
