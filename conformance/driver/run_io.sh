#!/bin/sh
# usage: run_io.sh BINDIR   -- checks creio: stdout/stderr separation and flush order
B=$1; R=$(cd "$(dirname "$0")/../.." && pwd)
W=$(mktemp -d); cp "$R"/src/creio.rexx "$W/"; cd "$W" || exit 2
cat > t.rexx <<'X'
options levelb
import rxfnsb
import creio
call creio..out "one" || '0a'x
call creio..err "two" || '0a'x
call creio..out "three" || '0a'x
call creio..flush
X
$B/rxc -i "$B" -l . creio.rexx >/dev/null && $B/rxas creio >/dev/null || exit 2
$B/rxc -i "$B" -l . t.rexx >/dev/null 2>&1 && $B/rxas t >/dev/null || exit 2
O=$($B/rxvm t creio 2>/dev/null); E=$($B/rxvm t creio 2>&1 >/dev/null); A=$($B/rxvm t creio 2>&1)
[ "$O" = "one
three" ] && [ "$E" = "two" ] && [ "$A" = "one
two
three" ] && { echo "creio: passed 3 of 3"; exit 0; }
echo "creio: FAILED"; printf 'stdout=[%s] stderr=[%s] merged=[%s]\n' "$O" "$E" "$A"; exit 1
