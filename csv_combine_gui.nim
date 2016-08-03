# csv_combine_gui.nim
# compile for windows with:
# nim --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui -d:release -o:bin/CSVcombiner.exe c csv_combine_gui.nim

import
  os,
  ui,
  csv_combine

var
  mainwin: ptr Window
  label1: ptr Label
  label2: ptr Label
  filename: string

proc onClosing(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  ui.quit()
  return 0

proc shouldQuit(data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  return 1

proc onBtnOpenClicked(b: ptr Button; data: pointer) {.cdecl.} =
  var fn = ui.openFile(mainwin)
  if fn == nil:
    filename = ""
    return
  else:
    filename = $fn
    label1.labelSetText("Ready to combine files.")
    label2.labelSetText("Press Start!")
    freeText(fn)

proc onBtnStartClicked(b: ptr Button; data: pointer) {.cdecl.} =
  if filename != "":
    var dir = parentDir(filename)
    combineDataInFolder(dir)
    label1.labelSetText("Files were combined. Done.")
    label2.labelSetText("")


proc main() =
  var
    o: ui.InitOptions
    err: cstring
    box: ptr Box
    btnOpen: ptr Button
    btnStart: ptr Button

  err = ui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return

  mainwin = newWindow("CSV Combiner", 300, 170, 1)
  windowSetMargined(mainwin, 1)
  windowOnClosing(mainwin, onClosing, nil)
  onShouldQuit(shouldQuit, nil)
  box = newVerticalBox()
  boxSetPadded(box, 1)
  windowSetChild(mainwin, box)
  btnOpen = newButton("Choose Dir...")
  btnOpen.buttonOnClicked(onBtnOpenClicked, nil)
  boxAppend(box, btnOpen, 0)
  btnStart = newButton("Start!")
  btnStart.buttonOnClicked(onBtnStartClicked, nil)
  boxAppend(box, btnStart, 0)
  label1 = newLabel("Choose directory with Envision files,")
  label2 = newLabel("then press Start!")
  boxAppend(box, label1, 0)
  boxAppend(box, label2, 0)
  boxAppend(box, newLabel(""), 0)
  boxAppend(box, newLabel("(c) 2016 COMAS"), 0)
  controlShow(mainwin)
  ui.main()
  ui.uninit()

main()
