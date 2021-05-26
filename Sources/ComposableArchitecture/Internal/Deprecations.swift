import RxSwift

// NB: Deprecated after 0.1.3:

extension Effect {
    @available(*, unavailable, renamed: "run")
    public static func async(
        _ work: @escaping (AnyObserver<Output>) -> Disposable
    ) -> Self {
        self.run(work)
    }
}

extension Effect {
    @available(*, unavailable, renamed: "catching")
    public static func sync(_ work: @escaping () throws -> Output) -> Self {
        self.catching(work)
    }
}
