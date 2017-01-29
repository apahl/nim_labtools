# Package

version       = "0.6.0"
author        = "Axel Pahl"
description   = "A set of lab tool programs: csvCombiner, solutionCalculator, pIC50Calculator, HTRF_ratio."
license       = "MIT"

# Dependencies
requires "nim >= 0.15.3"
requires "strfmt >= 0.8.0"
requires "https://github.com/apahl/csvtable.git >= 0.1.1"

const
  projectName = "labtools"
  winFlags    = "--os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui "
  srcFiles    = ["csv_combine_gui", "solution_calc_gui", "pic50_gui",
                 "generate_qsub_batch", "concat_cp_results", "transpose_table",
                 "get_layout", "get_layout_gui"]  # WITHOUT the .nim extension
  winBinaries = ["CSVcombiner.exe", "SolutionCalculator.exe", "pIC50Calculator.exe",
                 "generateQsubBatch.exe", "ConcatCPResults.exe", "TranposeTable.exe",
                 "", "getLayout.exe"]  # WITH the .exe extension

proc buildFiles(srcFiles, binFiles: openarray[string]; flags=""; release=false) =
  var
    flags = flags
    releaseFlag = ""

  flags.add("-d:useLibUiDll")

  if release:
    releaseFlag = "--verbosity:0 -d:release "

  if flags.len > 0 and flags[^1] != ' ':
    flags.add(" ")

  for i in 0 .. <srcFiles.len:
    if binFiles[i] != "":  # only build the GUI tools for Windows, not the cmdline versions
      let buildCmd = "nim " & flags & releaseFlag & "-o:bin/" & binFiles[i] & " c " & projectName & "/" & srcFiles[i] & ".nim"
      exec buildCmd

task info, "detailed package info":
  echo "Do *NOT* use `nimble install` with this package."
  echo "Use the individual tasks listed below instead."
  echo "Package dependencies: strfmt, https://github.com/apahl/csvtable.git"

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

task buildCSVCombine, "build CSVCombiner development executable for Linux and Windows":
  echo("Building CSVCombiner development executables for Linux and Windows...")
  buildFiles(srcFiles[0..0], srcFiles[0..0])
  buildFiles(srcFiles[0..0], winBinaries[0..0], winFlags)

task relCSVCombine, "build CSVCombiner release executable for Linux and Windows":
  echo("Building CSVCombiner release executables for Linux and Windows...")
  buildFiles(srcFiles[0..0], srcFiles[0..0], release=true)
  buildFiles(srcFiles[0..0], winBinaries[0..0], winFlags, release=true)

task buildQsubBatch, "build generate_qsub_batch development executable for Linux":
  echo("Building generate_qsub_batch development executable for Linux...")
  buildFiles(srcFiles[3..3], srcFiles[3..3])
  # buildFiles(srcFiles[3..3], winBinaries[3..3], winFlags)

task relQSubBatch, "build generate_qsub_batch release executable for Linux":
  echo("Building generate_qsub_batch release executable for Linux...")
  buildFiles(srcFiles[3..3], srcFiles[3..3], release=true)
  # buildFiles(srcFiles[3..3], winBinaries[3..3], winFlags, release=true)

task buildConcatCPResults, "build concat_cp_results development executable for Linux":
  echo("Building concat_cp_results development executable for Linux...")
  buildFiles(srcFiles[4..4], srcFiles[4..4])
  # buildFiles(srcFiles[3..3], winBinaries[3..3], winFlags)

task relConcatCPResults, "build concat_cp_results release executable for Linux":
  echo("Building concat_cp_results release executable for Linux...")
  buildFiles(srcFiles[4..4], srcFiles[4..4], release=true)
  # buildFiles(srcFiles[3..3], winBinaries[3..3], winFlags, release=true)

task buildTransposeTable, "build transpose_table development executable for Linux":
  echo("Building transpose_table development executable for Linux...")
  buildFiles(srcFiles[5..5], srcFiles[5..5])
  # buildFiles(srcFiles[5..5], winBinaries[5..5], winFlags)

task relTransposeTable, "build transpose_table release executable for Linux":
  echo("Building transpose_table release executable for Linux...")
  buildFiles(srcFiles[5..5], srcFiles[5..5], release=true)
  # buildFiles(srcFiles[5..5], winBinaries[5..5], winFlags, release=true)

task buildGetLayout, "build get_layout development executable for Linux and Windows":
  echo("Building get_layout development executables for Linux and Windows...")
  buildFiles(srcFiles[6..6], srcFiles[6..6])
  buildFiles(srcFiles[7..7], srcFiles[7..7])
  buildFiles(srcFiles[7..7], winBinaries[7..7], winFlags)

task relGetLayout, "build get_layout release executable for Linux and Windows":
  echo("Building get_layout release executable for Linux and Windows...")
  buildFiles(srcFiles[6..6], srcFiles[6..6], release=true)
  buildFiles(srcFiles[7..7], srcFiles[7..7], release=true)
  buildFiles(srcFiles[7..7], winBinaries[7..7], winFlags, release=true)
