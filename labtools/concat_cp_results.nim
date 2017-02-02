## This is the simplified version that only concatenates
## the `Image.csv` files which contain the Median values per image
## APL, 30-Jan-2017
# Include:
# Metadata_Plate,Metadata_Site,Metadata_Well,
# Count_Cells,Count_Cytoplasm,Count_Nuclei,
# *Name*

# Exclude:
# Location,Orientation,Edge
import os,         # `/`
       strutils,   # isDigit, parseInt, find
       algorithm,  # sort
       tables

import csvtable # https://github.com/apahl/csvtable
# Metadata_Plate,Metadata_Site,Metadata_Well
const
  rows = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
          "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "AA", "AB", "AC", "AD", "AE", "AF"]
  inclHeaders = ["CellOutlines", "ImageNumber", "Metadata_Plate", "Metadata_Site", "Metadata_Well",
                 "Count_Cells", "Count_Cytoplasm", "Count_Nuclei"]
  exclHeaders = ["Object", "Location", "Orientation", "Edge", "Zernike",
                 "_X", "_Y", "ImageNumber", "Parent_Nuclei", "Euler", "Parent_Cells",
                 "Intensity","Parent_Nuclei"]
  numLinesExp = 3456
  version     = "0.5.1"

proc echoHelp =
  echo "\nConcatenate all CellProfiler `Image.csv` result files."
  echo "Usage: concat_cp_results <folder>"
  echo "<folder>: directory which contains the numerical subdirs that contain"
  echo "          the CP `Image.csv` result files."
  quit(0)

template directWrite(s: string): untyped =
  stdout.write s
  stdout.flushFile

proc formatWell(well: string): string =
  ## reformat "A1" to "A01", etc., if necessary
  doAssert(well.len > 1 and well.len < 5)
  result = well
  if well.len == 2:
    result = well[0] & "0" & well[1]
  elif well.len == 3:
    if well[1].isAlphaAscii:
      result = well[0..1] & "0" & well[2]

proc expandWell(well: string): tuple[row: int, column: int] =
  ## Expand wells (A01, B02, ...) into tuples[row, column]
  var well = formatWell(well)
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

proc selectHeaders(headers: seq[string]): seq[string] =
  ## include and exclude certain headers,
  ## returns a new sequence with the desired headers
  result = @[]
  for hd in headers:
    var keep = false
    for ihd in inclHeaders:
      if hd.find(ihd) >= 0:
        keep = true  # keep in any case
        break
      if hd.startsWith("Median_") or hd.startsWith("Mean_"):
        keep = true  # keep maybe...,
        for ehd in exclHeaders:
          if hd.find(ehd) >= 0:  # ...if not in the exclHeaders list
            keep = false
            break
    if keep:
      result.add(hd)

proc concat_cp_folder*(folder: string): int =
  ## Concatenates all `Image.csv` result files
  ## that are located in the numbered subdirs.
  ## Returns the number of combined folders.
  var
    firstFolder    = true
    resultFile: CSVTblWriter
    resultHeaders: seq[string]
    lnCtr = 0

  echo "Concatenating folders..."
  stdout.flushFile
  for kind, path in os.walkDir(folder, relative=true):
    if kind == pcDir and path[0].isDigit and os.fileExists(folder / path / "Image.csv"):
      var
        imgFile: CSVTblReader
        imgHeaders = imgFile.open(folder / path / "Image.csv", sep=',')
      if firstFolder:
        firstFolder = false
        resultHeaders = selectHeaders(imgHeaders)
        resultHeaders.add("plateColumn")
        resultHeaders.add("plateRow")
        resultFile.open(folder / "Results.csv", resultHeaders, sep=',')
      result += 1
      directWrite "*"
      if result mod 10 == 0:
        directWrite " "
      elif result mod 5 == 0:
        directWrite "."
      for line in imgFile:
        var
          resRow = newTable[string, string]()
          platePos = expandWell(line["Metadata_Well"])
        resRow["plateColumn"] = $platePos.column
        resRow["plateRow"] = $platePos.row
        lnCtr += 1
        for hd in line.keys:
          if hd in resultHeaders:
            resRow[hd] = line[hd]
        resultFile.writeRow(resRow)
  echo " "
  resultFile.close
  if lnCtr != numLinesExp:
    echo "WARNING: total number of lines (", lnCtr, ") does not equal expected number of lines (", numLinesExp, ")!"


when isMainModule:
  echo "Cell Profiler result file concatenator"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 1:
    echoHelp()
  let folder = os.paramStr(1)
  if os.existsDir(folder):
    let numOfDirs = concat_cp_folder(folder)
    echo "\nResult files from ", numOfDirs, " subdirs were combined."
  else:
    echo("# Dir does not exist.")
