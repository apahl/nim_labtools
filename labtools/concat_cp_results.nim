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
  excludeHeaders = ["Object", "Location", "Orientation", "Edge", "Zernike",
                    "_X", "_Y", "ImageNumber"]

proc echoHelp =
  echo "\nConcatenate all CellProfiler result files."
  echo "Usage: concat_cp_results <folder>"
  echo "<folder>: directory which contains the numerical subdirs that contain the CP result files."
  quit(0)

template directWrite(s: string): untyped =
  stdout.write s
  stdout.flushFile

proc showProgress(ctr: int) =
  const progress = [".", "o", "O", "O", "o", "."]
  let idx = ctr mod progress.len
  directWrite "\b" & progress[idx]

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

proc addHeaders(s: var seq[string], headers: var seq[string], prefix: string) =
  ## prepare one total header with the prefix from the single files
  ## and exclude the headers that are in `excludeHeaders`
  var hdHigh = headers.high
  for idx in countdown(hdHigh, 0):
    var pos: int
    for excl in excludeHeaders:
      pos = headers[idx].find(excl)
      if pos >= 0:
        headers.delete(idx)
        break
    if pos < 0:
      s.add(prefix & headers[idx])

proc concat_cp_folder*(folder: string): int =
  ## Concatenates all CellProfiler result files
  ## that are located in the numbered subdirs.
  ## Returns the number of combined folders.
  var
    firstFolder    = true
    resultFile: CSVTblWriter
    resultHeaders = @["Metadata_Plate", "Metadata_Well", "plateColumn", "plateRow"]

  echo "Concatenating folders..."
  stdout.flushFile
  for kind, path in os.walkDir(folder, relative=true):
    if kind == pcDir and path[0].isDigit and os.fileExists(folder / path / "Image.csv"):
      var
        imgFile, cellsFile, cytFile, nuclFile: CSVTblReader
        cellsHeaders = cellsFile.open(folder / path / "Cells.csv", sep=',')
        cytHeaders   = cytFile.open(folder / path / "Cytoplasm.csv", sep=',')
        nuclHeaders  = nuclFile.open(folder / path / "Nuclei.csv", sep=',')
        wellTbl      = newTable[int, string]()
        plateIdTbl   = newTable[int, string]()
      discard imgFile.open(folder / path / "Image.csv", sep=',')  # the image headers are not needed
      directWrite "."
      if firstFolder:
        firstFolder = false
        resultHeaders.addHeaders(cellsHeaders, "Cells_")
        resultHeaders.addHeaders(cytHeaders, "Cyt_")
        resultHeaders.addHeaders(nuclHeaders, "Nucl_")
        resultFile.open(folder / "Results.csv", resultHeaders, sep=',')
      result += 1
    # read in plate and well information per imagenumber
      for line in imgFile:
        let imageNumber = line["ImageNumber"].parseInt
        plateIdTbl[imagenumber] = line["Metadata_Plate"]
        wellTbl[imageNumber] = line["Metadata_Well"]
      var
        inpRow = cellsFile.next()
        lineCtr = 0
      while inpRow.len > 0:
        var
          resRow = newTable[string, string]()
          imageNumber = inpRow["ImageNumber"].parseInt
          plateId = plateIdTbl[imageNumber]
          well = wellTbl[imageNumber]
          platePos = expandWell(well)
        lineCtr += 1
        if lineCtr mod 200 == 0:
          showProgress(lineCtr div 200)
        resRow["Metadata_Plate"] = plateId
        resRow["Metadata_Well"] = well
        resRow["plateColumn"] = $platePos.column
        resRow["plateRow"] = $platePos.row

        for h in inpRow.keys:
          if h notin excludeHeaders:
            resRow["Cells_" & h] = inpRow[h]

        inpRow = cytFile.next()
        if inpRow["ImageNumber"].parseInt != imageNumber:
          raise(newException(ValueError, "Imagenumber does not match in " & folder / path / "Cytoplasm.csv"))
        for h in inpRow.keys:
          if h notin excludeHeaders:
            resRow["Cyt_" & h] = inpRow[h]

        inpRow = nuclFile.next()
        if inpRow["ImageNumber"].parseInt != imageNumber:
          raise(newException(ValueError, "Imagenumber does not match in " & folder / path / "Nuclei.csv"))
        for h in inpRow.keys:
          if h notin excludeHeaders:
            resRow["Nucl_" & h] = inpRow[h]

        resultFile.writeRow(resRow)
        inpRow = cellsFile.next()
      directWrite "\b*"
      if result mod 10 == 0:
        directWrite " "
  echo " "
  resultFile.close


when isMainModule:
    if os.paramCount() != 1:
      echoHelp()
    let folder = os.paramStr(1)
    if os.existsDir(folder):
      let numOfDirs = concat_cp_folder(folder)
      echo "\nResult files from ", numOfDirs, " subdirs were combined."
    else:
      echo("# Dir does not exist.")
