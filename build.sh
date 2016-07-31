#!/bin/bash
TARGET=$1

if [[ $TARGET == "" ]]; then
  TARGET="all"
fi
if [[ $TARGET =~ "lin" || $TARGET == "all" ]]; then
  echo "Building csv_combine_gui for Linux..."
  nim -d:release c csv_combine_gui.nim
  echo
fi
if [[ $TARGET =~ "win" || $TARGET == "all" ]]; then
  echo "Building csv_combine_gui for Windows..."
  nim --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui -d:release c csv_combine_gui.nim
fi
