import Foundation
import RxRelay
import RxSwift

/// A store represents the runtime that powers the application. It is the object that you will pass
/// around to views that need to interact with the application.
///
/// You will typically construct a single one of these at the root of your application, and then use
/// the `scope` method to derive more focused stores that can be passed to subviews.
public final class Store<State, Action> {

  private var synchronousActionsToSend: [Action] = []
  private var isSending = false
  private var parentDisposable: Disposable?
  var effectDisposables = CompositeDisposable()
  private let reducer: (inout State, Action) -> Effect<Action>
  private let sendingQueue: DispatchQueue?

  private var stateRelay: BehaviorRelay<State>
  public private(set) var state: State {
    get { return stateRelay.value }
    set { stateRelay.accept(newValue) }
  }
  var observable: Observable<State> {
    return stateRelay.asObservable()
  }

  deinit {
    parentDisposable?.dispose()
    effectDisposables.dispose()
  }

  /// Initializes a store from an initial state, a reducer, and an environment.
  ///
  /// - Parameters:
  ///   - initialState: The state to start the application in.
  ///   - reducer: The reducer that powers the business logic of the application.
  ///   - environment: The environment of dependencies for the application.
  public convenience init<Environment>(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment,
    sendingQueue: DispatchQueue? = nil
  ) {
    let updatedReducer = sendingQueue
      // The ConcurrentDispatchQueueScheduler respects the incoming queue's attributes,
      // so if it is serial, events will still be observed serially.
      // See ConcurrentDispatchQueueScheduler's documentation for more.
      .map { reducer.receive(on: ConcurrentDispatchQueueScheduler(queue: $0)) }
      ?? reducer
    self.init(
      initialState: initialState,
      reducer: { updatedReducer.run(&$0, $1, environment) },
      sendingQueue: sendingQueue
    )
  }

