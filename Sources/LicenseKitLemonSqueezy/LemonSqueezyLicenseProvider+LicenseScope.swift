extension LemonSqueezyLicenseProvider {
  /// Accepted Lemon Squeezy store, product, and variant scope for license keys.
  public struct LicenseScope: Equatable, Hashable, Sendable {
    /// Accepts license keys from any Lemon Squeezy store, product, or variant.
    public static let any = Self()

    /// Accepted Lemon Squeezy store ID.
    ///
    /// When set, licenses from other stores are rejected.
    public let storeID: String?
    /// Accepted Lemon Squeezy product ID.
    ///
    /// When set, licenses from other products are rejected.
    public let productID: String?
    /// Accepted Lemon Squeezy variant IDs.
    ///
    /// When non-empty, other variants are rejected.
    public let variantIDs: Set<String>

    /// Creates a license scope.
    public init(
      storeID: String? = nil,
      productID: String? = nil,
      variantIDs: Set<String> = []
    ) {
      self.storeID = storeID?.lemonSqueezyTrimmedNonEmpty
      self.productID = productID?.lemonSqueezyTrimmedNonEmpty
      self.variantIDs = Set(variantIDs.compactMap(\.lemonSqueezyTrimmedNonEmpty))
    }
  }
}
