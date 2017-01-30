import
  os,
  strutils

const
  numImages = 3456
  cmdIntro  = "#!/bin/bash\n"
  cmdQsub   = "qsub cellprof_slice.sh "
  cmdSleep  = "sleep 5"

proc usage():string =
  result = "\n\nusage: generate_qsub_batch <numOfJobs>\n"
  result &= "The actual number of jobs can be lower than the number given on the cmdline."

proc writeBatchQueue(numJobsCirca=100) =
  var
    imagesPerSlice = numImages div numJobsCirca
    numJobsActual = numImages div imagesPerSlice
    jobNoLoop: int

  if numImages mod imagesPerSlice > 0:
    numJobsActual += 1

  var
    fn = "submit_jobs_" & $numJobsActual & ".sh"
    file = open(fn, fmWrite)

  file.writeLine(cmdIntro)
  for jobNo in 0..numJobsCirca-1:
    var
      firstImage = jobNo * imagesPerSlice + 1
      lastImage  = (jobNo + 1) * imagesPerSlice
    if lastImage > numImages:
      lastImage = numImages
    file.writeLine(cmdQsub, firstImage, " ", lastImage)
    file.writeLine(cmdSleep)
    jobNoLoop = jobNo + 1
    if lastImage >= numImages:
      break

  file.close
  doAssert(jobNoLoop == numJobsActual, "Calculated job number and looped job number do not match.")


when isMainModule:
  let numArgs = paramCount()
  var numJobsCirca: int
  if numArgs != 1:
    quit("Please pass the number of jobs to be generated (<numOfJobs>)." & usage())
  try:
    numJobsCirca = paramStr(1).parseInt
  except ValueError:
    quit(paramStr(1) & " does not seem to be a number." & usage())

  writeBatchQueue(numJobsCirca)
