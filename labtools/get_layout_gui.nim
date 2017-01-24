import os,
       strutils   # unindent

import ui      # https://github.com/nim-lang/ui
# from ui/rawui import controlEnable, controlDisable
ui.init()

const lblDefault = "Select files, then press start..."

var
  mainWin: Window
  btnStart: Button
  lbl: Label
  validDelivFile, validEchofile: bool

proc showManual() =
  let manualText = """
  Get Layout
  A tool to combine the layouts from the delivery plate and the echo assay plate.
  The result is a table with two columns: Assay plate well and Batch_Id

  The tool takes two input files:
  1. <delivery file.csv> - the COMAS plate delivery file
  2. <Echo result file.xml>: Echo result file for the assy plate"
  The CSV input file needs to be comma-separated.
  The result file is written into the folder where the Echo result file is located.

  © 2017,  COMAS"""
  msgBox(mainWin, "Manual", unindent(manualText, 2))

proc onBtnDelivClicked() =
  enable(btnStart)
  discard

proc onBtnEchoClicked() =
  discard

proc onBtnStartClicked() =
  discard

proc main() =
  var
    btnDeliv, btnEcho: Button
    leDeliv, leEcho: Entry

  var menu = newMenu("Help")
  menu.addItem("Manual", showManual)

  mainWin = newWindow("Get Layout", 300, 170, true)
  mainWin.margined = true
  mainWin.onClosing = (proc (): bool = return true)

  let vBox = newVerticalBox(true)
  leDeliv = newEntry("")
  vBox.add(leDeliv)
  btnDeliv = newButton("Choose Plate Delivery File", onBtnDelivClicked)
  vBox.add(btnDeliv)
  #------------------------------------------------------------------------
  vBox.add(newLabel(" "))  # insert some space
  #------------------------------------------------------------------------
  leEcho = newEntry("")
  vBox.add(leEcho)
  btnEcho = newButton("Choose Echo Report File", onBtnEchoClicked)
  vBox.add(btnEcho)
  #------------------------------------------------------------------------
  vBox.add(newLabel(" "))  # insert some space
  #------------------------------------------------------------------------
  btnStart = newButton("Start!", onBtnStartClicked)
  disable(btnStart)
  vBox.add(btnStart)
  #------------------------------------------------------------------------
  lbl = newLabel(lblDefault)
  vBox.add(lbl)
  #------------------------------------------------------------------------
  mainWin.setChild(vBox)

  show(mainwin)
  mainLoop()

main()