## Split a csv file into multiple files of the given length,
## e.g. for processing on a cluster.

import os,       # existsDir
       ospaths,  # /, walkDirRec
       strutils  # in[str], replace

const version = "0.1.0"

proc echoHelp =
  echo "\nReplace the give text with the new file recursively."
  echo "Usage: replace_in_files <start_dir> <filename_substring> <text_old> <text_new>"
  echo "Both text parameters should be put in quotes."
  quit(0)

proc replaceTextRecur(startDir, filename, textOld, textNew: string): int =
  ## Replaces the text. Returns the number of files in which text was replaced.
  for fn in walkDirRec(startDir):
    if filename in fn:
      var text = readFile(fn)
      if textOld in text:
        result += 1
        text = replace(text, textOld, textNew)
        writeFile(fn, text)

when isMainModule:
  echo "Text Replacer"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 4:
    echoHelp()
  let
    startDir = os.paramStr(1)
    filename = os.paramStr(2)
    textOld = os.paramStr(3)
    textNew = os.paramStr(4)
  if os.existsDir(startDir):
    let numRepl = replaceTextRecur(startDir, filename, textOld, textNew)
    echo "* ", numRepl, " replacements were made."
  else:
    echo "# Dir ", startDir, " does not exist."
    echoHelp()
