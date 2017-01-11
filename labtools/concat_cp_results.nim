import os         # `/`
import strutils   # isAlphaAscii, parseFloat, split, join, contains (used by `in`)
import algorithm  # sort
import sequtils   # toSeq

import csvtable

const
  cpFileNames = ["Cells.csv", "Cytoplasm.csv", "Image.csv", "Nuclei.csv"]

proc echoHelp =
  echo "\nConcatenate all CellProfiler result files."
  echo "Usage: concat_cp_results <folder>"
  echo "<folder>: directory which contains the numerical subdirs that contain the CP result files."
  quit(0)

proc concat_cp_folder*(folder: string): int =
  ## Concatenates all CellProfiler result files
  ## that are located in the numbered subdirs.
  ## Returns the number of combined folders.
  var
    firstIteration = true
    firstFolder = true
    numOfDirs = 0
  for cpFileName in cpFileNames:
    echo "\nConcatenating ", cpFileName, "..."
    stdout.write "    "
    var outFile: CSVTblWriter
    for kind, path in os.walkDir(folder, relative=true):
      if kind == pcDir and path[0].isDigit:
        stdout.write "."
        stdout.flushFile
        var cpResultFile: CSVTblReader
        let headers = cpResultFile.open(folder / path / cpFileName, sep=',')
        if not outFile.isOpen:
          outFile.open(folder / cpFileName, headers, sep=',')
        if firstFolder:
          firstFolder = false
          os.copyFile(folder / path / "Experiment.csv", folder / "Experiment.csv")
        if firstIteration:
          numOfDirs += 1
        for line in cpResultFile:
          outFile.writeRow(line)
    outFile.close
    echo ""
    firstIteration = false
  result = numOfDirs


when isMainModule:
    if os.paramCount() != 1:
      echoHelp()
    let folder = os.paramStr(1)
    if os.existsDir(folder):
      let numOfDirs = concat_cp_folder(folder)
      echo "\nResult files from ", numOfDirs, " subdirs were combined."
    else:
      echo("# Dir does not exist.")
