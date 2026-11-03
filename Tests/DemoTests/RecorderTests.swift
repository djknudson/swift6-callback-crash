import Demo
import Foundation
import OldAPI
import Testing

// Exit tests run the body in a child process, so a crash fails one test instead of
// killing the run. The sleep gives each fake time to answer on its background queue.

// MARK: What crashes

@Test func emptyClosureCrashes() async {
    await #expect(processExitsWith: .signal(SIGTRAP)) {
        await MainActor.run { Recorder().askEmpty() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// The Objective-C stand-in, block named `handler`, called by name: this fake catches the bug.
@Test func carefulHopCrashes() async {
    await #expect(processExitsWith: .signal(SIGTRAP)) {
        await MainActor.run { Recorder().askCareful() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// A fake in a library built in Swift 5 mode, called by name: this one catches it too.
@Test func aFakeInASwift5LibraryCatchesIt() async {
    await #expect(processExitsWith: .signal(SIGTRAP)) {
        await MainActor.run { Recorder().askCarefulViaSwift5Library() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

// MARK: The fixes

@Test func callbackSurvivesOffMain() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run { Recorder().askFixed() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

@Test func nonisolatedHelperSurvives() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run { Recorder().askViaHelper() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

// MARK: Fakes that miss the bug. Each passes with the closure from carefulHopCrashes.

@Test func aSwiftFakeWithASendableParameterMissesIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run {
            Recorder().askCareful(usingSendable: { handler in
                DispatchQueue.global().async { handler(3) }
            })
        }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

@Test func aSwiftFakeWithAPlainParameterMissesIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run {
            Recorder().askCareful(using: { handler in
                nonisolated(unsafe) let handler = handler
                DispatchQueue.global().async { handler(3) }
            })
        }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

@Test func aFakeInASwift6LibraryMissesIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run { Recorder().askCarefulViaSwift6Library() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// The real stand-in, injected. The compiler decides from the function the closure is
/// passed to, and that's now a Swift parameter.
@Test func anInjectedStandInMissesIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run {
            Recorder().askCareful(using: { handler in OldAPI.requestAnswer(handler) })
        }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// Same selector and same closure as `carefulHopCrashes`. Only the block's name differs.
@Test func aStandInWithACompletionHandlerBlockMissesIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run { Recorder().askCarefulWithCompletionHandlerName() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}
