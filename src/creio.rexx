/* creio - CRE standard streams, v0 draft. See spec/io.md */
options levelb
namespace creio expose out err flush creio_hout creio_herr
import _rxsysb

creio_hout = 0
creio_herr = 0

setup: procedure = .void
  if creio_hout = 0 then do
    creio_hout = _open("stdout", "w")
    creio_herr = _open("stderr", "w")
  end
  return

out: procedure = .void
  arg text = .string
  call setup
  assembler fwrite creio_hout, text
  return

flush: procedure = .void
  rcx = .int
  call setup
  assembler fflush rcx, creio_hout
  return

err: procedure = .void
  arg text = .string
  rcx = .int
  call setup
  assembler fflush rcx, creio_hout
  assembler fwrite creio_herr, text
  assembler fflush rcx, creio_herr
  return
