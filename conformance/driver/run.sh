#!/bin/sh
# usage: run.sh BINDIR [NAMESPACE...]   builds src/*.rexx, runs conformance/cases/*/NAMESPACE.cases
B=$1; shift
C=$(cd "$(dirname "$0")/.." && pwd); R=$(dirname "$C")
MODS="crecond crenum cretext"
[ $# -eq 0 ] && set -- $MODS
W=$(mktemp -d); cp "$R"/src/*.rexx "$W/"; cd "$W" || exit 2
BINS=""
for m in $MODS; do
  $B/rxc -i "$B" -l . $m.rexx 2>&1 | grep -i "error" && exit 2
  $B/rxas $m >/dev/null || exit 2
  BINS="$BINS $m"
done
rc=0
for ns in "$@"; do
  python3 "$C/driver/gen.py" $ns "$(ls "$C"/cases/*/$ns.cases)" drv_$ns.rexx $MODS
  $B/rxc -i "$B" -l . drv_$ns.rexx 2>&1 | grep -i "error" && { rc=2; continue; }
  $B/rxas drv_$ns >/dev/null && $B/rxvm drv_$ns $BINS || rc=1
done
exit $rc
