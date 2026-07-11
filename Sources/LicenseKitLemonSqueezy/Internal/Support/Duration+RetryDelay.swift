extension Duration {
  static let lemonSqueezyMinimumRetryDelay = Duration(
    secondsComponent: 0,
    attosecondsComponent: 1_000_000_000_000_000
  )

  var lemonSqueezyIsPositive: Bool {
    let components = components
    return components.seconds > 0
      || (components.seconds == 0 && components.attoseconds > 0)
  }
}
