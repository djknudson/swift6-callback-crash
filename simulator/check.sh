#!/bin/zsh
# usage: check.sh <label>   Reports the current run's outcome, reading the crash report rather than guessing from the exit.
root=${0:A:h}; read log t0 pid id < $root/.current
for i in 1 2 3 4 5 6; do kill -0 $pid 2>/dev/null || break; sleep 1; done
kill -0 $pid 2>/dev/null && p=running || p=gone; if [[ $p == gone ]]; then for i in {1..60}; do python3 -I $root/classify.py $id $t0 | grep -q no-crash || break; sleep 1; done; fi
print "== ${1:-run}: process=$p"; grep -E "^\[probe\]" $log | cut -c1-150; python3 -I $root/classify.py $id $t0 | cut -c1-110
print "${1:-run}\tprocess=$p\t$(grep -E '^\[probe\]' $log | tr '\n' ' ' | cut -c1-260)\t$(python3 -I $root/classify.py $id $t0 | head -1)" >> $root/results/simulator-prompt.tsv
