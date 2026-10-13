#!/bin/sh
# usage: run.sh BINDIR [NAMESPACE...]   builds src/*.crexx, runs conformance/cases/*/NAMESPACE.cases
B=$1; shift
C=$(cd "$(dirname "$0")/.." && pwd); R=$(dirname "$C")
MODS="crecond creio crenum cretext"
[ $# -eq 0 ] && set -- crecond crenum cretext
W=$(mktemp -d); cp "$R"/src/*.crexx "$W/"; cd "$W" || exit 2
BINS=""
for m in $MODS; do
  $B/rxc -i "$B" -l . $m.crexx 2>&1 | grep -i "error" && exit 2
  $B/rxas $m >/dev/null || exit 2
  BINS="$BINS $m"
done
rc=0
for ns in "$@"; do
  python3 "$C/driver/gen.py" $ns "$(ls "$C"/cases/*/$ns.cases)" drv_$ns.crexx $MODS
  $B/rxc -i "$B" -l . drv_$ns.crexx 2>&1 | grep -i "error" && { rc=2; continue; }
  $B/rxas drv_$ns >/dev/null && $B/rxvm drv_$ns $BINS || rc=1
done
exit $rc
