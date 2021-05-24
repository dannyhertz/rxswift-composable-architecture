import RxSwift

// This file provides support for `Store`’s `sendingQueue`.

extension Reducer {
  /// Creates a reducer whose returned `Effect`s run via the specified scheduler.
  ///
  /// - Parameter scheduler: The scheduler on which the created `Reducer`’s `Effect`s should run.
  func receive(on scheduler: SchedulerType) -> Self {
    Self { state, action, environment in
      self(&state, action, environment)
        .observeOn(scheduler)
        .eraseToEffect()
    }
  }
}

extension ObservableType {
  /// Returns an Observable that runs on the specified scheduler.
  ///
  /// - Parameter optional: If non-nil, the scheduler on which to run. Otherwise, the scheduler is unchanged.
  func observeOn(optional someScheduler: SchedulerType?) -> Observable<Element> {
    if let scheduler = someScheduler {
      return asObservable().observeOn(scheduler)
    } else {
      return asObservable()
    }
  }
}
