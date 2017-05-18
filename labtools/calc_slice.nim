import os,         # `/`, paramCount, paramStr
       strutils    # isDigit, parseInt, find, repeat

const
  version     = "0.1.0"

proc echoHelp =
  echo "\nCalculate the image numbers (first .. last) that comprise a CellProfiler slice."
  echo "Usage: calc_slice <num_of_tasks (48 or 96)> <slice_no (1 .. num_of_tasks)>"
  quit(0)

proc calcSlice(numTasks, sliceNum: int): tuple[first: int, last: int] =
  let imagesPerTask = 3456 div numTasks
  result.first = (sliceNum - 1) * imagesPerTask + 1
  result.last = slicenum * imagesPerTask

when isMainModule:
  echo "Calc CellProfiler slice "
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 2:
    echoHelp()
  let
    numTasksStr = os.paramStr(1)
    sliceNumStr = os.paramStr(2)
  var numTasks: int
  case numTasksStr
    of "48": numTasks = 48
    of "96": numTasks = 96
    else: echoHelp()
  var sliceNum: int
  try:
    sliceNum = sliceNumStr.parseInt
  except ValueError:
    echo "The slice number ", sliceNumStr, " could not be converted to a number."
    echoHelp()
  let imageSlice = calcSlice(numTasks, sliceNum)
  echo "The images for an array job of ", numTasks, " tasks range from"
  echo imageSlice.first, " to ", imageSlice.last

