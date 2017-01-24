import os,         # `/`
       strutils,   # isDigit, parseInt
       algorithm,  # sort
       sequtils,   # toSeq
       tables

import csvtable # https://github.com/apahl/csvtable
# Metadata_Plate,Metadata_Site,Metadata_Well
const
  rows = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
          "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "AA", "AB", "AC", "AD", "AE", "AF"]
  # Image.csv has to be the first file in the list, because it contains the Well metadata
  cpFileNames = ["Image.csv", "Cells.csv", "Cytoplasm.csv", "Nuclei.csv"]

proc echoHelp =
  echo "\nConcatenate all CellProfiler result files."
  echo "Usage: concat_cp_results <folder>"
  echo "<folder>: directory which contains the numerical subdirs that contain the CP result files."
  quit(0)

proc expandWell(well: string): tuple[row: int, column: int] =
  ## Expand wells (A01, B02, ...) into tuples[row, column]
  doAssert(well.len == 3 or well.len == 4)
  var idxHigh: int
  if well.len == 3:
    idxHigh = 0
  else:
    idxHigh = 1
  let idx = rows.find(well[0..idxHigh])
  if idx < 0:
    raise newException(IndexError, "Row denominator not found: " & well[0..idxHigh])
  result.row = idx + 1
  result.column = well[^2..^1].parseInt

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
            headers.add("plateRow")
            headers.add("plateColumn")
          outFile.open(folder / cpFileName, headers, sep=',')
        if firstFolder:
          firstFolder = false
          os.copyFile(folder / path / "Experiment.csv", folder / "Experiment.csv")
        if firstIteration:
          numOfDirs += 1
        for ln in cpResultFile:
          var line: Table[string, string]
          shallowcopy(line, ln)  # make the line editable
          if cpFileName == "Image.csv":
            if firstImageFile:
              firstImageFile = false
              plateId = line["Metadata_Plate"]
            let imageNumber = line["ImageNumber"].parseInt
            wellTable[imageNumber] = line["Metadata_Well"]
          else:  # write well metadata into the other files
            # replace "nan"s
            for k in line.keys:
              if line[k] == "nan":
                line[k] = ""
            let imageNumber = line["ImageNumber"].parseInt
            let well = wellTable[imageNumber]
            let expWell = expandWell(well)
            line["Metadata_Plate"] = plateId
            line["Metadata_Well"] = wellTable[imageNumber]
            line["plateRow"] = $expWell.row
            line["plateColumn"] = $expWell.column
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
