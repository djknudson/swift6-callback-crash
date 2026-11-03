import Foundation
import OldAPI

@MainActor
public final class Recorder {
    public init() {}

    /// Compiles with no warnings. Crashes in Swift 6 mode, because the closure belongs
    /// to the main actor and is called on a background queue.
    public func askEmpty() {
        OldAPI.requestAnswer { _ in }
    }

    /// The careful habit. Crashes too: the check runs when the closure is entered,
    /// before the hop.
    public func askCareful() {
        OldAPI.requestAnswer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// One word different. The closure no longer belongs to the main actor, so there
    /// is nothing to check. Touching main-actor state here without a hop only warns.
    public func askFixed() {
        OldAPI.requestAnswer { @Sendable status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// The other fix: form the closure somewhere that has no actor.
    public func askViaHelper() {
        Self.askFromNowhere()
    }

    nonisolated private static func askFromNowhere() {
        OldAPI.requestAnswer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// The same closure as `askCareful`, passed to a block named `completionHandler`.
    public func askUsingCompletionHandlerName() {
        OldAPI.fetchAnswer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// The closure from `askCareful`, handed to whatever API the caller injects.
    /// The compiler sees a Swift parameter here, so it adds no check.
    public func askCareful(using api: (@escaping (Int) -> Void) -> Void) {
        api { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }
}
