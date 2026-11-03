import Dispatch
// Built in Swift 5 mode with minimal checking: a Swift library that predates strict concurrency.
public func legacyAnswerOffMain(_ handler: @escaping (Int) -> Void) {
    DispatchQueue.global().async { handler(3) }
}
