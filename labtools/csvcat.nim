## Concat multiple CSV files into one.
# nim -d:release -o:bin/csvcat c labtools/csvcat.nim

import os, # paramCount, paramStr, fileExists
  strutils, # %, unindent
  csvtable

const version = "0.2.0"

type
  Arguments = object
    filesToCombine: seq[string]
    resultFile: string
    sep: char
    force: bool
    error: string

template debugMsg(msg: varargs[untyped]) =
  when not defined(release):
    echo "DEBUG: ", msg

proc echoHelp =
  let
    appName = extractFilename(getAppFilename())
    help = """
        Concat multiple CSV files into one large file.
        Usage: $1 [-f] [-s "," | "\t"] <files_to_combine> <name_of_combined_file>
        On unix the files_to_combine can contain wildcards (not tested on other systems).
        The last argument is the name of the file, into which all files are combined.
            If that file already exists and should be overwritten, the "-f" (force)
            argument has to be given.
        The "-s" denotes the field separator, default is tab ("\t").""".unindent % appName
  echo help
  quit(0)

proc processCmdLine(): Arguments =
  ## Process the commandline arguments into the `Arguments` object
  var tmpFileList: seq[string]
  result.sep = '\t'
  let pCount = paramCount()
  var ix = 0
  while ix < pCount: # paramCount starts at `1`
    ix += 1 # index for current iteration
    let arg = paramStr(ix)
    if arg == "-f" or arg == "--force":
      result.force = true
      continue
    if arg == "-s" and ix < pCount:
      ix += 1
      result.sep = paramStr(ix)[0]
      continue
    if ix == pCount:
      result.resultFile = arg
      continue
    tmpFileList.add(arg)
  # Make sure that the resultFile is not among the list of files to combine:
  for f in tmpFileList:
    if f != result.resultFile:
      result.filesToCombine.add(f)
  if result.filesToCombine.len == 0:
    result.error = "no files to combine."
  if result.resultFile == "":
    result.error = "no result file identified."
  debugMsg(result)

proc concatCsv(args: Arguments) =
  var
    csvOut: CSVTblWriter
    headersOut: seq[string] = @[]
    firstFile = true
    lineCounter = 0
    fileCounter = 0

  for fn in args.filesToCombine:
    var csvIn = newCSVTblReader(fn, sep = args.sep)
    fileCounter += 1
    if firstFile:
      firstFile = false
      headersOut = csvIn.headers
      csvOut = newCSVTblWriter(args.resultFile, headersOut, sep = args.sep)
    for dIn in csvIn:
      lineCounter += 1
      csvOut.writeRow(dIn)
  csvOut.close
  echo "Done."
  echo fileCounter, " files were combined into `", args.resultFile,
      "` with a total of ", lineCounter, " lines."


when isMainModule:
  echo "CSV File Concatenator"
  echo "written in Nim, © 2019, COMAS, v", version, "\n"
  let numParams = os.paramCount()
  if numParams < 1:
    echoHelp()
  let args = processCmdLine()
  if args.error != "":
    echo "Error: ", args.error
    quit(1)
  if fileExists(args.resultFile):
    if not args.force:
      echo "output file ", args.resultFile, " exists and will not be overwritten."
      echo "use `-f` to force overwrite."
      quit(1)
  concatCsv(args)
