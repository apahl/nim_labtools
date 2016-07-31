import os
import algorithm  # sort
import strutils  # split
import sequtils  # toSeq

proc readDataFromCSV(fn: string): string =
    var
        idx = 0
        cells: seq[string]
        output, data: seq[string] = @[]
        barcode, assay_id, values: string

    for line in lines(fn):
        idx += 1
        if idx == 3:
            cells = line.split(",")
            barcode = cells[2]
        elif idx == 30:
            cells = line.split(",")
            assay_id = cells[4]
            break
        elif idx >= 11 and idx <= 26:
            cells = line.split(",")
            values = cells[1..24].join(",")
            output.add(values)

    data.add(assay_id & "_" & barcode)
    data.add(output)
    result = data.join("\n")

    return result


proc combineDataInFolder*(folder: string) =
    ## Combines the data from all csv files in the folder
    ## and writes the combined results into combined.csv

    var outPath = os.joinPath(folder, "combined.csv")
    var mask = os.joinPath(folder, "*.csv")
    var file = open(outPath, fmWrite)
    var csv_files = toSeq(os.walkFiles(mask))
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
