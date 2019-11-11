## Concat multiple CSV files into one.
# nim -d:release -o:bin/concat_csv c labtools/concat_csv.nim

import os,        # walkFiles
       ospaths,   # /, splitFile
       strutils,  # parseInt, replace
       csvtable

# 0.2.0 uses new csvtable v0.3.0 API
const version = "0.2.0"

proc echoHelp =
    let
      appName = extractFilename(getAppFilename())
      help = """
        Concat multiple CSV files into one large file.
        Usage: $1 "filename_w_wildcards" [sep]
        The first parameter should be put in quotes.
        The second parameter separator is optional, default is tab ("\t").""".unindent % appName
    echo help
    quit(0)

proc concatCsv(fnPattern: string, sep: char) =
  var
    csvOut: CSVTblWriter
    headersOut: seq[string] = @[]
    firstFile = true
    lineCounter = 0
    fileCounter = 0
  let
    outFile = fnPattern.replace("*", "")

  for fn in walkFiles(fnPattern):
    var csvIn = newCSVTblReader(fn, sep=sep)
    fileCounter += 1
    if firstFile:
      firstFile = false
      headersOut = csvIn.headers
      csvOut = newCSVTblWriter(outFile, headersOut, sep=sep)
    for dIn in csvIn:
      lineCounter += 1
      csvOut.writeRow(dIn)
  csvOut.close
  echo "Done."
  echo fileCounter, " files were combined with a total of ", lineCounter, " results."


when isMainModule:
  echo "CSV File Concatenator"
  echo "written in Nim, © 2018, COMAS, v", version, "\n"
  let numParams = os.paramCount()
  if numParams < 1 or numParams > 2:
    echoHelp()
  let fnPattern = os.paramStr(1)
  var sep = '\t'
  if numParams == 2:
    sep = os.paramStr(1)[0]
  concatCsv(fnPattern, sep)
