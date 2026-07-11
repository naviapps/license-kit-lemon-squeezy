extension LemonSqueezyLicenseProvider.LicenseScope {
  func contains(_ context: LemonSqueezyLicenseContext) -> Bool {
    if let storeID, context.storeID != storeID {
      return false
    }
    if let productID, context.productID != productID {
      return false
    }
    if variantIDs.isEmpty == false {
      guard let variantID = context.variantID else { return false }
      return variantIDs.contains(variantID)
    }
    return true
  }
}
