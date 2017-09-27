## Concat multiple CSV files into one.

import os,       # walkFiles
       ospaths,  # /, splitFile
       strutils,  # parseInt, align, replace
       csvtable

const version = "0.1.0"

proc echoHelp =
    let
      appName = extractFilename(getAppFilename())
      help = """
        Concat multiple CSV files into one large one.
        Usage: $1 "filename_w_wildcards" [sep]
        The first parameter should be put in quotes.
        The second parameter separator is optional, default is tab ("\t").""".unindent % appName
    echo help
    quit(0)

proc concatCsv(fnPattern: string, sep: char) =
  var
    csvIn: CSVTblReader
    csvOut: CSVTblWriter
    headersOut: seq[string] = @[]
    firstFile = true
    lineCounter = 0
    fileCounter = 0
  let
    outFile = fnPattern.replace("*", "")

  for fn in walkFiles(fnPattern):
    fileCounter += 1
    let
      headersIn = csvIn.open(fn, sep=sep)
    if firstFile:
      firstFile = false
      headersOut = headersIn
      csvOut.open(outFile, headersOut, sep=sep)
    for dIn in csvIn:
      lineCounter += 1
      csvOut.writeRow(dIn)
  csvOut.close
  echo "Done."
  echo fileCounter, " files were combined with a total of ", lineCounter, " results."


when isMainModule:
  echo "CSV File Concatenator"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  let numParams = os.paramCount()
  if numParams < 1 or numParams > 2:
    echoHelp()
  let fnPattern = os.paramStr(1)
  var sep = '\t'
  if numParams == 2:
    sep = os.paramStr(1)[0]
  concatCsv(fnPattern, sep)
