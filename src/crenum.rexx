/* crenum - CRE number services, v0 draft. See spec/num.md */
options levelb
namespace crenum expose isint isdecimal parseint fixed
import rxfnsb
import crecond

/* 1 if s is [+-] followed by one or more ASCII digits, nothing else */
isint: procedure = .int
  arg s = .string
  n = length(s)
  i = 1
  if n >= 1 then do
    ch = substr(s,1,1)
    if ch = "+" | ch = "-" then i = 2
  end
  if i > n then return 0
  do k = i to n
    ch = substr(s,k,1)
    if c2d(ch) < 48 | c2d(ch) > 57 then return 0
  end
  return 1

/* 1 if s is a plain decimal number: [+-] digits [. digits] [e [+-] digits], or [+-] . digits ... */
isdecimal: procedure = .int
  arg s = .string
  n = length(s)
  i = 1
  if n >= 1 then do
    ch = substr(s,1,1)
    if ch = "+" | ch = "-" then i = 2
  end
  nd = 0
  do while i <= n
    ch = substr(s,i,1)
    if c2d(ch) < 48 | c2d(ch) > 57 then leave
    nd = nd + 1
    i = i + 1
  end
  if i <= n then do
    if substr(s,i,1) = "." then do
      i = i + 1
      do while i <= n
        ch = substr(s,i,1)
        if c2d(ch) < 48 | c2d(ch) > 57 then leave
        nd = nd + 1
        i = i + 1
      end
    end
  end
  if nd = 0 then return 0
  if i > n then return 1
  ch = substr(s,i,1)
  if ch <> "e" & ch <> "E" then return 0
  i = i + 1
  if i > n then return 0
  ch = substr(s,i,1)
  if ch = "+" | ch = "-" then i = i + 1
  if i > n then return 0
  do while i <= n
    ch = substr(s,i,1)
    if c2d(ch) < 48 | c2d(ch) > 57 then return 0
    i = i + 1
  end
  return 1

/* parse an integer. Bad syntax: CONVERSION_ERROR. Syntax fine but not representable: OUT_OF_RANGE */
parseint: procedure = .int
  arg s = .string
  if isint(s) = 0 then call crecond..raise("conversion_error", "not an integer")
  do
    v = s as .int
    return v
  on signal as c
    call crecond..raise("out_of_range", "integer does not fit")
  end
  return 0

/* x rounded half away from zero to `places` decimals, fixed notation, no negative zero */
fixed: procedure = .string
  arg x = .string, places = .int
  if places < 0 then call crecond..raise("invalid_arguments", "places must not be negative")
  if isdecimal(x) = 0 then call crecond..raise("conversion_error", "not a decimal number")
  d = x as .decimal
  r = format(d,,places)
  if pos("E", upper(r)) > 0 then call crecond..raise("out_of_range", "needs exponent form")
  if left(r,1) = "-" then do
    if verify(substr(r,2), "0.") = 0 then r = substr(r,2)
  end
  return r
