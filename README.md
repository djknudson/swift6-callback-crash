# Swift 6 callback crash

A closure written in `@MainActor` code crashes in Swift 6 mode if an older API with a plain callback calls it on a background queue. It compiles with no warnings, and it crashes even if the closure is empty or hops straight back to the main thread, because the check runs when the closure is entered.

This package reproduces that with a small Objective-C stand-in, and shows which tests can catch it.

## Run it

```
swift test
```

All ten tests should pass. It needs Swift 6.2 or later (Xcode 26 or later) and runs on the Mac, because Swift Testing's exit tests aren't available on iOS.

## What the tests show

| Test | Expects | Why |
|---|---|---|
| `emptyClosureCrashes` | crash | The closure belongs to the main actor and is entered off the main thread. |
| `carefulHopCrashes` | crash | The check runs before the hop to the main queue. This is also the Objective-C fake that catches the bug. |
| `aFakeInASwift5LibraryCatchesIt` | crash | A library built in Swift 5 mode hasn't adopted strict concurrency, so it gets the check too. |
| `callbackSurvivesOffMain` | no crash | `@Sendable` means the closure doesn't belong to the main actor. |
| `nonisolatedHelperSurvives` | no crash | A closure formed in a `nonisolated` function has no actor. |
| `aSwiftFakeWithASendableParameterMissesIt` | no crash | With a `@Sendable` parameter, the closure isn't isolated at all. |
| `aSwiftFakeWithAPlainParameterMissesIt` | no crash | The closure stays isolated, but a fake in Swift 6 mode gets no check. |
| `aFakeInASwift6LibraryMissesIt` | no crash | The same, across a module boundary. |
| `anInjectedStandInMissesIt` | no crash | The compiler decides from the function the closure is passed to, and here that's a Swift parameter. |
| `aStandInWithACompletionHandlerBlockMissesIt` | no crash | Same selector and same closure as `carefulHopCrashes`, with the block named `completionHandler`. Swift can import that method as `async`, so its callback is `@Sendable` ([SE-0463](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0463-sendable-completion-handlers.md)). |

To see a test catch a regression, delete `@Sendable` from `askFixed` in `Sources/Demo/Recorder.swift` and run `swift test` again. `callbackSurvivesOffMain` fails. The fakes that can't catch the bug keep passing, whatever you do to the closure, which is the point of them.

## Which Apple callbacks are exposed

`survey.sh` typechecks a closure in `@MainActor` code against each API, using the iOS 27.2 SDK. If it compiles with no isolation diagnostic, the closure is isolated, so it crashes if that API answers off the main thread. Isolated only means exposed: on the simulator, with permission already granted, the old Photos call crashed and the old `AVAudioSession` call answered on the main thread and didn't.

| API | Closure in `@MainActor` code |
|---|---|
| `SFSpeechRecognizer.requestAuthorization` | **isolated, exposed** |
| `AVAudioNode.installTap` | **isolated, exposed** |
| `PHPhotoLibrary.requestAuthorization(_:) (old)` | **isolated, exposed** |
| `PHPhotoLibrary.requestAuthorization(for:handler:)` | not isolated, safe |
| `AVCaptureDevice.requestAccess(for:)` | not isolated, safe |
| `AVAudioApplication.requestRecordPermission` | not isolated, safe |
| `AVAudioSession.requestRecordPermission` | **isolated, exposed** |
| `CNContactStore.requestAccess` | not isolated, safe |
| `EKEventStore.requestFullAccessToEvents` | not isolated, safe |
| `UNUserNotificationCenter.requestAuthorization` | not isolated, safe |
| `HKHealthStore.requestAuthorization` | not isolated, safe |
| `ATTrackingManager.requestTrackingAuthorization` | not isolated, safe |
| `MPMediaLibrary.requestAuthorization` | not isolated, safe |
| `INPreferences.requestSiriAuthorization` | **isolated, exposed** |
| `CMPedometer.queryPedometerData` | **isolated, exposed** |
| `URLSession.dataTask` | not isolated, safe |

The run-time check comes from [SE-0423](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md). Tested with Xcode 27.2 and Swift 6.4.2.
