import Foundation
import LicenseKit
import LicenseKitLemonSqueezy
import XCTest

@MainActor
final class LicenseKitLemonSqueezyPublicAPITests: XCTestCase {
  func testConfigurationScopeAndProviderAPIsAreUsableFromPublicImport() async throws {
    let apiBaseURL = try XCTUnwrap(URL(string: "https://licenses.example.com"))
    let scope = LemonSqueezyLicenseProvider.LicenseScope(
      storeID: " store_1 ",
      productID: " product_1 ",
      variantIDs: [" variant_1 ", "variant_1", "variant_2", " "]
    )
    let configuration = LemonSqueezyLicenseProvider.Configuration(
      apiBaseURL: apiBaseURL,
      activationInstanceName: " Example App ",
      maximumRequestAttempts: 0,
      baseRetryDelay: .zero,
      licenseScope: scope
    )
    let provider = LemonSqueezyLicenseProvider(configuration: configuration)

    XCTAssertEqual(configuration.apiBaseURL, apiBaseURL)
    XCTAssertEqual(configuration.activationInstanceName, "Example App")
    XCTAssertEqual(configuration.maximumRequestAttempts, 1)
    XCTAssertEqual(configuration.baseRetryDelay, .milliseconds(1))
    XCTAssertEqual(configuration.licenseScope.storeID, "store_1")
    XCTAssertEqual(configuration.licenseScope.productID, "product_1")
    XCTAssertEqual(configuration.licenseScope.variantIDs, ["variant_1", "variant_2"])
    assertSendable(scope)
    assertSendable(configuration)
    assertSendable(provider)
    assertHashable(scope)
    XCTAssertEqual(
      LemonSqueezyLicenseProvider.LicenseScope(
        storeID: " ",
        productID: "\n",
        variantIDs: [" ", "\n"]
      ),
      .any
    )
    XCTAssertEqual(LemonSqueezyLicenseProvider.LicenseScope.any.variantIDs, [])
    XCTAssertEqual(LemonSqueezyLicenseProvider.source.identifier, "lemon-squeezy")
    assertHashable(LemonSqueezyLicenseProvider.source)

    await assertProviderRequestFailure(
      message: "Lemon Squeezy activation requires a license key."
    ) {
      _ = try await provider.activate(.automatic)
    }
    let validation = try await provider.validate(
      try makeLicenseActivation(
        LicenseActivation(
          source: try makeLicenseSource("other"),
          planIdentifier: "variant_1",
          activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
          licenseKey: "KEY"
        )),
      validationIdentifier: "instance_1"
    )
    XCTAssertFalse(validation.isValid)

    await assertProviderRequestFailure(
      message: "Activation is not a Lemon Squeezy license activation."
    ) {
      try await provider.deactivate(
        try makeLicenseActivation(
          LicenseActivation(
            source: try makeLicenseSource("other"),
            planIdentifier: "variant_1",
            activatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            licenseKey: "KEY"
          )
        )
      )
    }
  }

  func testReadmeLicenseManagerIntegrationIsUsableFromPublicImport() async throws {
    let provider = LemonSqueezyLicenseProvider(
      configuration: LemonSqueezyLicenseProvider.Configuration(
        activationInstanceName: "Example App",
        licenseScope: LemonSqueezyLicenseProvider.LicenseScope(
          storeID: "123",
          productID: "456",
          variantIDs: ["789"]
        )
      )
    )
    let activationStorage = PublicActivationStorage()

    let licenseManager = LicenseManager(
      provider: provider,
      activationStorage: activationStorage
    )

    try activationStorage.delete()
    XCTAssertNil(licenseManager.source)
    XCTAssertFalse(licenseManager.isLicensed)
    if licenseManager.needsRefresh() {
      _ = try await licenseManager.refresh()
    }
  }

  private func assertProviderRequestFailure(
    message expectedMessage: String,
    _ operation: () async throws -> Void
  ) async {
    do {
      try await operation()
      XCTFail("Expected request failure.")
    } catch LicenseProviderError.requestFailure(let message) {
      XCTAssertEqual(message, expectedMessage)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

}

private func assertHashable<Value: Hashable>(_: Value) {}

private func assertSendable<Value: Sendable>(_: Value) {}

private final class PublicActivationStorage: @unchecked Sendable, LicenseActivationStorage {
  private let lock = NSLock()
  private var activation: LicenseActivation?

  func save(_ activation: LicenseActivation) throws {
    lock.withLock {
      self.activation = activation
    }
  }

  func load() throws -> LicenseActivation? {
    lock.withLock { activation }
  }

  func delete() throws {
    lock.withLock {
      activation = nil
    }
  }
}