  /// Scopes the store to one that exposes local state and actions.
  ///
  /// This can be useful for deriving new stores to hand to child views in an application. For
  /// example:
  ///
  ///     // Application state made from local states.
  ///     struct AppState { var login: LoginState, ... }
  ///     struct AppAction { case login(LoginAction), ... }
  ///
  ///     // A store that runs the entire application.
  ///     let store = Store(
  ///       initialState: AppState(),
  ///       reducer: appReducer,
  ///       environment: AppEnvironment()
  ///     )
  ///
  ///     // Construct a login view by scoping the store to one that works with only login domain.
  ///     LoginView(
  ///       store: store.scope(
  ///         state: { $0.login },
  ///         action: { AppAction.login($0) }
  ///       )
  ///     )
  ///
  /// Scoping in this fashion allows you to better modularize your application. In this case,
  /// `LoginView` could be extracted to a module that has no access to `AppState` or `AppAction`.
  ///
  /// Scoping also gives a view the opportunity to focus on just the state and actions it cares
  /// about, even if its feature domain is larger.
  ///
  /// For example, the above login domain could model a two screen login flow: a login form followed
  /// by a two-factor authentication screen. The second screen's domain might be nested in the
  /// first:
  ///
  ///     struct LoginState: Equatable {
  ///       var email = ""
  ///       var password = ""
  ///       var twoFactorAuth: TwoFactorAuthState?
  ///     }
  ///
  ///     enum LoginAction: Equatable {
  ///       case emailChanged(String)
  ///       case loginButtonTapped
  ///       case loginResponse(Result<TwoFactorAuthState, LoginError>)
  ///       case passwordChanged(String)
  ///       case twoFactorAuth(TwoFactorAuthAction)
  ///     }
  ///
  /// The login view holds onto a store of this domain:
  ///
  ///     struct LoginView: View {
  ///       let store: Store<LoginState, LoginAction>
  ///
  ///       var body: some View { ... }
  ///     }
  ///
  /// If its body were to use a view store of the same domain, this would introduce a number of
  /// problems:
  ///
  /// * The login view would be able to read from `twoFactorAuth` state. This state is only intended
  ///   to be read from the two-factor auth screen.
  ///
  /// * Even worse, changes to `twoFactorAuth` state would now cause SwiftUI to recompute
  ///   `LoginView`'s body unnecessarily.
  ///
  /// * The login view would be able to send `twoFactorAuth` actions. These actions are only
  ///   intended to be sent from the two-factor auth screen (and reducer).
  ///
  /// * The login view would be able to send non user-facing login actions, like `loginResponse`.
  ///   These actions are only intended to be used in the login reducer to feed the results of
  ///   effects back into the store.
  ///
  /// To avoid these issues, one can introduce a view-specific domain that slices off the subset of
  /// state and actions that a view cares about:
  ///
  ///     extension LoginView {
  ///       struct State: Equatable {
  ///         var email: String
  ///         var password: String
  ///       }
  ///
  ///       enum Action: Equatable {
  ///         case emailChanged(String)
  ///         case loginButtonTapped
  ///         case passwordChanged(String)
  ///       }
  ///     }
  ///
  /// One can also introduce a couple helpers that transform feature state into view state and
  /// transform view actions into feature actions.
  ///
  ///     extension LoginState {
  ///       var view: LoginView.State {
  ///         .init(email: self.email, password: self.password)
  ///       }
  ///     }
  ///
  ///     extension LoginView.Action {
  ///       var feature: LoginAction {
  ///         switch self {
  ///         case let .emailChanged(email)
  ///           return .emailChanged(email)
  ///         case .loginButtonTapped:
  ///           return .loginButtonTapped
  ///         case let .passwordChanged(password)
  ///           return .passwordChanged(password)
  ///         }
  ///       }
  ///     }
  ///
  /// With these helpers defined, `LoginView` can now scope its store's feature domain into its view
  /// domain:
  ///
  ///     var body: some View {
  ///       WithViewStore(
  ///         self.store.scope(state: { $0.view }, action: { $0.feature })
  ///       ) { viewStore in
  ///         ...
  ///       }
  ///     }
  ///
  /// This view store is now incapable of reading any state but view state (and will not recompute
  /// when non-view state changes), and is incapable of sending any actions but view actions.
  ///
  /// - Parameters:
  ///   - toLocalState: A function that transforms `State` into `LocalState`.
  ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
  /// - Returns: A new store with its domain (state and action) transformed.
  public func scope<LocalState, LocalAction>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalState, LocalAction> {
    let localStore = Store<LocalState, LocalAction>(
      initialState: toLocalState(self.state),
      reducer: { localState, localAction in
        self.send(fromLocalAction(localAction))
        localState = toLocalState(self.state)
        return .none
      },
      sendingQueue: sendingQueue
    )

    localStore.parentDisposable = self.observable
      .subscribe(onNext: { [weak localStore] newValue in
        localStore?.state = toLocalState(newValue)
      })

    return localStore
  }

  /// Scopes the store to one that exposes local state.
  ///
  /// - Parameter toLocalState: A function that transforms `State` into `LocalState`.
  /// - Returns: A new store with its domain (state and action) transformed.
  public func scope<LocalState>(
    state toLocalState: @escaping (State) -> LocalState
  ) -> Store<LocalState, Action> {
    self.scope(state: toLocalState, action: { $0 })
  }

