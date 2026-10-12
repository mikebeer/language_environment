/* cretext - CRE text services, v0 draft. See spec/text.md */
options levelb
namespace cretext expose cp isdigit isalpha isalnum isspace isupper islower bytelen bytetocp cptobyte
import rxfnsb
import rxunicode

/* codepoint value of the single character c, or -1 if c is not one character */
cp: procedure = .int
  arg c = .string
  if length(c) <> 1 then return -1
  return c2d(c)

isdigit: procedure = .int
  arg c = .string
  n = cp(c)
  if n >= 48 & n <= 57 then return 1
  return 0

isupper: procedure = .int
  arg c = .string
  n = cp(c)
  if n >= 65 & n <= 90 then return 1
  return 0

islower: procedure = .int
  arg c = .string
  n = cp(c)
  if n >= 97 & n <= 122 then return 1
  return 0

isalpha: procedure = .int
  arg c = .string
  if isupper(c) = 1 then return 1
  return islower(c)

isalnum: procedure = .int
  arg c = .string
  if isalpha(c) = 1 then return 1
  return isdigit(c)

/* space, tab, LF, VT, FF, CR */
isspace: procedure = .int
  arg c = .string
  n = cp(c)
  if n = 32 | (n >= 9 & n <= 13) then return 1
  return 0

/* length of the UTF-8 form of s in bytes */
bytelen: procedure = .int
  arg s = .string
  return binlength(rxunicode..encode(s))

/* 1-based codepoint index of the codepoint starting at 0-based byte offset off.
   off = bytelen(s) gives length(s)+1. Not on a boundary or out of range: -1 */
bytetocp: procedure = .int
  arg s = .string, off = .int
  if off < 0 then return -1
  pos = 0
  do i = 1 to length(s)
    if pos = off then return i
    if pos > off then return -1
    pos = pos + binlength(rxunicode..encode(substr(s,i,1)))
  end
  if pos = off then return length(s) + 1
  return -1

/* 0-based byte offset of 1-based codepoint index idx. idx = length(s)+1 gives bytelen(s). Else -1 */
cptobyte: procedure = .int
  arg s = .string, idx = .int
  if idx < 1 | idx > length(s) + 1 then return -1
  pos = 0
  do i = 1 to idx - 1
    pos = pos + binlength(rxunicode..encode(substr(s,i,1)))
  end
  return pos
