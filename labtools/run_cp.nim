## Runs CellProfiler

import
  os,
  parseopt,
  strutils

const numOfImagesPerProc = 36

when isMainModule:
  var
    inputDir, outputDir: string
    numWorkers = 4  # use countProcessors() from osproc later
    startImage = 1

  for kind, key, val in getOpt():
    case kind
      of cmdArgument:
        echo "Arg"
      of cmdShortOption, cmdLongOption:
        echo "Option: ", key, " ", val
        case key
          of "i", "input":
            inputDir = val
            if not existsDir(inputDir):
              echo "input dir does not exist (", inputDir, ")"
              quit(1)
          of "o", "output":
            outputDir = val
            if not existsDir(outputDir):
              echo "output dir does not exist (", outputDir, ")"
              quit(1)
          of "s", "start":
            try:
              let v = val.parseInt
              startImage = v
            except ValueError:
              echo "start image number (1 - 3456) has to given"
              quit(1)
            if startImage < 1 or startImage > 3456:
              echo "start image number is out of range (1 - 3456)"
              quit(1)
          of "w", "workers":
            try:
              let v = val.parseInt
              numWorkers = v
            except ValueError:
              echo "number of workers has to be given"
              quit(1)
            if numWorkers < 1 or numWorkers > 8:
              echo "too many workers (", numWorkers, ")!"
              quit(1)

          else:
            echo "unknown option ", key
            quit(1)
      of cmdEnd: discard
  echo numWorkers, " ", inputDir, " ", outputDir