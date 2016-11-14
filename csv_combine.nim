import os
import strutils   # isAlphaAscii, split, join, contains (used by `in`)
import algorithm  # sort
import sequtils   # toSeq

proc readDataFromCSV(fn: string): string =
  var
    idx = 0
    cells: seq[string]
    output, data: seq[string] = @[]
    barcode, assay_id, values, name: string

  for line in lines(fn):
    idx += 1
    if line.startsWith("Assay ID"):
      cells = line.split(",")
      assay_id = cells[4]
      break
    elif idx == 3:
      cells = line.split(",")
      barcode = cells[2]
      if not barcode[0].isAlphaAscii:
        barcode = ""
    elif idx >= 11 and idx <= 26:
      cells = line.split(",")
      values = cells[1..24].join(",")
      output.add(values)

  name = assay_id
  if barcode.len > 0:
    name = name & "_" & barcode
  data.add(name)
  data.add(output)
  result = data.join("\n")

  return result


proc combineDataInFolder*(folder: string) =
  ## Combines the data from all csv files in the folder
  ## and writes the combined results into combined.csv

  let
    outPath = os.joinPath(folder, "combined.csv")
    mask = os.joinPath(folder, "*.csv")
  var
    file = open(outPath, fmWrite)
    csv_files = toSeq(os.walkFiles(mask))
  csv_files.sort(system.cmp)
  for fn in csv_files:
    if "combined" in fn: continue
    var data = readDataFromCSV(fn)
    file.write(data)
    file.write("\n\n")

  file.close()


when isMainModule:
    if os.paramCount() > 0:
        var folder = os.paramStr(1)

        if os.existsDir(folder):
            combineDataInFolder(folder)

        else:
            echo("# Dir does not exist.")
