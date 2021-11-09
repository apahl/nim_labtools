## Add an Id property to an SD File.
# nim -d:release -o:bin/sdf_add_id c labtools/sdf_add_id.nim
import std/os
import std/strutils

proc main(fn, id_prop: string) =
  let (dir, name, ext) = fn.splitFile
  let newFile = dir / name & "_mod" & ext
  var f = open(newFile, fmWrite)
  var recCtr = 0
  for line in fn.lines:
    if "$$$$" in line:
      recCtr += 1
      f.writeLine("> <$1>" % [idProp])
      f.writeLine($recCtr)
      f.writeLine("")
    f.writeLine(line)
  f.close()

when isMainModule:
  import cligen
  dispatch(
    main,
    cmdName = "sdf_add_id",
    doc = "Add an id property to an SD file.",
    help = {
      "fn": "The name of the SD file. The result will be written to a `_mod` file",
      "id_prop": "The name of the id property"
    }
  )
