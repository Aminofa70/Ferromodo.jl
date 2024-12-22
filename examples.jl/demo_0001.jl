using Revise
using Comodo
using Ferrite
using Ferromodo

# Parameters for the box domain and mesh
sampleSize = 10
pointSpacing = 2
boxDim = sampleSize .* [1, 1, 1]  # Dimensions of the box in each direction
boxEl = ceil.(Int, boxDim ./ pointSpacing)  # Number of elements to use in each direction

# Generate the hexahedral mesh using hexbox
E, V, F, Fb, CFb_type = hexbox(boxDim, boxEl)

grid = cogrid(hex8, E, V, F, Fb, CFb_type)