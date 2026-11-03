# Swift 6 callback crash

A closure written in `@MainActor` code crashes in Swift 6 mode if an older API calls it on a background queue. It compiles with no warnings, and it crashes even if the closure is empty or hops straight back to the main thread, because the check runs when the closure is entered.

This package reproduces that with a small Objective-C stand-in, and shows which tests can catch it.

## Run it

```
swift test
```

All seven tests should pass. It needs Swift 6.2 or later (Xcode 26 or later) and runs on the Mac, because Swift Testing's exit tests aren't available on iOS.

## What the tests show

| Test | Expects | Why |
|---|---|---|
| `emptyClosureCrashes` | crash | The closure belongs to the main actor and is entered off the main thread. |
| `carefulHopCrashes` | crash | The check runs before the hop to the main queue. |
| `callbackSurvivesOffMain` | no crash | `@Sendable` means the closure doesn't belong to the main actor. |
| `nonisolatedHelperSurvives` | no crash | A closure formed in a `nonisolated` function has no actor. |
| `theParameterNameDecides` | no crash | The same closure as the crashing one, passed to a block named `completionHandler`. Swift can import that method as `async`, so its callback is `@Sendable` ([SE-0463](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0463-sendable-completion-handlers.md)). |
| `aSwiftFakeCannotCatchIt` | no crash | A fake in Swift 6 mode gets no check, so the crashing closure passes. |
| `anInjectedStandInCannotCatchItEither` | no crash | The compiler decides at the call site, and the call site here is a Swift parameter. |

To see a test catch a regression, delete `@Sendable` from `askFixed` in `Sources/Demo/Recorder.swift` and run `swift test` again. `callbackSurvivesOffMain` fails. The two fakes keep passing whatever you do, which is the point of them.

The run-time check comes from [SE-0423](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md). Tested with Xcode 27.2 and Swift 6.4.2.
