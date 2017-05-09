import os,         # `/`
       strutils    # isDigit, parseInt, find, repeat

const
  version     = "0.1.5"

proc echoHelp =
  echo "\nFind CellProfiler array tasks that did not finish by scanning the log files"
  echo "in the *current* directory."
  echo "Usage: find_incomplete <num_of_jobs (48 or 96)>"
  quit(0)

proc scanLogFiles(numJobs: int) =
  ## Scans the SGE array job log files in the current directory
  let
    globLogFile = "cellprof_" & $numJobs & ".o*"
    size: int = 3456 div numJobs  # number of images per task (48 tasks * 72 images = 3456)
  var
    incompleteTasks: seq[string] = @[]
    ctr: int
  for logFile in os.walkFiles(globLogFile):
    ctr += 1
    let
      slice_str = logfile.split(".")[^1]
      slice = slice_str.parseInt
      lastImage = slice * size
      lastLine = "Image # " & $lastImage & ", module CreateBatchFiles # 20"
      f = open(logFile)
      log = f.readAll
      pos = log.rfind(lastLine)
      spc = if slice < 10: " " else: ""
    if pos == -1:
      incompleteTasks.add(logFile)
      echo logFile, "   ", spc, "FAILED!"
    else:
      echo logFile, "   ", spc, "finished."
  echo "\nScanned ", ctr, " files.\n"

  let
    numIncompleteTasks = incompleteTasks.len
  if numIncompleteTasks == 0:
    echo "All tasks finished successfully."
  else:
    let taskWord = if numIncompleteTasks == 1: " Task " else: " Tasks "
    echo numIncompleteTasks, taskword, "did NOT finish:"
    for task in incompleteTasks:
      echo "  ", task


when isMainModule:
  echo "Find incomplete CellProfiler array tasks"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 1:
    echoHelp()
  let
    numJobsStr = os.paramStr(1)
  var numJobs: int
  case numJobsStr
    of "48": numJobs = 48
    of "96": numJobs = 96
    else: echoHelp()

  scanLogFiles(numJobs)


