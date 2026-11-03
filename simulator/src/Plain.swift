import Speech
// No @MainActor anywhere in this file. Whether this closure is main-actor isolated
// depends only on the module's default isolation setting.
final class PlainRecorder {
    func ask() {
        SFSpeechRecognizer.requestAuthorization { status in
            where_("plain", status.rawValue)
        }
    }
    func askFake() {
        ObjCFake.answerOffMain { status in
            where_("plain-objc-fake", status)
        }
    }
}
