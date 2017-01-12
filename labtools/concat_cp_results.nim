import os,         # `/`
       strutils,   # isDigit, parseInt
       algorithm,  # sort
       sequtils,   # toSeq
       tables

import csvtable # https://github.com/apahl/csvtable
# Metadata_Plate,Metadata_Site,Metadata_Well
const
  # Image.csv has to be the first file in the list, because it contains the Well metadata
  cpFileNames = ["Image.csv", "Cells.csv", "Cytoplasm.csv", "Nuclei.csv"]

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
    wellTable      = newTable[int, string]()
    plateId: string
    firstIteration = true
    firstFolder    = true
    firstImageFile = true
    numOfDirs      = 0

  for cpFileName in cpFileNames:
    echo "\nConcatenating ", cpFileName, "..."
    stdout.write "    "
    var outFile: CSVTblWriter
    for kind, path in os.walkDir(folder, relative=true):
      if kind == pcDir and path[0].isDigit:
        stdout.write "."
        stdout.flushFile
        var cpResultFile: CSVTblReader
        var headers = cpResultFile.open(folder / path / cpFileName, sep=',')
        if not outFile.isOpen:
          if not(cpFileName == "Image.csv"):  # the other files will have these two columns added
            headers.add("Metadata_Plate")
            headers.add("Metadata_Well")
          outFile.open(folder / cpFileName, headers, sep=',')
        if firstFolder:
          firstFolder = false
          os.copyFile(folder / path / "Experiment.csv", folder / "Experiment.csv")
        if firstIteration:
          numOfDirs += 1
        for ln in cpResultFile.items:
          var line: Table[string, string]
          shallowcopy(line, ln)
          if cpFileName == "Image.csv":
            if firstImageFile:
              firstImageFile = false
              plateId = line["Metadata_Plate"]
            let imageNumber = line["ImageNumber"].parseInt
            wellTable[imageNumber] = line["Metadata_Well"]
          else:  # write well metadata into the other files
            let imageNumber = line["ImageNumber"].parseInt
            line["Metadata_Plate"] = plateId
            line["Metadata_Well"] = wellTable[imageNumber]
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
