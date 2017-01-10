# screeningTypes.nim
## Useful types in a screening environment

type
  PlateFormat* = enum
    pfUnknown, pf384, pf1536
  ReadOut* = enum
    roNone, roAlpha, roHTRF
  Row* = seq[float]
  Plate* = seq[Row]

const
  numCols*: array[PlateFormat, int] = [0, 24, 48]
  numRows*: array[PlateFormat, int] = [0, 16, 32]
  rowLetters* = "ABCDEFGHIJKLMNOPQRSTUVWXYZAAABACADAEAF"

proc `$`*(pf: PlateFormat): string =
  case pf
   of pfUnknown:  "Unknown"
   of pf384:      "384"
   of pf1536:     "1536"

proc `$`*(ro: ReadOut): string =
  case ro
   of roNone:  ""
   of roAlpha: "Alpha"
   of roHTRF:  "HTRF"

when isMainModule:  # compile and run for testing
  var
    r1, r2: Row
    p: Plate

  r1 = @[1.14, 2.45]
  r2 = @[3.14, 4.45]
  p = @[]
  p.add(r1)
  p.add(r2)
  doAssert p[0][0] == 1.14
  doAssert p[0][1] == 2.45
  doAssert p[1][0] == 3.14
  doAssert numCols[pf1536] == 48
  doAssert numRows[pf384] == 16
  doAssert $roAlpha == "Alpha"

  echo "[screeningTypes.nim] all tests passed."