import os
import strutils   # isAlphaAscii, parseFloat, split, join, contains (used by `in`)
import algorithm  # sort
import sequtils   # toSeq

import screeningTypes  # PlateFormat

type
  FileFormatError* = object of Exception
  Channel = seq[seq[string]]

proc removeEmpty(cells: var seq[string]) =
  ## Remove cells that are empty or only contain whitespace from the right end
  var
    last = cells.len - 1
    foundEmptyCells = false
  while cells[last].isNilOrWhitespace:
    foundEmptyCells = true
    last -= 1
  if foundEmptyCells:
    cells = cells[0..last]

proc serialize(channel: Channel): seq[string] =
  result = @[]
  for row in channel:
    let rowStr = row.join(",")
    result.add(rowStr)

proc calcRatio(channel1, channel2: Channel): Channel =
  ## Calculates and returns the ratio of channel1 / channel2
  result = @[]
  for idxRow in 0..channel1.len-1:
    var resRow: seq[string] = @[]
    for idxCol in 0..channel1[idxRow].len-1:
      let ratio = channel1[idxRow][idxCol].parseFloat / channel2[idxRow][idxCol].parseFloat
      resRow.add($ratio)
    result.add(resRow)

proc readDataFromCSV(fn: string, htrf=false): string =
  var
    idx = 0
    channelId = -1
    plateFormat: PlateFormat
    barcode_line = false
    maxRow, maxCol = [0, 0]
    cells, row: seq[string]
    output, data: seq[string] = @[]
    channel1, channel2: Channel = @[]
    barcode, assay_id, name: string

  for line in lines(fn):
    idx += 1
    if line.len < 3: continue
    cells = line.split(",")
    cells.removeEmpty
    if cells.len < 2: continue
    let firstCell = cells[0]
    if "Assay ID" in firstCell:
      if cells.len >= 5:
        assay_id = cells[4]
        break
      else:
        raise newException(FileFormatError, "line.startsWith(_Assay ID_)")
    elif barcode_line:
      if cells.len > 2:
        barcode = cells[2]
        barcode_line = false
        if barcode.len > 0 and not barcode[0].isAlphaAscii:
          barcode = ""
      else:
        raise newException(FileFormatError, "idx == 3")
    elif (cells.len > 2 and barcode.len == 0 and cells.len >= 3 and cells[2] == "Barcode"):
      barcode_line = true
    elif firstCell.len > 0 and firstCell in rowLetters:
      if firstCell == "A":
        channelId += 1
      maxRow[channelId] += 1
      row = cells[1..^1]
      if maxCol[channelId] == 0:
        maxCol[channelId] = row.len
      elif row.len != maxCol[channelId]:
        raise newException(FileFormatError, "Different row length in channel" & $(channelId+1) & ", row " & $maxRow[channelId])
      if channelId == 0:
        channel1.add(row)
      else:
        channel2.add(row)

  # data sanity checks
  if maxRow[0] != maxRow[1]:
    raise newException(FileFormatError, "FileFormatError: different row lengths maxRow[0] != maxRow[1] (" & $maxRow[0] & " != " & $maxRow[1] & ")")
  if maxCol[0] != maxCol[1]:
    raise newException(FileFormatError, "FileFormatError: different column lengths maxCol[0] != maxCol[1] (" & $maxCol[0] & " != " & $maxCol[1] & ")")
  if maxRow[0] == numRows[pf384] and maxCol[0] == numCols[pf384]:
    plateFormat = pf384
  if maxRow[0] == numRows[pf1536] and maxCol[0] == numCols[pf1536]:
    plateFormat = pf1536
  if plateFormat == pfUnknown:
    raise newException(FileFormatError, "FileFormatError: unknown plate format (neither 384 nor 1536: " & $maxRow[0] & "  " & $maxCol[0] & ")")
  if channelId == -1:  # no plate data was found.
    raise newException(FileFormatError, "FileFormatError: no data was found (channelId == 0)")
  if htrf:
    if channelId < 1:  # plate data was only found for one channel.
      raise newException(FileFormatError, "FileFormatError: plate data was only found for one channel (htrf and channelId < 1)")
    # divide the content of channel1 by that of channel2 and reassign to channel1
    data = serialize(calcRatio(channel1, channel2))
  else:
    data = serialize(channel1)

  name = assay_id
  if barcode.len > 0:
    name = name & "_" & barcode
  output.add(name)
  output.add(data)
  result = output.join("\n")

proc combineDataInFolder*(folder: string, htrf=false): int =
  ## Combines the data from all csv files in the folder
  ## and writes the combined results into combined.csv

  let
    outPath = os.joinPath(folder, "combined.csv")
    mask = os.joinPath(folder, "*.csv")
  var
    csv_files = toSeq(os.walkFiles(mask))
    numOfFiles = 0
  if csv_files.len == 0:
    raise newException(IOError, "No CSV files were found in " & folder)
  var file = open(outPath, fmWrite)
  csv_files.sort(system.cmp)
  for fn in csv_files:
    if "combined" in fn: continue
    try:
      var data = readDataFromCSV(fn, htrf=htrf)
      file.write(data)
      file.write("\n\n")
      numOfFiles += 1
    except FileFormatError:
      file.close()
      when defined(release):
        let msg = "File " & fn & " has the wrong format. No files were combined."
      else:  # give some more information in debug mode
        let msg = "FileFormatError: " & fn & "\n" & getCurrentExceptionMsg()
      raise newException(FileFormatError, msg)

  file.close()
  result = numOfFiles


when isMainModule:
    if os.paramCount() > 0:
        var
          folder = os.paramStr(1)
          htrf = false
        if os.paramCount() == 2:
          if os.paramStr(2) == "htrf":
            htrf = true
        if os.existsDir(folder):
            let numOfFiles = combineDataInFolder(folder, htrf=htrf)
            echo numOfFiles, " files were combined."
            if htrf:
              echo "  - HTRF mode"

        else:
            echo("# Dir does not exist.")
