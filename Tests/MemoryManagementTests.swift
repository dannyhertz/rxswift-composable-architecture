import ComposableArchitecture
import RxSwift
import RxTest
import XCTest

final class MemoryManagementTests: XCTestCase {
  var disposeBag = DisposeBag()

  func testOwnership_ScopeHoldsOntoParent() {
    let counterReducer = Reducer<Int, Void, Void> { state, _, _ in
      state += 1
      return .none
    }
    let store = Store(initialState: 0, reducer: counterReducer, environment: ())
      .scope(state: { "\($0)" })
      .scope(state: { Int($0)! })
    let viewStore = ViewStore(store)

    var count = 0
    viewStore.publisher
      .subscribe(onNext: { count = $0 })
      .disposed(by: disposeBag)

    XCTAssertEqual(count, 0)
    viewStore.send(())
    XCTAssertEqual(count, 1)
  }

  func testOwnership_ViewStoreHoldsOntoStore() {
    let counterReducer = Reducer<Int, Void, Void> { state, _, _ in
      state += 1
      return .none
    }
    let viewStore = ViewStore(Store(initialState: 0, reducer: counterReducer, environment: ()))

    var count = 0
    viewStore.publisher
      .subscribe(onNext: { count = $0 })
      .disposed(by: disposeBag)

    XCTAssertEqual(count, 0)
    viewStore.send(())
    XCTAssertEqual(count, 1)
  }
}
