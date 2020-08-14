import CoreLocation

/// A value type wrapper for `CLBeacon`. This type is necessary so that we can do equality checks
/// and write tests against its values.
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Beacon: Equatable {
  public let rawValue: CLBeacon?

  public var accuracy: CLLocationAccuracy
  public var major: NSNumber
  public var minor: NSNumber
  public var proximity: CLProximity
  public var rssi: Int

  public init(rawValue: CLBeacon) {
    self.rawValue = rawValue

    self.accuracy = rawValue.accuracy
    self.major = rawValue.major
    self.minor = rawValue.minor
    self.proximity = rawValue.proximity
    self.rssi = rawValue.rssi
  }

  init(
    accuracy: CLLocationAccuracy,
    major: NSNumber,
    minor: NSNumber,
    proximity: CLProximity,
    rssi: Int,
    timestamp: Date,
    uuid: UUID
  ) {
    self.rawValue = nil
    self.accuracy = accuracy
    self.major = major
    self.minor = minor
    self.proximity = proximity
    self.rssi = rssi
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.accuracy == rhs.accuracy
      && lhs.major == rhs.major
      && lhs.minor == rhs.minor
      && lhs.proximity == rhs.proximity
      && lhs.rssi == rhs.rssi
  }
}
