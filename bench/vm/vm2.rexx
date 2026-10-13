options levelb
import rxfnsb
import _rxsysb

hout = _open("stdout", "w")
cnt = 100000
d1 = 1234.56d
d2 = 7.25d
dacc = 0.0d
iacc = 0
sacc = 0
rec = "JOHN SMITH          000123450  NY"
pic = "0000123.45"
cur = "  ABC"
buf = ""

call time "R"
x = time("R")
do i = 1 to cnt
  dacc = dacc + d1 * d2
end
e = time("E") as .float
say "decimal multiply-add (COMPUTE)    " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  dacc = dacc / 3.0d
  dacc = dacc + 100.0d
end
e = time("E") as .float
say "decimal divide+add                " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  buf = dacc as .string
  iacc = iacc + length(buf)
end
e = time("E") as .float
say "decimal to string (DISPLAY)       " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  buf = substr(rec, 21, 9)
  iacc = iacc + (buf as .int)
end
e = time("E") as .float
say "field extract + numeric (MOVE)    " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  buf = overlay("XX", rec, 31, 2)
  iacc = iacc + length(buf)
end
e = time("E") as .float
say "overlay (MOVE to field)           " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  buf = right(pic, 12, " ")
  buf = translate(buf, "$", " ")
  iacc = iacc + length(buf)
end
e = time("E") as .float
say "picture edit (right+translate)    " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  buf = left(strip(cur), 20, " ")
  iacc = iacc + length(buf)
end
e = time("E") as .float
say "pad/trim (STRING DELIMITED)       " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  iacc = iacc + pos("SMITH", rec) + verify(pic, "0123456789.")
end
e = time("E") as .float
say "INSPECT-style pos+verify          " || (e*1000000000/cnt) as .int || " ns"

x = time("R")
do i = 1 to cnt
  iacc = iacc + (rec = "JOHN SMITH          000123450  NY")
end
e = time("E") as .float
say "record compare                    " || (e*1000000000/cnt) as .int || " ns"
say iacc dacc
