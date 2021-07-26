//import RxSwift
import ComposableArchitecture
import RxSwift
import RxTest
import XCTest

final class TimerTests: XCTestCase {
  var disposeBag = DisposeBag()

  func testTimer() {
    let scheduler = TestScheduler.default()

    var count = 0

    Effect<Int>.timer(id: 1, every: .seconds(1), on: scheduler)
      .subscribe(onNext: { _ in count += 1 })
      .disposed(by: disposeBag)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 1)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 2)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 3)

    scheduler.advance(by: 3)
    XCTAssertEqual(count, 6)
  }

  func testInterleavingTimer() {
    let scheduler = TestScheduler.default()

    var count2 = 0
    var count3 = 0

    Effect.merge(
      Effect<Int>.timer(id: 1, every: .seconds(2), on: scheduler)
        .do(onNext: { _ in count2 += 1 })
        .eraseToEffect(),
      Effect<Int>.timer(id: 2, every: .seconds(3), on: scheduler)
        .do(onNext: { _ in count3 += 1 })
        .eraseToEffect()
    )
    .subscribe(onNext: { _ in })
    .disposed(by: disposeBag)

    scheduler.advance(by: 1)
    XCTAssertEqual(count2, 0)
    XCTAssertEqual(count3, 0)
    scheduler.advance(by: 1)
    XCTAssertEqual(count2, 1)
    XCTAssertEqual(count3, 0)
    scheduler.advance(by: 1)
    XCTAssertEqual(count2, 1)
    XCTAssertEqual(count3, 1)
    scheduler.advance(by: 1)
    XCTAssertEqual(count2, 2)
    XCTAssertEqual(count3, 1)
  }

  func testTimerCancellation() {
    let scheduler = TestScheduler.default()

    struct CancelToken: Hashable {}

    var firstCount = 0
    var secondCount = 0

    Effect<Int>.timer(id: CancelToken(), every: .seconds(2), on: scheduler)
      .subscribe(onNext: { _ in firstCount += 1 })
      .disposed(by: disposeBag)

    scheduler.advance(by: 2)

    XCTAssertEqual(firstCount, 1)

    scheduler.advance(by: 2)

    XCTAssertEqual(firstCount, 2)

    Effect<Int>.timer(id: CancelToken(), every: .seconds(2), on: scheduler)
      .subscribe(onNext: { _ in secondCount += 1 })
      .disposed(by: disposeBag)

    scheduler.advance(by: 2)

    XCTAssertEqual(firstCount, 2)
    XCTAssertEqual(secondCount, 1)

    scheduler.advance(by: 2)

    XCTAssertEqual(firstCount, 2)
    XCTAssertEqual(secondCount, 2)
  }

  func testTimerCompletion() {
    let scheduler = TestScheduler.default()

    var count = 0

    Effect<Int>.timer(id: 1, every: .seconds(1), on: scheduler)
      .take(3)
      .subscribe(onNext: { _ in count += 1 })
      .disposed(by: disposeBag)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 1)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 2)

    scheduler.advance(by: 1)
    XCTAssertEqual(count, 3)

    scheduler.run()
    XCTAssertEqual(count, 3)
  }
}
