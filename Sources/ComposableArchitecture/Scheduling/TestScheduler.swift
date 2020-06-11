import Foundation
import RxSwift
import RxTest

private let testSchedulerResultion = 0.01

extension TestScheduler {

  public static func `default`(withInitialClock initialClock: Int = 0) -> TestScheduler {
    TestScheduler(
      initialClock: initialClock, resolution: testSchedulerResultion, simulateProcessingDelay: false
    )
  }

  public func advance(by: TimeInterval = 0) {
    self.advanceTo(self.clock + Int(by * (1 / testSchedulerResultion)))
  }

  public func tick() {
    self.advanceTo(self.clock + 1)
  }

  public func run() {
    self.advanceTo(Int(Date.distantFuture.timeIntervalSince1970))
  }

}
