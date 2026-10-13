options levelb
import rxfnsb
import _rxsysb
import crecond
import cretext

hout = _open("stdout", "w")
s = "hello world 123"
s2 = "abc"
ch = "7"
ndl = "wor"
dig = "0123456789"
ou = "ABC"
inn = "abc"
fs = "123.456"
fv = 1.5
key = "alpha"
line = "twenty bytes of text" || '0a'x
acc = 0
facc = 0.0
t = ""
n = 0
fl = 0.0
ia = .int[]
sa = .string[]
sm = .stem()
ia[7] = 1
sa[7] = "x"
sm["alpha"] = 1
sm["beta"] = 2
cnt = 200000
call time "R"
res = ""
x = time("R")
do i = 1 to cnt
  acc = acc + 1
end
e0 = time("E") as .float
call out2 "empty loop", e0
x = time("R")
do i = 1 to cnt
  acc = acc + f(i)
end
e1 = time("E") as .float
call out2 "local call f(x)", e1
x = time("R")
do i = 1 to cnt
  acc = acc + g(i, 2)
end
e2 = time("E") as .float
call out2 "local call, 2 args", e2
x = time("R")
do i = 1 to cnt
  acc = acc + h(i)
end
e3 = time("E") as .float
call out2 "imported call, not inlined (crecond.named-like)", e3
x = time("R")
do i = 1 to cnt
  acc = acc + cretext..isdigit(ch)
end
e4 = time("E") as .float
call out2 "inlined imported call (cretext.isdigit)", e4
x = time("R")
do i = 1 to cnt
  acc = acc + length(s)
end
e5 = time("E") as .float
call out2 "length(s)", e5
x = time("R")
do i = 1 to cnt
  acc = acc + length(substr(s, 3, 1))
end
e6 = time("E") as .float
call out2 "substr(s,i,1)", e6
x = time("R")
do i = 1 to cnt
  acc = acc + c2d(ch)
end
e7 = time("E") as .float
call out2 "c2d(ch)", e7
x = time("R")
do i = 1 to cnt
  acc = acc + pos(ndl, s)
end
e8 = time("E") as .float
call out2 "pos(needle,s)", e8
x = time("R")
do i = 1 to cnt
  acc = acc + verify(s, dig)
end
e9 = time("E") as .float
call out2 "verify(s,set)", e9
x = time("R")
do i = 1 to cnt
  acc = acc + length(left(s, 3))
end
e10 = time("E") as .float
call out2 "left(s,3)", e10
x = time("R")
do i = 1 to cnt
  acc = acc + length(upper(s))
end
e11 = time("E") as .float
call out2 "upper(s)", e11
x = time("R")
do i = 1 to cnt
  acc = acc + length(translate(s, ou, inn))
end
e12 = time("E") as .float
call out2 "translate(s,o,i)", e12
x = time("R")
do i = 1 to cnt
  acc = acc + length(s || s2)
end
e13 = time("E") as .float
call out2 "concat a || b", e13
x = time("R")
do i = 1 to cnt
  if s = s2 then acc = acc + 1
end
e14 = time("E") as .float
call out2 "string compare a = b", e14
x = time("R")
do i = 1 to cnt
  fl = fs as .float
  facc = facc + fl
end
e15 = time("E") as .float
call out2 "string to float (s as .float)", e15
x = time("R")
do i = 1 to cnt
  acc = acc + length(fv as .string)
end
e16 = time("E") as .float
call out2 "float to string (x as .string)", e16
x = time("R")
do i = 1 to cnt
  fv = fv * 1.0000001 + 0.5
  facc = facc + fv
end
e17 = time("E") as .float
call out2 "float multiply-add", e17
x = time("R")
do i = 1 to cnt
  acc = acc + ia[7]
end
e18 = time("E") as .float
call out2 "int array read", e18
x = time("R")
do i = 1 to cnt
  ia[7] = i
end
e19 = time("E") as .float
call out2 "int array write", e19
x = time("R")
do i = 1 to cnt
  sa[7] = s
end
e20 = time("E") as .float
call out2 "string array write", e20
x = time("R")
do i = 1 to cnt
  sm[key] = i
end
e21 = time("E") as .float
call out2 "map write sm[key]", e21
x = time("R")
do i = 1 to cnt
  acc = acc + sm[key]
end
e22 = time("E") as .float
call out2 "map read sm[key]", e22
x = time("R")
do i = 1 to cnt
  acc = acc + blk(i)
end
e23 = time("E") as .float
call out2 "signal block entry, no signal", e23
x = time("R")
do i = 1 to cnt
  acc = acc + rz(i)
end
e24 = time("E") as .float
call out2 "signal raise + catch", e24
x = time("R")
do i = 1 to cnt
  assembler fwrite hout, line
end
e25 = time("E") as .float
call out2 "fwrite 20 bytes to stdout", e25
say acc t n fl
exit

out2: procedure = .void
  arg nm = .string, e = .float
  say right(format(e * 1000000000 / 200000, , 0), 7) "ns  " nm
  return

f: procedure = .int
  arg x = .int
  return x + 1

g: procedure = .int
  arg x = .int, y = .int
  return x + y

h: procedure = .int
  arg x = .int
  r = 0
  if x > 5 then r = 1
  return r

blk: procedure = .int
  arg x = .int
  do
    return x + 1
  on signal as c
    return 0
  end
  return 0

rz: procedure = .int
  arg x = .int
  do
    signal failure
  on signal as c
    return 1
  end
  return 0

