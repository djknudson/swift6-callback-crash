#!/bin/zsh
# usage: launch.sh <build> <variant> [reset]   Launches and returns immediately, so the prompt can be answered. check.sh reads the outcome.
root=${0:A:h}; name=$1; variant=$2; U=$(<$root/.udid); id=com.example.swift6crash.$name
xcrun simctl install $U $root/build/$name/Probe.app || exit 2
[[ ${3:-} == reset ]] && { xcrun simctl privacy $U reset all $id; print "privacy reset rc=$?"; }
mkdir -p $root/logs; log=$root/logs/$name--$variant--$(date +%H%M%S).log; t0=$(date +%s)
SIMCTL_CHILD_VARIANT=$variant xcrun simctl launch --terminate-running-process --stdout=$log --stderr=$log $U $id > $root/.launch 2>&1
print "$log $t0 $(awk '{print $NF}' $root/.launch) $id" > $root/.current; print "launched $name / $variant"; 
