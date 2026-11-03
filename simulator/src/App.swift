import UIKit
import Speech
import Photos
import AVFAudio
@preconcurrency import LegacyFake

nonisolated func log(_ s: String) { print("[probe] \(s)"); fflush(stdout) }
nonisolated func where_(_ variant: String, _ status: Int) {
    let q = String(cString: __dispatch_queue_get_label(nil))
    log("ANSWER variant=\(variant) status=\(status) main=\(Thread.isMainThread) queue=\(q)")
}

// Swift-only double, written in this (strict) module. Non-Sendable parameter, so a closure
// literal passed from main-actor code stays isolated; the hop off main needs an explicit escape hatch.
nonisolated func swiftFake(_ handler: @escaping (Int) -> Void) {
    nonisolated(unsafe) let h = handler
    DispatchQueue.global().async { h(3) }
}

@MainActor
final class Variants {
    /// The bug, reduced: a closure literal written in a @MainActor type, handed to Apple's API.
    func inline() {
        SFSpeechRecognizer.requestAuthorization { status in
            where_("inline", status.rawValue)
        }
    }
    /// The exact shape build 90 shipped.
    func continuationShape() async {
        let s = await withCheckedContinuation { (c: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                c.resume(returning: status)
            }
        }
        where_("continuation-resumed", s.rawValue)
    }
    /// Candidate fix: mark the closure @Sendable.
    func sendable() {
        SFSpeechRecognizer.requestAuthorization { @Sendable status in
            where_("sendable", status.rawValue)
        }
    }
    /// The fix Zhiva shipped: form the closure in a nonisolated helper.
    nonisolated static func helper() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { status in
                where_("nonisolated-helper", status.rawValue)
                c.resume(returning: status)
            }
        }
    }
    /// The first regression test's double, with `nonisolated` dropped (the mutant it could not catch).
    static func mutantHelper(_ request: @Sendable (@escaping @Sendable (Int) -> Void) -> Void) async -> Int {
        await withCheckedContinuation { c in
            request { s in
                where_("first-test-shape", s)
                c.resume(returning: s)
            }
        }
    }
    func swiftOnlyFake() { swiftFake { s in where_("swift-fake", s) } }
    func emptyClosure() { SFSpeechRecognizer.requestAuthorization { _ in } }
    func carefulHop() {
        SFSpeechRecognizer.requestAuthorization { s in
            DispatchQueue.main.async { where_("real-careful-hop", s.rawValue) }
        }
    }
    func carefulTask() {
        SFSpeechRecognizer.requestAuthorization { s in
            Task { @MainActor in where_("real-careful-task", s.rawValue) }
        }
    }
    func photosOld() { PHPhotoLibrary.requestAuthorization { s in where_("photos-old", s.rawValue) } }
    func photosNew() { PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in where_("photos-new", s.rawValue) } }
    func audioSessionOld() { AVAudioSession.sharedInstance().requestRecordPermission { ok in where_("audiosession-old", ok ? 1 : 0) } }
    func objcFake() { ObjCFake.answerOffMain { s in where_("objc-fake", s) } }
    func legacyFake() { legacyAnswerOffMain { s in where_("legacy-swift5-module-fake", s) } }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool { true }
    func application(_ application: UIApplication, configurationForConnecting s: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let c = UISceneConfiguration(name: "Default", sessionRole: s.role)
        c.delegateClass = SceneDelegate.self
        return c
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let v = Variants()
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let w = UIWindow(windowScene: ws)
        w.rootViewController = UIViewController()
        w.rootViewController?.view.backgroundColor = .systemBackground
        w.makeKeyAndVisible(); window = w
        let variant = ProcessInfo.processInfo.environment["VARIANT"] ?? "inline"
        log("LAUNCH variant=\(variant) priorStatus=\(SFSpeechRecognizer.authorizationStatus().rawValue) supportsOnDevice=\(SFSpeechRecognizer()?.supportsOnDeviceRecognition == true)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { MainActor.assumeIsolated { self.run(variant) } }
    }
    func run(_ variant: String) {
        switch variant {
        case "inline": v.inline()
        case "continuation": Task { await v.continuationShape() }
        case "sendable": v.sendable()
        case "helper": Task { let s = await Variants.helper(); where_("resumed", s.rawValue) }
        case "first-test": Task {
            let s = await Variants.mutantHelper { answer in DispatchQueue.global().async { answer(3) } }
            where_("resumed", s) }
        case "empty": v.emptyClosure()
        case "careful-hop": v.carefulHop()
        case "careful-task": v.carefulTask()
        case "photos-old": v.photosOld()
        case "photos-new": v.photosNew()
        case "audiosession-old": v.audioSessionOld()
        case "swift-fake": v.swiftOnlyFake()
        case "objc-fake": v.objcFake()
        case "legacy-fake": v.legacyFake()
        case "plain": PlainRecorder().ask()
        case "plain-objc-fake": PlainRecorder().askFake()
        default: log("unknown variant")
        }
    }
}
