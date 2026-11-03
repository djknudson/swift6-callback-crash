import Demo
import Foundation
import OldAPI
import Testing

// Exit tests run the body in a child process, so a crash fails one test instead of
// killing the run. The sleep gives the stand-in time to answer on its background queue.

// MARK: What crashes

@Test func emptyClosureCrashes() async {
    await #expect(processExitsWith: .signal(SIGTRAP)) {
        await MainActor.run { Recorder().askEmpty() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

@Test func carefulHopCrashes() async {
    await #expect(processExitsWith: .signal(SIGTRAP)) {
        await MainActor.run { Recorder().askCareful() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

// MARK: What survives

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

/// Same closure as `carefulHopCrashes`. Only the Objective-C parameter's name differs.
@Test func theParameterNameDecides() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run { Recorder().askUsingCompletionHandlerName() }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

// MARK: Tests that cannot catch the bug. Both of these pass with the crashing closure.

/// A fake that answers off the main thread, just as the real API does.
@Test func aSwiftFakeCannotCatchIt() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run {
            Recorder().askCareful { handler in
                nonisolated(unsafe) let handler = handler
                DispatchQueue.global().async { handler(3) }
            }
        }
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// The real Objective-C stand-in, injected through a Swift parameter. The compiler
/// decides at the call site, and that call site is a Swift parameter.
@Test func anInjectedStandInCannotCatchItEither() async {
    await #expect(processExitsWith: .success) {
        await MainActor.run {
            Recorder().askCareful { handler in OldAPI.requestAnswer(handler) }
        }
        try? await Task.sleep(for: .milliseconds(300))
    }
}
