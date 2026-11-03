# The real permission prompt

The package above uses an Objective-C stand-in so it runs without a simulator. This folder is the small iOS app that puts the same closures through the real `SFSpeechRecognizer.requestAuthorization`, in a simulator, with a human or a tool tapping the prompt.

```
./build.sh swift6-O -swift-version 6 -O
xcrun simctl list devices        # pick a simulator
echo <its UDID> > .udid          # then boot it
./launch.sh swift6-O empty reset # answer the prompt in the simulator
./check.sh "empty closure, Allow"
```

`launch.sh` takes a build name, a variant and an optional `reset`, which clears the app's saved answers. Variants include `continuation`, `empty`, `careful-hop`, `careful-task`, `sendable`, `helper` and `plain`. Leave out `reset` to test with the answer already saved. `check.sh` reads the crash report and only counts a run as this crash if the isolation check is on the stack.

Booting a simulator is heavy. On the 10-core Mac this was run on, one boot took the load average past 100 within a minute.

`results/` holds the raw runs from Xcode 27.2 and the iOS 27.0 simulator. All three closures crashed through the real prompt: the crash stacks are in `results/crash-stacks/`, and `results/lldb-*.txt` shows the two hops under a debugger.

The two hops read `no-crash` in `simulator-prompt-closures.tsv`, and those rows are wrong. The first run of each, under the process name `Probe`, left no crash report, for reasons unknown. Renamed and re-run, they wrote reports, but one landed 34 seconds after the crash with no bundle ID in its header, so the checker missed it. `check.sh` and `classify.py` now wait longer and handle a missing bundle ID. A `no-crash` from `check.sh` still isn't proof: under heavy load, look for a late report, or attach a debugger.