  /// Scopes the store to a publisher of stores of more local state and local actions.
  ///
  /// - Parameters:
  ///   - toLocalState: A function that transforms a publisher of `State` into a publisher of
  ///     `LocalState`.
  ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
  /// - Returns: A publisher of stores with its domain (state and action) transformed.
  public func scope<O: ObservableType, LocalState, LocalAction>(
    state toLocalState: @escaping (Observable<State>) -> O,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Observable<Store<LocalState, LocalAction>>
  where O.Element == LocalState {

    func extractLocalState(_ state: State) -> LocalState? {
      var localState: LocalState?
      _ = toLocalState(Observable.just(state))
        .subscribe(onNext: { localState = $0 })
      return localState
    }

    return toLocalState(self.observable)
      .map { localState in
        let localStore = Store<LocalState, LocalAction>(
          initialState: localState,
          reducer: { localState, localAction in
            self.send(fromLocalAction(localAction))
            localState = extractLocalState(self.state) ?? localState
            return .none
          },
          sendingQueue: self.sendingQueue
        )

        localStore.parentDisposable = self.observable
          .subscribe(onNext: { [weak localStore] state in
            guard let localStore = localStore else { return }
            localStore.state = extractLocalState(state) ?? localStore.state
          })

        return localStore
      }
  }

  /// Scopes the store to a publisher of stores of more local state and local actions.
  ///
  /// - Parameter toLocalState: A function that transforms a publisher of `State` into a publisher
  ///   of `LocalState`.
  /// - Returns: A publisher of stores with its domain (state and action)
  ///   transformed.
  public func scope<O: ObservableType, LocalState>(
    state toLocalState: @escaping (Observable<State>) -> O
  ) -> Observable<Store<LocalState, Action>>
  where O.Element == LocalState {
    self.scope(state: toLocalState, action: { $0 })
  }

  public func send(_ action: Action) {
    if let queue = sendingQueue {
      queue.async { self._send(action) }
    } else {
      _send(action)
    }
  }

  private func _send(_ action: Action) {
    self.synchronousActionsToSend.append(action)

    while !self.synchronousActionsToSend.isEmpty {
      let action = self.synchronousActionsToSend.removeFirst()

      if self.isSending {
        assertionFailure(
          """
          The store was sent the action \(debugCaseOutput(action)) while it was already
          processing another action.

          This can happen for a few reasons:

          * The store was sent an action recursively. This can occur when you run an effect \
          directly in the reducer, rather than returning it from the reducer. Check the stack (⌘7) \
          to find frames corresponding to one of your reducers. That code should be refactored to \
          not invoke the effect directly.

          * The store has been sent actions from multiple threads. The `send` method is not \
          thread-safe, and should only ever be used from a single thread (typically the main \
          thread). Instead of calling `send` from multiple threads you should use effects to \
          process expensive computations on background threads so that it can be fed back into the \
          store.
          """
        )
      }
      self.isSending = true
      let effect = self.reducer(&self.state, action)
      self.isSending = false

      var didComplete = false
      var isProcessingEffects = true
      var disposeKey: CompositeDisposable.DisposeKey?

      let effectDisposable = effect.subscribe(
        onNext: { [weak self] action in
          if isProcessingEffects {
            self?.synchronousActionsToSend.append(action)
          } else {
            self?.send(action)
          }
        },
        onError: { err in
          assertionFailure("Error during effect handling: \(err.localizedDescription)")
        },
        onCompleted: { [weak self] in
          didComplete = true
          if let disposeKey = disposeKey {
            self?.effectDisposables.remove(for: disposeKey)
          }
        }
      )

      isProcessingEffects = false

      if !didComplete {
        disposeKey = effectDisposables.insert(effectDisposable)
      }
    }
  }

  /// Returns a "stateless" store by erasing state to `Void`.
  public var stateless: Store<Void, Action> {
    self.scope(state: { _ in () })
  }

  /// Returns an "actionless" store by erasing action to `Never`.
  public var actionless: Store<State, Never> {
    func absurd<A>(_ never: Never) -> A {}
    return self.scope(state: { $0 }, action: absurd)
  }

  private init(
    initialState: State,
    reducer: @escaping (inout State, Action) -> Effect<Action>,
    sendingQueue: DispatchQueue?
  ) {
    self.reducer = reducer
    self.stateRelay = BehaviorRelay(value: initialState)
    self.sendingQueue = sendingQueue
  }
}

/// A publisher of store state.
@dynamicMemberLookup
public struct StorePublisher<State>: ObservableType {
  public typealias Element = State
  public let upstream: Observable<State>
  let scheduler: SchedulerType?

  public func subscribe<Observer>(_ observer: Observer) -> Disposable
  where Observer: ObserverType, Self.Element == Observer.Element {
    upstream.observeOn(optional: scheduler).subscribe(observer)
  }

  init(_ upstream: Observable<State>, scheduler: SchedulerType? = nil) {
    self.upstream = upstream
    self.scheduler = scheduler
  }

  /// Returns the resulting publisher of a given key path.
  public subscript<LocalState>(
    dynamicMember keyPath: KeyPath<State, LocalState>
  ) -> StorePublisher<LocalState>
  where LocalState: Equatable {
    .init(
      self.upstream.map { $0[keyPath: keyPath] }.distinctUntilChanged(),
      scheduler: scheduler
    )
  }
}
