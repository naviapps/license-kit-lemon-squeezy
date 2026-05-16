import Foundation

struct LemonSqueezyRetryPolicy: Sendable {
  let maximumAttempts: Int
  let baseDelayMilliseconds: Int

  init(maximumAttempts: Int = 3, baseDelayMilliseconds: Int = 200) {
    self.maximumAttempts = max(1, maximumAttempts)
    self.baseDelayMilliseconds = max(1, baseDelayMilliseconds)
  }

  func shouldRetry(statusCode: Int, afterAttempt attempt: Int) -> Bool {
    attempt < maximumAttempts && (statusCode == 429 || (500...599).contains(statusCode))
  }

  func delayNanoseconds(afterAttempt attempt: Int, retryAfterSeconds: Int?) -> UInt64 {
    if let retryAfterSeconds, retryAfterSeconds >= 0 {
      return Self.saturatedMultiply(UInt64(retryAfterSeconds), by: 1_000_000_000)
    }
    let baseDelayNanos = Self.saturatedMultiply(UInt64(baseDelayMilliseconds), by: 1_000_000)
    let shift = max(0, attempt - 1)
    guard shift < UInt64.bitWidth else { return UInt64.max }
    let shifted = baseDelayNanos.multipliedReportingOverflow(by: UInt64(1) << UInt64(shift))
    return shifted.overflow ? UInt64.max : shifted.partialValue
  }

  func retryAfterSeconds(from response: HTTPURLResponse, now: Date = Date()) -> Int? {
    guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
    let trimmedValue = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    if let seconds = Int(trimmedValue), seconds >= 0 { return seconds }
    guard let date = Self.httpDate(from: trimmedValue, now: now) else { return nil }
    return max(0, Int(ceil(date.timeIntervalSince(now))))
  }

  private static func saturatedMultiply(_ lhs: UInt64, by rhs: UInt64) -> UInt64 {
    let result = lhs.multipliedReportingOverflow(by: rhs)
    return result.overflow ? UInt64.max : result.partialValue
  }

  private static func httpDate(from value: String, now: Date) -> Date? {
    for candidate in httpDateCandidates(from: value, now: now) {
      if let date = httpDateFormatter(format: candidate.format).date(from: candidate.value) {
        return date
      }
    }
    return nil
  }

  private static func httpDateCandidates(
    from value: String,
    now: Date
  ) -> [(value: String, format: String)] {
    var candidates: [(value: String, format: String)] = []
    if let normalizedRFC850Date = normalizedRFC850Date(value, now: now) {
      candidates.append(
        (value: normalizedRFC850Date, format: "EEEE',' dd'-'MMM'-'yyyy HH':'mm':'ss zzz")
      )
    }
    candidates.append(contentsOf: [
      (value: value, format: "EEE',' dd MMM yyyy HH':'mm':'ss zzz"),
      (value: value, format: "EEE MMM d HH':'mm':'ss yyyy"),
    ])
    return candidates
  }

  private static func normalizedRFC850Date(_ value: String, now: Date) -> String? {
    let parts = value.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
    guard parts.count == 3 else { return nil }
    let dateParts = parts[1].split(separator: "-", omittingEmptySubsequences: false)
    guard dateParts.count == 3, let year = Int(dateParts[2]) else { return nil }
    let currentYear =
      Calendar(identifier: .gregorian)
      .dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: now)
      .year ?? 0
    let currentCentury = currentYear - currentYear % 100
    var fullYear = currentCentury + year
    if fullYear - currentYear > 50 { fullYear -= 100 }
    return "\(parts[0]) \(dateParts[0])-\(dateParts[1])-\(fullYear) \(parts[2])"
  }

  private static func httpDateFormatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = format
    formatter.isLenient = false
    return formatter
  }
}
