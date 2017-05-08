import os,
       iup,
       get_layout

const constBtnSize = "150x"
var
  btnStart, lblStatus: PIhandle
  fnDeliv, fnEcho, lastPath: string

template enableStart() =
  if fnDeliv.len > 0 and fnEcho.len > 0:
    lblStatus.setAttribute("TITLE", "Press Start.")
    btnStart.setAttribute("ACTIVE", "YES")

proc onBtnDelivClicked(ih: PIhandle): cint {.cdecl.} =
  # iup.message("Delivery", "You clicked the Delivery button!")
  echo "Delivery button clicked."
  var fileDialog = fileDlg()
  discard fileDialog.setAttributes("TITLE=Choose Delivery File, ALLOWNEW=FALSE, EXTFILTER=CSV|*.csv|")
  if lastPath.len > 0:
    fileDialog.setAttribute("DIRECTORY", lastPath)
  popup(fileDialog, IUP_CENTER, IUP_CENTER)
  fnDeliv = $fileDialog.getAttribute("VALUE")
  lastPath = os.splitPath(fnDeliv).head
  enableStart()

proc onBtnEchoClicked(ih: PIhandle): cint {.cdecl.} =
  # iup.message("Delivery", "You clicked the Delivery button!")
  echo "Echo button clicked."
  var fileDialog = fileDlg()
  discard fileDialog.setAttributes("TITLE=Choose Echo File, ALLOWNEW=FALSE, EXTFILTER=XML|*.xml|")
  if lastPath.len > 0:
    fileDialog.setAttribute("DIRECTORY", lastPath)
  popup(fileDialog, IUP_CENTER, IUP_CENTER)
  fnEcho = $fileDialog.getAttribute("VALUE")
  lastPath = os.splitPath(fnEcho).head
  enableStart()

proc onBtnStartClicked(ih: PIhandle): cint {.cdecl.} =
  echo "Start button clicked!"
  lblStatus.setAttribute("TITLE", "Started.")
  let layout = genLayout(fnDeliv, fnEcho)
  layout.write(lastPath / "layout.csv")
  lblStatus.setAttribute("TITLE", "Layout written. Finished.")


when isMainModule:
  var lblStatusTxt = "Choose files, then press Start."

  discard iup.open(nil, nil)
  var btnDeliv = button("Choose File...", nil)
  discard btnDeliv.setCallback("ACTION", cast[ICallback](onBtnDelivClicked))
  btnDeliv.setAttribute("MINSIZE", constBtnSize)

  var btnEcho = button("Choose File...", nil)
  discard btnEcho.setCallback("ACTION", cast[ICallback](onBtnEchoClicked))
  btnEcho.setAttribute("MINSIZE", constBtnSize)

  btnStart = button("Start", nil)
  discard btnStart.setCallback("ACTION", cast[ICallback](onBtnStartClicked))
  btnStart.setAttribute("MINSIZE", constBtnSize)
  btnStart.setAttribute("ACTIVE", "NO")

  lblStatus = label(lblStatusTxt)
  lblStatus.setAttribute("NAME", "STATUSBAR")
  lblStatus.setAttribute("EXPAND", "HORIZONTAL")
  lblStatus.setAttribute("PADDING", "10x5")

  var vb = vbox(label("\nDelivery Layout:"),
                btnDeliv,
                label("\nEcho Result File:"),
                btnEcho,
                label(""),
                btnStart,
                lblStatus, nil)
  vb.setAttribute("GAP", "5")
  vb.setAttribute("ALIGNMENT", "ACENTER")

  var dlg = dialog(vb)
  dlg.setAttribute("TITLE", "Generate Layout")

  discard dlg.showXY(IUP_CENTER, IUP_CENTER)
  discard mainLoop()

  iup.close()