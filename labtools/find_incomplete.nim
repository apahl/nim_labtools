import os,         # `/`
       strutils    # isDigit, parseInt, find, repeat

const
  size    = 72  # number of images per task (48 tasks * 72 images = 3456)
  version = "0.1.2"

proc echoHelp =
  echo "\nFind CellProfiler array tasks that did not finish by scanning the log files"
  echo "in the *current* directory."
  echo "Usage: find_incomplete"
  quit(0)

proc scanLogFiles(): seq[string] =
  ## Scans the SGE array job log files in the current directory
  result = @[]
  for logFile in os.walkFiles("cellprof_48.o*"):
    let
      slice_str = logfile.split(".")[^1]
      slice = slice_str.parseInt
      lastImage = slice * size
      lastLine = "Image # " & $lastImage & ", module CreateBatchFiles # 20"
      f = open(logFile)
      log = f.readAll
      pos = log.rfind(lastLine)
    if pos == -1:
      result.add(logFile)


when isMainModule:
  echo "Find incomplete CellProfiler array tasks"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() > 0:
    echoHelp()
  let
    incompleteTasks = scanLogFiles()
    numIncompleteTasks = incompleteTasks.len
  if numIncompleteTasks == 0:
    echo "All tasks finished successfully."
  else:
    let taskWord = if numIncompleteTasks == 1: " Task " else: " Tasks "
    echo numIncompleteTasks, taskword, "did NOT finish:"
    for task in incompleteTasks:
      echo "  ", task



