import XCTest

@testable import LicenseKitLemonSqueezy

final class LemonSqueezyLicenseScopeTests: XCTestCase {
  func testNormalizesScopeIdentifiers() {
    let scope = LemonSqueezyLicenseScope(
      storeID: " store_1 ",
      productID: " product_1 ",
      variantIDs: [" variant_1 ", "variant_1", "variant_2", " "]
    )

    XCTAssertEqual(scope.storeID, "store_1")
    XCTAssertEqual(scope.productID, "product_1")
    XCTAssertEqual(scope.variantIDs, ["variant_1", "variant_2"])
  }

  func testIgnoresBlankScopeIdentifiers() {
    let scope = LemonSqueezyLicenseScope(
      storeID: " ",
      productID: "\n",
      variantIDs: [" ", "\n"]
    )

    XCTAssertNil(scope.storeID)
    XCTAssertNil(scope.productID)
    XCTAssertTrue(scope.variantIDs.isEmpty)
  }

  func testAnyAcceptsAnyLicenseContext() {
    let scope = LemonSqueezyLicenseScope.any

    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: nil, productID: nil, variantID: nil)
      )
    )
    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: "store_1", productID: "product_1", variantID: "variant_1")
      )
    )
  }

  func testRejectsUnexpectedStoreID() {
    let scope = makeScope(
      storeID: "store_1",
      productID: nil,
      variantIDs: []
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: "store_2", productID: nil, variantID: nil)
      )
    )
  }

  func testRejectsMissingStoreIDWhenStoreIsConstrained() {
    let scope = makeScope(
      storeID: "store_1",
      productID: nil,
      variantIDs: []
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: nil, productID: nil, variantID: nil)
      )
    )
  }

  func testAcceptsMatchingStoreIDWhenOtherDimensionsAreUnconstrained() {
    let scope = makeScope(
      storeID: "store_1",
      productID: nil,
      variantIDs: []
    )

    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: "store_1", productID: "product_2", variantID: "variant_2")
      )
    )
  }

  func testRejectsUnexpectedProductID() {
    let scope = makeScope(
      storeID: nil,
      productID: "product_1",
      variantIDs: []
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: nil, productID: "product_2", variantID: nil)
      )
    )
  }

  func testRejectsMissingProductIDWhenProductIsConstrained() {
    let scope = makeScope(
      storeID: nil,
      productID: "product_1",
      variantIDs: []
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: nil, productID: nil, variantID: nil)
      )
    )
  }

  func testAcceptsMatchingProductIDWhenOtherDimensionsAreUnconstrained() {
    let scope = makeScope(
      storeID: nil,
      productID: "product_1",
      variantIDs: []
    )

    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: "store_2", productID: "product_1", variantID: "variant_2")
      )
    )
  }

  func testRejectsMissingVariantWhenVariantsAreConstrained() {
    let scope = makeScope(
      storeID: nil,
      productID: nil,
      variantIDs: ["variant_1"]
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: nil, productID: nil, variantID: nil)
      )
    )
  }

  func testRejectsUnexpectedVariantID() {
    let scope = makeScope(
      storeID: nil,
      productID: nil,
      variantIDs: ["variant_1"]
    )

    XCTAssertFalse(
      scope.contains(
        makeContext(storeID: nil, productID: nil, variantID: "variant_2")
      )
    )
  }

  func testAcceptsMatchingVariantIDWhenOtherDimensionsAreUnconstrained() {
    let scope = makeScope(
      storeID: nil,
      productID: nil,
      variantIDs: ["variant_1"]
    )

    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: "store_2", productID: "product_2", variantID: "variant_1")
      )
    )
  }

  func testAcceptsMatchingStoreProductAndVariant() {
    let scope = makeScope(
      storeID: "store_1",
      productID: "product_1",
      variantIDs: ["variant_1", "variant_2"]
    )

    XCTAssertTrue(
      scope.contains(
        makeContext(storeID: "store_1", productID: "product_1", variantID: "variant_2")
      )
    )
  }

  private func makeScope(
    storeID: String?,
    productID: String?,
    variantIDs: Set<String>
  ) -> LemonSqueezyLicenseScope {
    LemonSqueezyLicenseScope(
      storeID: storeID,
      productID: productID,
      variantIDs: variantIDs
    )
  }

  private func makeContext(
    storeID: String?,
    productID: String?,
    variantID: String?
  ) -> LemonSqueezyLicenseContext {
    LemonSqueezyLicenseContext(
      licenseKey: nil,
      storeID: storeID,
      productID: productID,
      variantID: variantID,
      activationID: nil,
      activationCreatedAt: nil,
      expiresAt: nil,
      remainingActivations: nil,
      status: nil,
      isValid: nil,
      message: nil
    )
  }
}
