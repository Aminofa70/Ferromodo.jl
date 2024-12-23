using Revise
using Comodo
using Ferrite
using Ferromodo
using GeometryBasics
plateDim1 = [20.0,24.0]
plateElem1 = [11,16]
orientation1 = :up
F1,V1 = quadplate(plateDim1,plateElem1; orientation=orientation1)

grid = cogrid(quad4plate, F1,V1)
grid.cells