#!/usr/bin/env python3
"""Generate a Level B conformance driver from a .cases file.
usage: gen.py NAMESPACE cases-file out.rexx IMPORT...
Line format:  function | arguments | expected
  arguments: 'text' (U+{hhhh} = codepoint) or integers, comma separated
  expected : integer, or 'text' for a string result
An optional NAMESPACE.prelude file next to the cases is appended (helper procedures)."""
import os, re, sys
ns, src, out = sys.argv[1:4]
imports = sys.argv[4:]
def lit(s):
    parts = re.split(r'U\+\{([0-9A-Fa-f]{4,6})\}', s)
    exprs = []
    for i, p in enumerate(parts):
        if i % 2: exprs.append('d2c(%d)' % int(p, 16))
        elif p: exprs.append('"%s"' % p)
    return ' || '.join(exprs) if exprs else '""'
L = ['options levelb', 'import rxfnsb'] + ['import ' + m for m in imports]
L += ['pass = 0', 'fail = 0']
n = 0
for line in open(src, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line or line.startswith('#'): continue
    fn, args, exp = line.split('|')
    a = []
    for m in re.finditer(r"'([^']*)'|(-?\d+)", args):
        a.append(lit(m.group(1)) if m.group(1) is not None else m.group(2))
    n += 1
    L.append('r%d = %s(%s)' % (n, fn, ', '.join(a)))
    if exp.startswith("'"):
        cond = 'r%d = ' % n + lit(exp[1:-1])
    else:
        cond = 'r%d = ' % n + exp
    L.append('if %s then pass = pass + 1' % cond)
    L.append('else do; fail = fail + 1; say "FAIL %s(%s) expected %s got" r%d; end'
             % (fn, args.replace('"', "'"), exp.replace('"', "'"), n))
L.append('say "%s: passed" pass "failed" fail "of %d"' % (ns, n))
L.append('if fail > 0 then exit 1')
L.append('exit 0')
pre = os.path.splitext(src)[0] + '.prelude'
if os.path.exists(pre): L.append(open(pre, encoding='utf-8').read())
open(out, 'w').write('\n'.join(L) + '\n')
