# pic50_gui.nim
#[
compile for Linux with:
nim -d:release -o:bin/pic50_gui c pic50_gui.nim
compile for windows with:
nim --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui -d:release -o:bin/pIC50.exe c pic50_gui.nim
]#
import
  os,
  strutils,
  # tables,
  strfmt,
  ui,
  conversions

type
  Fields =  enum
    fIC50, fpIC50

var
  mainwin: ptr Window
  label1: ptr Label
  entry_IC50, entry_pIC50: ptr Entry
  cbConcUnit: ptr Combobox
  useComma = false

template fillComboBox(cbBox: ptr Combobox, units: typedesc[enum]): untyped =
  for unit in units:
    comboBoxAppend(cbBox, $unit)

template replaceComma() =
  if "," in text:
    text = text.replace(",", ".")
    useComma = true

template formatRsltText() =
  rsltText = "{0:.2f}".fmt(calcValue)
  if useComma:
    rsltText = rsltText.replace(".", ",")

proc onClosing(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  ui.quit()
  return 0

proc shouldQuit(data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  return 1

proc onBtnClearClicked(b: ptr Button; data: pointer) {.cdecl.} =
  echo "Clear clicked."
  comboboxSetSelected(cbConcUnit, 1)
  entrySetText(entry_IC50, "")
  entrySetText(entry_pIC50, "")

proc onBtnCalcClicked(b: ptr Button; data: pointer) {.cdecl.} =
  var
    ctext: cstring
    whatToCalc: Fields
    conc: ConcUnits
    text, rsltText: string
    nbr_IC50, nbr_pIC50, calcValue: float
    numOfFilledFields = 0
    valError = false

  echo "Calc clicked."
  # IC50
  ctext = entryText(entry_IC50)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbr_IC50 = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fIC50

  # pIC50
  ctext = entryText(entry_pIC50)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbr_pIC50 = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fpIC50

  if valError:
    echo "At least one field could not be converted to a number."
    label1.labelSetText("At least one field could not be converted to a number.")
    echo "Nothing will be calculated."
    return

  if numOfFilledFields != 1:
    echo "Too many or too few fields are filled."
    label1.labelSetText("Too many or too few fields are filled.")
    echo "Nothing will be calculated."
    return

  echo "Field ", whatToCalc, " will be calculated."
  if whatToCalc == fIC50:
    conc = comboboxSelected(cbConcUnit).ConcUnits
    calcValue = calc_IC50(nbr_pIC50, conc)
    scaleResult(calcValue, conc)
    formatRsltText()
    comboboxSetSelected(cbConcUnit, conc.ord)
    entrySetText(entry_IC50, rsltText)

  if whatToCalc == fpIC50:
    calcValue = calc_pIC50(nbr_IC50, comboboxSelected(cbConcUnit).ConcUnits)
    formatRsltText()
    entrySetText(entry_pIC50, rsltText)

  label1.labelSetText($whatToCalc & " was calculated.")


proc main() =
  var
    o: ui.InitOptions
    err: cstring
    boxMain, boxColumns, boxCol1, boxCol2, boxCol3, boxColBlank: ptr Box
    btnCalc, btnClear: ptr Button

  err = ui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return

  mainwin = newWindow("COMAS pIC50 Calculator", 470, 240, 1)
  windowSetMargined(mainwin, 1)
  windowOnClosing(mainwin, onClosing, nil)
  onShouldQuit(shouldQuit, nil)

  boxMain = newVerticalBox()
  boxSetPadded(boxMain, 1)
  windowSetChild(mainwin, boxMain)

  boxColumns = newHorizontalBox()
  boxSetPadded(boxColumns, 1)
  boxAppend(boxMain, boxColumns, 0)

  boxCol1 = newVerticalBox()
  boxSetPadded(boxCol1, 1)
  boxAppend(boxColumns, boxCol1, 0)

  boxAppend(boxCol1, newLabel("IC50:"), 0)
  entry_IC50 = newEntry()
  boxAppend(boxCol1, entry_IC50, 0)

  btnClear = newButton("Clear")
  btnClear.buttonOnClicked(onBtnClearClicked, nil)
  boxAppend(boxCol1, btnClear, 0)
#--------------------------------------------------------------
  boxCol2 = newVerticalBox()
  boxSetPadded(boxCol2, 1)
  boxAppend(boxColumns, boxCol2, 0)

  boxAppend(boxCol2, newLabel(""), 0)
  cbConcUnit = newCombobox()
  fillComboBox(cbConcUnit, ConcUnits)
  comboboxSetSelected(cbConcUnit, 1)
  boxAppend(boxCol2, cbConcUnit, 0)
#--------------------------------------------------------------
  boxColBlank = newVerticalBox()
  boxSetPadded(boxColBlank, 1)
  boxAppend(boxColumns, boxColBlank, 0)

  boxAppend(boxColBlank, newLabel("     "), 0)
#--------------------------------------------------------------
  boxCol3 = newVerticalBox()
  boxSetPadded(boxCol3, 1)
  boxAppend(boxColumns, boxCol3, 0)

  boxAppend(boxCol3, newLabel("pIC50"), 0)
  entry_pIC50 = newEntry()
  boxAppend(boxCol3, entry_pIC50, 0)
  btnCalc = newButton("Calc")
  btnCalc.buttonOnClicked(onBtnCalcClicked, nil)
  boxAppend(boxCol3, btnCalc, 0)
#--------------------------------------------------------------
  boxAppend(boxMain, newLabel(""), 0)
  boxAppend(boxMain, newLabel("Fill one field, the other will be calculated."), 0)
  label1 = newLabel("Comma or point may be used for decimal separation.")
  boxAppend(boxMain, label1, 0)
  boxAppend(boxMain, newLabel(""), 0)
  boxAppend(boxMain, newLabel("(c) 2016 COMAS"), 0)

  controlShow(mainwin)
  ui.main()
  ui.uninit()

main()
