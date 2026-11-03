import Dispatch

public func new6Answer(_ handler: @escaping (Int) -> Void) {
    nonisolated(unsafe) let handler = handler
    DispatchQueue.global().async { handler(3) }
}
