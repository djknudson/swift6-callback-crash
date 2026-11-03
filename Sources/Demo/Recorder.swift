import Foundation
import New6
import Old5
import OldAPI

@MainActor
public final class Recorder {
    public init() {}

    // MARK: Crashes in Swift 6 mode

    /// Compiles with no warnings. The closure belongs to the main actor and is called
    /// on a background queue.
    public func askEmpty() {
        OldAPI.requestAnswer { _ in }
    }

    /// The careful habit. The check runs when the closure is entered, before the hop.
    public func askCareful() {
        OldAPI.requestAnswer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// A Swift library built in Swift 5 mode hasn't adopted strict concurrency either.
    public func askCarefulViaSwift5Library() {
        old5Answer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    // MARK: The fixes

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

    // MARK: The closure from askCareful, in places where it gets no check

    /// Same selector and same closure as `askCareful`. Only the block's name differs.
    public func askCarefulWithCompletionHandlerName() {
        OldAPICompletion.requestAnswer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// A library built in Swift 6 mode gets no check.
    public func askCarefulViaSwift6Library() {
        new6Answer { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// A plain Swift parameter: the closure stays isolated and gets no check.
    public func askCareful(using api: (@escaping (Int) -> Void) -> Void) {
        api { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }

    /// A `@Sendable` Swift parameter: the closure isn't isolated at all.
    public func askCareful(usingSendable api: (@escaping @Sendable (Int) -> Void) -> Void) {
        api { status in
            DispatchQueue.main.async { print("answer:", status) }
        }
    }
}
