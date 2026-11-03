#!/usr/bin/env python3 -I
"""Say what ended a run: the isolation trap, some other crash, or no crash. Reads the .ips written after a given time."""
import json,sys,os,glob
bundle,since=sys.argv[1],float(sys.argv[2])
hits=[]
for f in glob.glob(os.path.expanduser('~/Library/Logs/DiagnosticReports/*Probe-*.ips')):
    if os.path.getmtime(f)<since: continue
    raw=open(f).read().split('\n',1)
    try: h=json.loads(raw[0]); d=json.loads(raw[1])
    except Exception: continue
    if h.get('bundleID')!=bundle: continue
    hits.append((os.path.getmtime(f),f,d))
if not hits: print('RESULT no-crash'); sys.exit()
_,f,d=sorted(hits)[-1]
t=d['threads'][d['faultingThread']]; imgs=d['usedImages']
syms=[f"{os.path.basename(imgs[x['imageIndex']].get('name','?'))}:{x.get('symbol','?')}" for x in t['frames'][:9]]
trap=any('checkIsolated' in s or '_dispatch_assert_queue_fail' in s or 'isCurrentExecutor' in s for s in syms)
print('RESULT','ISOLATION-TRAP' if trap else 'OTHER-CRASH',d['exception'].get('type'),'queue=',t.get('queue'))
for s in syms: print('   ',s)
print('    report:',os.path.basename(f))
