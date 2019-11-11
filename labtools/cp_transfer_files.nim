## Copy Echo transfer files into the correct Cell Painting folders.
# nim -d:release -o:bin/cp_transfer_files c labtools/cp_transfer_files.nim

import os, # paramCount, paramStr, dirExists, fileExists, /
  strutils, # %, unindent
  algorithm # sort

const version = "0.1.0"

# template debugMsg(msg: varargs[untyped]) =
#   when not defined(release):
#     echo "DEBUG: ", msg

proc echoHelp(retCode: int) =
  let
    appName = extractFilename(getAppFilename())
    help = """

      Copy Echo transfer files into the correct Cell Painting folders.
      Usage: $1 <source folder> <plate name>
          source folder: The folder which contains the transfer XML files.
          plate name: The full path to the Cell Painting plate
              but *without* the replicate identifier (-A, -B, -C).""".unindent % appName
  echo help
  quit(retCode)

proc validateInput(): (string, string) = # tuple[src: string, plate: string] =
  let numParams = os.paramCount()
  if numParams < 2:
    echoHelp(0)
  let
    src = os.paramStr(1)
    plate = os.paramStr(2)
  if not dirExists(src):
    echo "Source directory ", src, " does not exist."
    echoHelp(1)
  for repl in @["A", "B", "C"]:
    let plateName = "$1-$2" % [plate, repl]
    if not dirExists(plateName):
      echo "Target plate $1 does not exist." % plateName
      echoHelp(2)
  result = (src, plate)

proc cpTransfer(src, plate: string) =
  let fnPattern = src / "E5XX-1030_Transfer_*.xml"
  var xmlFiles: seq[string]
  for fn in walkFiles(fnPattern):
    if fn.contains("Exception"):
      continue
    xmlFiles.add(fn)
  if xmlFiles.len != 3:
    echo "Incorrect number of XML files found ($1)." % $xmlFiles.len
    quit(3)
  xmlFiles.sort(cmp = cmpIgnoreCase)
  let repls = @["A", "B", "C"]
  for ix in 0 .. 2:
    let
      plateName = "$1-$2" % [plate, repls[ix]]
      baseFn = extractFilename(xmlFiles[ix])
    echo "Checking for existing XML file in $1..." % plateName
    for kind, path in walkDir(plateName):
      if kind == pcFile and path.contains(".xml"):
        echo "  XML file already present. Aborting."
        quit(4)
    echo "Copying XML file..."
    copyFile(xmlFiles[ix], plateName / baseFn)


when isMainModule:
  echo "Copy Echo Transfer Files"
  echo "written in Nim, © 2019, COMAS, v", version, "\n"
  let (src, plate) = validateInput()
  cpTransfer(src, plate)
