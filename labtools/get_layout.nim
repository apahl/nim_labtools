import os,                  # `/`
       strutils,            # isDigit, parseInt
       xmlparser, xmltree,
       tables

import csvtable  # https://github.com/apahl/csvtable

type
  Layout = TableRef[string, string]

const
  batchCol = "Batch_ID"  # the name of the Batch_Id column in the delivery csv file
  version  = "0.3.0"

proc newLayout(): Layout =
  new(result)
  result[] = initTable[string, string]()

proc echoHelp =
  let msg = """
  get_layout
  A tool to combine the layouts from the delivery plate and the echo assay plate.
  The result is a table with two columns: Assay plate well and Batch_Id

  The tool takes two input files:
  1. <delivery file.csv> - the COMAS plate delivery file
  2. <Echo result file.xml>: Echo result file for the assy plate"
  The CSV input file needs to be comma-separated.
  The result is written into the folder where the Echo result file was loaded."""
  echo unindent(msg, 2)

proc checkFile(fn, ext: string): string =
  ## check if the file exists and has the right extension
  result = ""
  let fileExt = os.splitFile(fn)
  if not os.fileExists(fn):
    result = "File " & fn & " does not exist."
    return
  if fileExt.ext != ext:
    result = "File " & fn & " has the wrong extension. `" & ext & "` was expected."

template validateFile(fn: string, ext: string): untyped =
  let msg = checkFile(fn, ext)
  if msg.len > 0:
    echo msg
    echoHelp()
    quit(1)

proc formatWell(well: string): string =
  ## reformat "A1" to "A01", etc., if necessary
  doAssert(well.len > 1 and well.len < 5)
  result = well
  if well.len == 2:
    result = well[0] & "0" & well[1]
  elif well.len == 3:
    if well[1].isAlphaAscii:
      result = well[0..1] & "0" & well[2]

proc write*(layout: Layout, fn="layout.csv") =
  var layoutFile = open(fn, fmWrite)
  layoutFile.writeLine("Batch_Id,WellType,Conc [M],Well")
  for well, cpdId in layout:
    layoutFile.writeLine(cpdId & "," & well)

proc readDelivLayout(plateDelivFn: string): Layout =
  result = newLayout()
  var
    plateDelivFile: CSVTblReader
    # store the information from the delivery and the result layout file:
    # Well: Compound_Id (e.g. A01: 247115)
  # read the layout of the COMAS delivery plate:
  discard plateDelivFile.open(plateDelivFn, sep=',')
  for line in plateDelivFile:
    result[line["Address_384"]] = line[batchCol]

proc genLayout*(plateDelivFn, echoReportFn: string): Layout =
  result = newLayout()
  let
    delivLayout = readDelivLayout(plateDelivFn)
    xml = loadXml(echoReportFn)
  for elmnt in xml:
    if elmnt.kind == xnElement and elmnt.tag == "reportbody":
      for rec in elmnt:
        if rec.kind == xnElement and rec.tag == "record":
          var cpd, srcWell, destWell, destConc: string
          for field in rec:
            if field.kind == xnElement:
              case field.tag
                of "CompoundName": cpd      = field.innerText
                of "SrcWell":      srcWell  = formatWell(field.innerText)
                of "DestWell":     destWell = formatWell(field.innerText)
                of "DestConc":     destConc = field.innerText
                else: discard
          if destWell in result and result[destWell] != "DMSO,Control,":
            raise newException(ValueError, "destWell " & destWell & " already present in result.")
          if cpd == "":
            result[destWell] = "DMSO,Control,"
          else:
            result[destWell] = delivLayout[srcWell] & ",Compound," & destConc


when isMainModule:
  echo "Plate Layout"
  echo "written in Nim, © 2017, COMAS, v", version, "\n"
  if os.paramCount() != 2:
    echoHelp()
    quit(0)
  let
    plateDelivFn = os.paramStr(1)
    echoReportFn = os.paramStr(2)
    # layoutPath = os.splitPath(plateDelivFn).head
  validateFile(plateDelivFn, ".csv")
  validateFile(echoReportFn, ".xml")
  var layout = genLayout(plateDelivFn, echoReportFn)
  layout.write("layout.csv")
  echo "Layout was generated."


