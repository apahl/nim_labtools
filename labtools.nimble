# Package

version       = "0.5.0"
author        = "Axel Pahl"
description   = "A set of lab tool programs: csvCombiner, solutionCalculator, pIC50Calculator."
license       = "MIT"

# Dependencies

requires "nim >= 0.14.2"
requires "strfmt >= 0.8.0"

const
  winFlags = "--os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui "
  srcFiles = ["csv_combine_gui", "solution_calc_gui", "pic50_gui"]  # WITHOUT the .nim extension
  winBinaries = ["CSVcombiner.exe", "SolutionCalculator.exe", "pIC50Calculator.exe"]  # WITH the .exe extension

proc buildFiles(srcFiles, binFiles: openarray[string]; flags=""; release=false) =
  var
    flags = flags
    releaseFlag = ""

  if release:
    releaseFlag = "--verbosity:0 -d:release "

  if flags.len > 0 and flags[^1] != ' ':
    flags.add(" ")

  for i in 0 .. <srcFiles.len:
    let buildCmd = "nim " & flags & releaseFlag & "-o:bin/" & binFiles[i] & " c " & srcFiles[i] & ".nim"
    exec buildCmd

task buildLinux, "build development executables for linux":
  echo("Building development executables for linux...")
  buildFiles(srcFiles, srcFiles)

task buildWin, "build development executables for windows":
  echo("Building development executables for windows...")
  buildFiles(srcFiles, winBinaries, winFlags)

task releaseLinux, "build release executables for linux":
  echo("Building release executables for linux...")
  buildFiles(srcFiles, srcFiles, release=true)

task releaseWin, "build release executables for windows":
  echo("Building release executables for windows...")
  buildFiles(srcFiles, winBinaries, winFlags, release=true)
