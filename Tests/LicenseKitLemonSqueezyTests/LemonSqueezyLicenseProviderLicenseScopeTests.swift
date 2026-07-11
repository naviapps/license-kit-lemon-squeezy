import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseProviderLicenseScopeTests: XCTestCase {
  func testMatchesConfiguredDimensions() {
    let cases: [Case] = [
      .init(
        name: "unconstrained scope accepts missing metadata",
        scope: .any,
        context: makeContext(),
        expected: true
      ),
      .init(
        name: "unconstrained scope accepts all metadata",
        scope: .any,
        context: makeContext(
          storeID: "store_1",
          productID: "product_1",
          variantID: "variant_1"
        ),
        expected: true
      ),
      .init(
        name: "store matches independently",
        scope: makeScope(storeID: "store_1"),
        context: makeContext(
          storeID: "store_1",
          productID: "product_2",
          variantID: "variant_2"
        ),
        expected: true
      ),
      .init(
        name: "store rejects a missing value",
        scope: makeScope(storeID: "store_1"),
        context: makeContext(),
        expected: false
      ),
      .init(
        name: "store rejects a different value",
        scope: makeScope(storeID: "store_1"),
        context: makeContext(storeID: "store_2"),
        expected: false
      ),
      .init(
        name: "product matches independently",
        scope: makeScope(productID: "product_1"),
        context: makeContext(
          storeID: "store_2",
          productID: "product_1",
          variantID: "variant_2"
        ),
        expected: true
      ),
      .init(
        name: "product rejects a missing value",
        scope: makeScope(productID: "product_1"),
        context: makeContext(),
        expected: false
      ),
      .init(
        name: "product rejects a different value",
        scope: makeScope(productID: "product_1"),
        context: makeContext(productID: "product_2"),
        expected: false
      ),
      .init(
        name: "variant matches independently",
        scope: makeScope(variantIDs: ["variant_1"]),
        context: makeContext(
          storeID: "store_2",
          productID: "product_2",
          variantID: "variant_1"
        ),
        expected: true
      ),
      .init(
        name: "variant rejects a missing value",
        scope: makeScope(variantIDs: ["variant_1"]),
        context: makeContext(),
        expected: false
      ),
      .init(
        name: "variant rejects a different value",
        scope: makeScope(variantIDs: ["variant_1"]),
        context: makeContext(variantID: "variant_2"),
        expected: false
      ),
      .init(
        name: "all configured dimensions match",
        scope: makeScope(
          storeID: "store_1",
          productID: "product_1",
          variantIDs: ["variant_1", "variant_2"]
        ),
        context: makeContext(
          storeID: "store_1",
          productID: "product_1",
          variantID: "variant_2"
        ),
        expected: true
      ),
    ]

    for testCase in cases {
      XCTAssertEqual(
        testCase.scope.contains(testCase.context),
        testCase.expected,
        testCase.name
      )
    }
  }

  private struct Case {
    let name: String
    let scope: LemonSqueezyLicenseProvider.LicenseScope
    let context: LemonSqueezyLicenseContext
    let expected: Bool
  }

  private func makeScope(
    storeID: String? = nil,
    productID: String? = nil,
    variantIDs: Set<String> = []
  ) -> LemonSqueezyLicenseProvider.LicenseScope {
    LemonSqueezyLicenseProvider.LicenseScope(
      storeID: storeID,
      productID: productID,
      variantIDs: variantIDs
    )
  }

  private func makeContext(
    storeID: String? = nil,
    productID: String? = nil,
    variantID: String? = nil
  ) -> LemonSqueezyLicenseContext {
    LemonSqueezyLicenseContext(
      licenseKey: nil,
      storeID: storeID,
      productID: productID,
      variantID: variantID,
      activationIdentifier: nil,
      activationCreatedAt: nil,
      expiresAt: nil,
      remainingActivations: nil,
      status: nil,
      isValid: nil,
      message: nil
    )
  }
}
