# pic50_gui.nim
#[
compile for Linux with:
nim -d:release c pic50_gui.nim
compile for windows with:
nim --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --app:gui -d:release -o:bin/pIC50.exe c pic50_gui.nim
]#
import
  os,
  strutils,
  tables,
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
  rsltText = "{0:.3f}".fmt(calcValue)
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
    text, rsltText: string
    nbrMolwt, nbrWeight, nbrConc, nbrVol, calcValue: float
    numOfFilledFields = 0
    valError = false

  echo "Calc clicked."
  # Molwt
  ctext = entryText(entryMolwt)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbrMolwt = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fMolWt

  # Weight
  ctext = entryText(entryWeight)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbrWeight = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fWeight

  # Conc
  ctext = entryText(entryConc)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbrConc = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fConc

  # Vol
  ctext = entryText(entryVol)
  text = $ctext
  freeText(ctext)
  if text != "":
    replaceComma()
    try:
      nbrVol = text.parseFloat
      numOfFilledFields += 1
    except ValueError:
      echo "No number."
      valError = true
  else:
    whatToCalc = fVol

  if valError:
    echo "At least one field could not be converted to a number."
    label1.labelSetText("At least one field could not be converted to a number.")
    echo "Nothing will be calculated."
    return

  if numOfFilledFields != 3:
    echo "Too many or too few fields are filled."
    label1.labelSetText("Too many or too few fields are filled.")
    echo "Nothing will be calculated."
    return

  echo "Field ", whatToCalc, " will be calculated."
  if whatToCalc == fVol:
    calcValue = calcVol(nbrWeight, comboboxSelected(cbWeightUnit).WeightUnits,
                        nbrConc, comboboxSelected(cbConcUnit).ConcUnits,
                        nbrMolwt, comboboxSelected(cbVolUnit).VolumeUnits)
    formatRsltText()
    entrySetText(entryVol, rsltText)

  if whatToCalc == fWeight:
    calcValue = calcWeight(nbrVol, comboboxSelected(cbVolUnit).VolumeUnits,
                           nbrConc, comboboxSelected(cbConcUnit).ConcUnits,
                           nbrMolwt, comboboxSelected(cbWeightUnit).WeightUnits)
    formatRsltText()
    entrySetText(entryWeight, rsltText)

  if whatToCalc == fConc:
    calcValue = calcConc(nbrWeight, comboboxSelected(cbWeightUnit).WeightUnits,
                         nbrVol, comboboxSelected(cbVolUnit).VolumeUnits,
                         nbrMolwt, comboboxSelected(cbConcUnit).ConcUnits)
    formatRsltText()
    entrySetText(entryConc, rsltText)

  if whatToCalc == fMolWt:
    calcValue = calcMolwt(nbrWeight, comboboxSelected(cbWeightUnit).WeightUnits,
                          nbrVol, comboboxSelected(cbVolUnit).VolumeUnits,
                          nbrConc, comboboxSelected(cbConcUnit).ConcUnits)
    formatRsltText()
    entrySetText(entryMolwt, rsltText)

  label1.labelSetText($whatToCalc & " was calculated.")


proc main() =
  var
    o: ui.InitOptions
    err: cstring
    boxMain, boxColumns, boxCol1, boxCol2: ptr Box
    boxWeight, boxMolwt, boxConc, boxVol: ptr Box
    btnCalc, btnClear: ptr Button

  err = ui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return

  mainwin = newWindow("COMAS Concentration Calculator", 520, 280, 1)
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

  boxAppend(boxCol1, newLabel("Molwt:"), 0)
  boxMolwt = newHorizontalBox()
  boxSetPadded(boxMolwt, 1)
  boxAppend(boxCol1, boxMolwt, 0)
  entryMolwt = newEntry()
  boxAppend(boxMolwt, entryMolwt, 0)
  boxAppend(boxMolwt, newLabel("g / mol"), 0)

  boxAppend(boxCol1, newLabel("Concentration:"), 0)
  boxConc = newHorizontalBox()
  boxSetPadded(boxConc, 1)
  boxAppend(boxCol1, boxConc, 0)
  entryConc = newEntry()
  entrySetText(entryConc, "10.000")
  boxAppend(boxConc, entryConc, 0)
  cbConcUnit = newCombobox()
  fillComboBox(cbConcUnit, ConcUnits)
  comboboxSetSelected(cbConcUnit, 1)
  boxAppend(boxConc, cbConcUnit, 0)
  btnClear = newButton("Clear")
  btnClear.buttonOnClicked(onBtnClearClicked, nil)
  boxAppend(boxCol1, btnClear, 0)

#--------------------------------------------------------------
  boxCol2 = newVerticalBox()
  boxSetPadded(boxCol2, 1)
  boxAppend(boxColumns, boxCol2, 0)

  boxAppend(boxCol2, newLabel("Weight:"), 0)

  boxWeight = newHorizontalBox()
  boxSetPadded(boxWeight, 1)
  boxAppend(boxCol2, boxWeight, 0)
  entryWeight = newEntry()
  boxAppend(boxWeight, entryWeight, 0)
  cbWeightUnit = newCombobox()
  fillComboBox(cbWeightUnit, WeightUnits)
  comboboxSetSelected(cbWeightUnit, 1)
  boxAppend(boxWeight, cbWeightUnit, 0)

  boxAppend(boxCol2, newLabel("Volume:"), 0)
  boxVol = newHorizontalBox()
  boxSetPadded(boxVol, 1)
  boxAppend(boxCol2, boxVol, 0)
  entryVol = newEntry()
  boxAppend(boxVol, entryVol, 0)
  cbVolUnit = newCombobox()
  fillComboBox(cbVolUnit, VolumeUnits)
  comboboxSetSelected(cbVolUnit, 1)
  boxAppend(boxVol, cbVolUnit, 0)
  btnCalc = newButton("Calc")
  btnCalc.buttonOnClicked(onBtnCalcClicked, nil)
  boxAppend(boxCol2, btnCalc, 0)

  boxAppend(boxMain, newLabel(""), 0)
  boxAppend(boxMain, newLabel("Fill three fields, the fourth will be calculated."), 0)
  label1 = newLabel("Comma or point may be used for decimal separation.")
  boxAppend(boxMain, label1, 0)
  boxAppend(boxMain, newLabel(""), 0)
  boxAppend(boxMain, newLabel("(c) 2016 COMAS"), 0)

  controlShow(mainwin)
  ui.main()
  ui.uninit()

main()
