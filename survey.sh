#!/bin/zsh
# Typecheck only. No diagnostic = the closure in @MainActor code stays isolated; a "nonisolated" diagnostic = it does not.
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path); d=$(mktemp -d)
probe() { print -r -- "import $2
@MainActor func mainOnly() {}
@MainActor func probe() { $3 }" > $d/p.swift
  xcrun swiftc -typecheck -swift-version 6 -target arm64-apple-ios27.0-simulator -sdk $SDK $d/p.swift > $d/p.log 2>&1; rc=$?
  if grep -qE "main actor-isolated.*(nonisolated|Sendable)" $d/p.log; then r="safe: closure not isolated"; elif [[ $rc == 0 ]]; then r="EXPOSED: closure isolated"; else r=OTHER; fi; printf '%-50s %s\n' "$1" "$r"; }
probe "SFSpeechRecognizer.requestAuthorization" Speech 'SFSpeechRecognizer.requestAuthorization { _ in mainOnly() }'
probe "AVAudioNode.installTap" AVFAudio 'AVAudioEngine().inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { _, _ in mainOnly() }'
probe "PHPhotoLibrary.requestAuthorization(_:) (old)" Photos 'PHPhotoLibrary.requestAuthorization { _ in mainOnly() }'
probe "PHPhotoLibrary.requestAuthorization(for:handler:)" Photos 'PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in mainOnly() }'
probe "AVCaptureDevice.requestAccess(for:)" AVFoundation 'AVCaptureDevice.requestAccess(for: .video) { _ in mainOnly() }'
probe "AVAudioApplication.requestRecordPermission" AVFAudio 'AVAudioApplication.requestRecordPermission { _ in mainOnly() }'
probe "AVAudioSession.requestRecordPermission" AVFAudio 'AVAudioSession.sharedInstance().requestRecordPermission { _ in mainOnly() }'
probe "CNContactStore.requestAccess" Contacts 'CNContactStore().requestAccess(for: .contacts) { _, _ in mainOnly() }'
probe "EKEventStore.requestFullAccessToEvents" EventKit 'EKEventStore().requestFullAccessToEvents { _, _ in mainOnly() }'
probe "UNUserNotificationCenter.requestAuthorization" UserNotifications 'UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in mainOnly() }'
probe "HKHealthStore.requestAuthorization" HealthKit 'HKHealthStore().requestAuthorization(toShare: [], read: []) { _, _ in mainOnly() }'
probe "ATTrackingManager.requestTrackingAuthorization" AppTrackingTransparency 'ATTrackingManager.requestTrackingAuthorization { _ in mainOnly() }'
probe "MPMediaLibrary.requestAuthorization" MediaPlayer 'MPMediaLibrary.requestAuthorization { _ in mainOnly() }'
probe "INPreferences.requestSiriAuthorization" Intents 'INPreferences.requestSiriAuthorization { _ in mainOnly() }'
probe "CMPedometer.queryPedometerData" CoreMotion 'CMPedometer().queryPedometerData(from: .now, to: .now) { _, _ in mainOnly() }'
probe "URLSession.dataTask (safe control)" Foundation 'URLSession.shared.dataTask(with: URL(string: "https://example.com")!) { _, _, _ in mainOnly() }.resume()'
