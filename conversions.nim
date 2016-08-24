from math import pow, log10

type
  ConcUnits* = enum
    M, mM, uM, nM

  VolumeUnits* = enum
    L, mL, uL

  WeightUnits* = enum
    g, mg

proc unitToBase*(x: float; unit: enum): float =
  result = x * pow(10.0, -3.0 * unit.ord.float)

proc baseToUnit*(x: float; unit: enum): float =
  result = x * pow(10.0, 3.0 * unit.ord.float)

proc scaleResult*[T: enum](val: var float; unit: var T, minVal=0.1) =
  ## If the value is small, readability is increased by using a larger value and a smaller unit.
  ## This procedure increases the value by order-of-magnitude steps and takes the unit with it.
  ## Parameters are modified in-place!
  while val < minVal and unit < unit.high:
    val *= 1000.0
    inc unit

proc calcVol*(weight: float; weightUnit: WeightUnits;
              conc: float; concUnit: ConcUnits;
              molWeight: float; resultUnit: VolumeUnits): float =
  result = unitToBase(weight, weightUnit) / molWeight
  result = result / unitToBase(conc, concUnit)
  result = baseToUnit(result, resultUnit)

proc calcWeight*(vol: float; volUnit: VolumeUnits;
                 conc: float; concUnit: ConcUnits;
                 molWeight: float; resultUnit: WeightUnits): float =
  result = unitToBase(vol, volUnit) * unitToBase(conc, concUnit)
  result = result * molWeight
  result = baseToUnit(result, resultUnit)

proc calcConc*(weight: float; weightUnit: WeightUnits;
              vol: float; volUnit: VolumeUnits;
              molWeight: float; resultUnit: ConcUnits): float =
  result = unitToBase(weight, weightUnit) / molWeight
  result = result / unitToBase(vol, volUnit)
  result = baseToUnit(result, resultUnit)

proc calcMolwt*(weight: float; weightUnit: WeightUnits;
                vol: float; volUnit: VolumeUnits;
                conc: float; concUnit: ConcUnits): float =
  result = unitToBase(weight, weightUnit) / (unitToBase(vol, volUnit) * unitToBase(conc, concUnit))

proc calc_IC50*(pic50: float; concUnit: ConcUnits): float =
  ## concUnit is the unit of the result value
  result = baseToUnit(pow(10.0, -pic50), concUnit)

proc calc_pIC50*(ic50: float; concUnit: ConcUnits): float =
  result = -log10(unitToBase(ic50, concUnit))


when isMainModule:
  # Some tests
  assert unitToBase(1000, mM) == baseToUnit(1, M)
  assert calcVol(5, mg, 10, mM, 500, mL) == 1.0
  assert calcWeight(1, mL, 10, mM, 500, mg) == 5.0
  assert calcWeight(1, mL, 100, mM, 500, mg) == 50.0
  assert calcConc(5, mg, 1, mL, 500, mM) == 10.0
  assert calc_IC50(7.0, nM) == 100.0
  assert calc_IC50(6, uM) == 1.0
  assert calc_pIC50(100, nM) == 7.0
