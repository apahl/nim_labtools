## Exchanges rows and columns of an input table
import os,         # `/`
       strutils    # sep, join

type
  Table = seq[seq[string]]
  Dimension = tuple[x, y: int]

proc echoHelp =
  echo "\nTranspose a csv table."
  echo "Rows and columns are interchanged."
  echo "Usage: transpose_table <csv file>"
  echo "<file>: csv table to be transposed."
  quit(0)

proc resultFilename(fn: string, suffix: string): string =
  ## resultFilename("/home/path/test", suffix="_result.csv") -> "/home/path/test_result.csv"
  ## resultFilename("/home/path/test.csv", suffix="_result.csv") -> "/home/path/test_result.csv"
  ## resultFilename("/home/path/test.xxx.csv", suffix="_result.csv") -> "/home/path/test.xxx_result.csv"
  let splitExt = fn.split('.')
  if splitExt.len > 1:
    result = splitExt[0..^2].join(".") & suffix
  else:
    result = splitExt[0] & suffix

proc transpose(tbl: Table): Table =
  let
    inputDim: Dimension = (x: tbl[1].len, y: tbl.len)
  doAssert(inputDim.x > 0 and inputDim.y > 0)
  result = @[]
  for x in 0 .. inputDim.x-1:
    var row: seq[string] = @[]
    for y in 0 .. inputDim.y-1:
      row.add(tbl[y][x])
    result.add(row)

proc transpose(fn: string, sep=',') =
  var
    tbl: Table = @[]
  for line in fn.lines:
    let row = line.split(sep)
    tbl.add(row)
  let transposed = transpose(tbl)
  let resFn = resultFilename(fn, suffix="_transposed.csv")
  var f = open(resFn, mode=fmWrite)
  for row in transposed:
    f.writeLine(row.join($sep))
  f.close


when isMainModule:
    if os.paramCount() != 1:
      echoHelp()
    let csvFile = os.paramStr(1)
    if os.existsFile(csvFile):
      transpose(csvFile)
      echo csvFile, " was transposed."
    else:
      echo("# File does not exist.")
