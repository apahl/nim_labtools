# csv_combine_gui.nim
# compile for windows with:
# nim --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui -d:release -o:bin/CSVcombiner.exe c csv_combine_gui.nim

import
  os,
  ui,
  csv_combine,
  screeningTypes

const
  lbl1Default = "Select Technology, choose directory with"
  lbl2Default = " Envision result files, then press Start!"

var
  mainwin: ptr Window
  cbTechnology: ptr Combobox
  btnStart: ptr Button
  label1: ptr Label
  label2: ptr Label
  filename: string = ""
  technology: ReadOut

proc onClosing(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  ui.quit()
  return 0

proc shouldQuit(data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  return 1

template enableStart() =
  if technology != roNone and filename != "":
    label1.labelSetText("Ready to combine files.")
    label2.labelSetText("Press Start!")
    controlEnable(btnStart)

proc onCbTechnologyChanged(cb: ptr Combobox; data: pointer) {.cdecl.} =
  let idx = comboBoxSelected(cb)
  technology = ReadOut(idx)
  enableStart()

proc onBtnOpenClicked(b: ptr Button; data: pointer) {.cdecl.} =
  var fn = ui.openFile(mainwin)
  if fn == nil:
    filename = ""
    return
  else:
    filename = $fn
    enableStart()
    freeText(fn)

proc onBtnStartClicked(b: ptr Button; data: pointer) {.cdecl.} =
  if filename != "" and technology != roNone:
    let dir = parentDir(filename)
    try:
      let numOfFiles = combineDataInFolder(dir, technology==roHTRF)
      label1.labelSetText($technology & " mode was used.")
      label2.labelSetText($numOfFiles & " Files were combined. Done.")
    except FileFormatError, IOError:
      label1.labelSetText(lbl1Default)
      label2.labelSetText(lbl2Default)
      msgBoxError(mainwin, "", getCurrentExceptionMsg())


proc main() =
  var
    o: ui.InitOptions
    err: cstring
    box: ptr Box
    btnOpen: ptr Button

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
  cbTechnology = newCombobox()
  comboBoxAppend(cbTechnology, "Choose Technology...")
  comboBoxAppend(cbTechnology, $roAlpha)
  comboBoxAppend(cbTechnology, $roHTRF)
  comboboxSetSelected(cbTechnology, 0)
  boxAppend(box, cbTechnology, 0)
  comboboxOnSelected(cbTechnology, onCbTechnologyChanged, nil)
  btnOpen = newButton("Choose Dir...")
  btnOpen.buttonOnClicked(onBtnOpenClicked, nil)
  boxAppend(box, btnOpen, 0)
  btnStart = newButton("Start!")
  btnStart.buttonOnClicked(onBtnStartClicked, nil)
  controlDisable(btnStart)
  boxAppend(box, btnStart, 0)
  label1 = newLabel(lbl1Default)
  label2 = newLabel(lbl2Default)
  boxAppend(box, label1, 0)
  boxAppend(box, label2, 0)
  boxAppend(box, newLabel(""), 0)
  boxAppend(box, newLabel("(c) 2016 COMAS"), 0)
  controlShow(mainwin)
  ui.main()
  ui.uninit()

main()
