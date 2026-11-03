import Dispatch

public func old5Answer(_ handler: @escaping (Int) -> Void) {
    DispatchQueue.global().async { handler(3) }
}
