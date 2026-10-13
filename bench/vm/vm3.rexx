options levelb
import rxfnsb
import _rxsysb
import cretext

s = "x7y"
cnt = 200000
acc = 0
call time "R"
x = time("R")
do i = 1 to cnt
  c = substr(s, 2, 1)
  acc = acc + cretext..isdigit(c)
end
e = time("E") as .float
say "A isdigit via cretext call   " || (e*1000000000/cnt) as .int || " ns/iter"

x = time("R")
do i = 1 to cnt
  c = substr(s, 2, 1)
  k = c2d(c)
  if k >= 48 & k <= 57 then acc = acc + 1
end
e = time("E") as .float
say "B same logic written inline  " || (e*1000000000/cnt) as .int || " ns/iter"

x = time("R")
do i = 1 to cnt
  c = substr(s, 2, 1)
end
e = time("E") as .float
say "C substr alone               " || (e*1000000000/cnt) as .int || " ns/iter"

x = time("R")
do i = 1 to cnt
  c = "12345"
  if verify(c, "0123456789") = 0 then acc = acc + 1
end
e = time("E") as .float
say "D numeric guard via verify   " || (e*1000000000/cnt) as .int || " ns/iter"

x = time("R")
do i = 1 to cnt
  acc = acc + trysig("12345")
end
e = time("E") as .float
say "E numeric via signal block   " || (e*1000000000/cnt) as .int || " ns/iter"
say acc

trysig: procedure = .int
  arg c = .string
  do
    return c as .int
  on signal as sg
    return -1
  end
  return -1
