/* crecond - CRE condition conventions, v0 draft. See spec/cond.md */
options levelb
namespace crecond expose raise describe named
import rxfnsb

/* raise the CREXX signal `name` with message `text` */
raise: procedure = .int
  arg name = .string, text = .string
  signal .signal(upper(name), text)
  return 0

/* one-line description of a signal: NAME: message (message omitted when empty) */
describe: procedure = .string
  arg c = .signal
  n = strip(c.name())
  if c.message() = "" then return n
  return n": "c.message()

/* 1 if the signal has the given name (case-insensitive) */
named: procedure = .int
  arg c = .signal, name = .string
  if upper(strip(c.name())) = upper(name) then return 1
  return 0
