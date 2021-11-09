## Split an SD file into multiple files of the given length,
## e.g. for processing on a cluster.
# nim -d:release -o:bin/sdfsplit c labtools/sdfsplit.nim

import std/os # fileExists, /, splitFile
import std/strutils # parseInt, align

const version = "0.1.0"

proc echoHelp(exitCode = 0) =
  echo "\nSplit a large SD file into smaller files of given length."
  echo "Usage: sdfsplit <orig_file.sdf> <length>"
  echo "       If only the file name is given, the number of records in the SD file is counted."
  quit(exitCode)

proc countRecords(fn: string): int =
  for line in fn.lines:
    if line.startsWith("$$$"):
      result += 1

proc splitSDF(fn: string, length: int) =
  var
    newFile = true
    recordCounter = 0
    fileCounter = 0
    outFile: File
  for line in fn.lines:
    if newFile:
      newFile = false
      fileCounter += 1
      let
        (dir, name, ext) = splitFile(fn)
        outFn = dir / name & "-" & align($fileCounter, 2, '0') & ext
      outFile = open(outFn, fmWrite)
    outFile.writeLine(line)
    if line.startsWith("$$$"):
      recordCounter += 1
    if recordCounter == length:
      newFile = true
      recordCounter = 0
      outFile.close
  if recordCounter != 0:
    # do a final close
    outFile.close


when isMainModule:
  echo "SDF File Splitter "
  echo "written in Nim, © 2021, COMAS, v", version, "\n"
  if os.paramCount() == 0:
    echoHelp(1)
  let fnOrig = os.paramStr(1)
  if not os.fileExists(fnOrig):
    echo "# File ", fnOrig, " does not exist."
    echoHelp(3)
  if os.paramCount() == 1:
    echo "Counting records in ", fnOrig, " ..."
    let numRecords = countRecords(fnOrig)
    echo "Number of records in file: ", numRecords
    quit(0)
  if os.paramCount() != 2:
    echoHelp(1)
  var length: int
  try:
    length = os.paramStr(2).parseInt
  except ValueError:
    echo "Length ", os.paramStr(2), " could not be converted to a number."
    echoHelp(2)
  echo "Splitting SD file ", fnOrig, " into ", length, " records per file..."
  splitSDF(fnOrig, length)
