## Split a csv file into multiple files of the given length,
## e.g. for processing on a cluster.
# nim -d:release -o:bin/csvsplit c labtools/csvsplit.nim

import std/os # fileExists, /, splitFile
import std/strutils # parseInt, align

const version = "0.1.0"

proc echoHelp =
  echo "\nSplit a large CSV file into smaller files of given length."
  echo "Usage: csvsplit <orig_file.csv> <length>"
  quit(0)

proc splitcsv(fn: string, length: int) =
  var
    header: string
    firstLine = true
    lineCounter = 0
    fileCounter = 0
    outFile: File
  for line in fn.lines:
    if firstLine:
      header = line
      firstLine = false
      continue
    if lineCounter == 0:
      fileCounter += 1
      let
        (dir, name, ext) = splitFile(fn)
        outFn = dir / name & "-" & align($fileCounter, 2, '0') & ext
      outFile = open(outFn, fmWrite)
      outFile.writeLine(header)
    lineCounter += 1
    outFile.writeLine(line)
    if lineCounter == length:
      lineCounter = 0
      outFile.close
  if lineCounter != 0:
    # do a final close
    outFile.close


when isMainModule:
  echo "CSV File Splitter "
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 2:
    echoHelp()
  let fn_orig = os.paramStr(1)
  var length: int
  try:
    length = os.paramStr(2).parseInt
  except ValueError:
    echo "Length ", os.paramStr(2), " could not be converted to a number."
    echoHelp()
  if os.fileExists(fn_orig):
    splitcsv(fn_orig, length)
  else:
    echo "# File ", fn_orig, " does not exist."
    echoHelp()
