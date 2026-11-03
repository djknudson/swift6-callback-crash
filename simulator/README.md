# The real permission prompt

The package above uses an Objective-C stand-in so it runs anywhere. This folder is the small iOS app that puts the same closures through the real `SFSpeechRecognizer.requestAuthorization`, in a simulator, with a human or a tool tapping the prompt.

```
./build.sh swift6-O -swift-version 6 -O
xcrun simctl list devices        # pick a simulator
echo <its UDID> > .udid          # then boot it
./launch.sh swift6-O empty reset # answer the prompt in the simulator
./check.sh "empty closure, Allow"
```

`launch.sh` takes a build name, a variant and an optional `reset`, which clears the app's saved answers. Variants include `continuation`, `empty`, `careful-hop`, `careful-task`, `sendable`, `helper` and `plain`. Leave out `reset` to test with the answer already saved. `check.sh` reads the crash report and only counts a run as this crash if the isolation check is on the stack.

Booting a simulator is heavy. On the 10-core Mac this was run on, one boot took the load average past 100 within a minute.

`results/` holds the raw runs from Xcode 27.2 and the iOS 27.0 simulator, one run per row. The `DispatchQueue` and `Task` hop runs wrote no crash report, for reasons unknown, so `results/lldb-*.txt` records them under a debugger. `simulator-prompt-closures.tsv` shows those two rows as `no-crash` for that reason: the classifier found no report, and the process had exited without logging an answer. The debugger output is the evidence for them.
