#!/bin/zsh
# usage: build.sh <name> <swiftc flags...>   Builds an installable simulator app at build/<name>/Probe.app
set -euo pipefail
name=$1; shift
root=${0:A:h}; src=$root/src; out=$root/build/$name; rm -rf $out; mkdir -p $out
app=$out/Probe.app; mkdir -p $app
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path); T=arm64-apple-ios27.0-simulator
xcrun -sdk iphonesimulator clang -target $T -isysroot $SDK -fobjc-arc -c $src/ObjCFake.m -o $out/ObjCFake.o
xcrun -sdk iphonesimulator swiftc -target $T -sdk $SDK -swift-version 5 -strict-concurrency=minimal \
  -emit-library -static -emit-module -module-name LegacyFake -emit-module-path $out/LegacyFake.swiftmodule \
  $src/LegacyFake.swift -o $out/libLegacyFake.a
xcrun -sdk iphonesimulator swiftc -target $T -sdk $SDK -parse-as-library -module-name Probe "$@" \
  -import-objc-header $src/ObjCFake.h -I $out -L $out -lLegacyFake $out/ObjCFake.o \
  $src/App.swift $src/Plain.swift -o $app/Probe 2> $out/compile.log || { cat $out/compile.log; exit 1; }
id=com.example.swift6crash.$name
/usr/libexec/PlistBuddy -c "Clear dict" $app/Info.plist >/dev/null 2>&1 || true
plutil -create xml1 $app/Info.plist
for kv in CFBundleIdentifier=$id CFBundleExecutable=Probe CFBundleName=Probe CFBundlePackageType=APPL CFBundleVersion=1 CFBundleShortVersionString=1.0 MinimumOSVersion=27.0 \
  "NSSpeechRecognitionUsageDescription=Reproduces a crash for an article." "NSPhotoLibraryUsageDescription=Reproduces a crash for an article." "NSMicrophoneUsageDescription=Reproduces a crash for an article."; do
  plutil -insert "${kv%%=*}" -string "${kv#*=}" $app/Info.plist; done
plutil -insert LSRequiresIPhoneOS -bool YES $app/Info.plist
plutil -insert UILaunchScreen -json '{}' $app/Info.plist
plutil -insert UIApplicationSceneManifest -json '{"UIApplicationSupportsMultipleScenes":false}' $app/Info.plist
plutil -insert UIDeviceFamily -json '[1]' $app/Info.plist
plutil -insert CFBundleSupportedPlatforms -json '["iPhoneSimulator"]' $app/Info.plist
codesign -s - --force $app 2>/dev/null
print "built $name: warnings=$(grep -c 'warning:' $out/compile.log || true) errors=$(grep -c 'error:' $out/compile.log || true)"
