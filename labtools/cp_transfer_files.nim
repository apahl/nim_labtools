## Copy Echo transfer files into the correct Cell Painting folders.
# nim --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc --passL:-static -d:release -o:bin/cp_transfer_files c labtools/cp_transfer_files.nim
# scp bin/cp_transfer_files clem:bin/

import std / os, # paramCount, paramStr, dirExists, fileExists, `/`
  std / strutils, # %, unindent
  std / algorithm, # sort
  std / terminal, # colored terminal output
  std / exitprocs # addExitProc

const version = "0.1.1"

template colorEcho(color: ForegroundColor; args: varargs[untyped]) =
  setForegroundColor(color)
  echo args
  resetAttributes()

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
    colorEcho(fgRed, "ERROR: Source directory ", src, " does not exist.\n")
    echoHelp(1)
  for repl in @["A", "B", "C"]:
    let plateName = "$1-$2" % [plate, repl]
    if not dirExists(plateName):
      colorEcho(fgRed, "ERROR: Target plate $1 does not exist.\n" % plateName)
      echoHelp(2)
  result = (src, plate)

proc cpTransfer(src, plate: string) =
  let fnPattern = src / "E5XX*_Transfer_*.xml"
  var xmlFiles: seq[string]
  for fn in walkFiles(fnPattern):
    if fn.contains("Exception"):
      continue
    xmlFiles.add(fn)
  if xmlFiles.len != 3:
    colorEcho(fgRed, "ERROR: Incorrect number of XML files found ($1).\n" % $xmlFiles.len)
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
        colorEcho(fgRed, "  ERROR: XML file already present. Aborting.\n")
        quit(4)
    echo "Copying XML file $1 --> $2 ..." % [xmlFiles[ix], plateName]
    copyFile(xmlFiles[ix], plateName / baseFn)


when isMainModule:
  addExitProc(resetAttributes)
  colorEcho(fgCyan, "Copy Echo Transfer Files")
  colorEcho(fgCyan, "written in Nim, © 2019, COMAS, v", version, "\n")
  let (src, plate) = validateInput()
  cpTransfer(src, plate)
