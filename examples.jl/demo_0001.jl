using Revise
using Comodo
using Ferromodo

# Parameters for the box domain and mesh
sampleSize = 10
pointSpacing = 2
boxDim = sampleSize .* [1, 1, 1]  # Dimensions of the box in each direction
boxEl = ceil.(Int, boxDim ./ pointSpacing)  # Number of elements in each direction

# Generate the hexahedral mesh using hexbox
E, V, F, Fb, CFb_type = hexbox(boxDim, boxEl)

grid = cogrid("Hex8", E, V, F, Fb, CFb_type)