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
grid = cogrid(hex8 , E, V, F, Fb, CFb_type)

# Function to create cell and facet values
function create_values()
    order = 1
    dim = 3
    ip = Lagrange{RefHexahedron,order}()^dim
    qr = QuadratureRule{RefHexahedron}(2)
    qr_face = FacetQuadratureRule{RefHexahedron}(1)
    cell_values = CellValues(qr, ip)
    facet_values = FacetValues(qr_face, ip)
    return cell_values, facet_values
end

# Function to create a DOF handler
function create_dofhandler(grid)
    dh = Ferrite.DofHandler(grid)
    Ferrite.add!(dh, :u, Ferrite.Lagrange{Ferrite.RefHexahedron,1}()^3)
    Ferrite.close!(dh)
    return dh
end

# Function to create boundary conditions
function create_bc(dh, grid)
    ch = Ferrite.ConstraintHandler(dh)
    # dbc = Dirichlet(:u, getfacetset(grid, "my_top"), (x, t) -> [0.0, 0.0, 0.0], [1,2,3])
    dbc = Dirichlet(:u, getfacetset(grid, "back"), (x, t) -> [0.0, 0.0, 0.0], [1,2,3])
    add!(ch, dbc)
    Ferrite.close!(ch)
    return ch
end
grid = grid
dh = create_dofhandler(grid)
ch = create_bc(dh, grid)
# VTKGridFile("boundary-conditions", dh) do vtk
#     Ferrite.write_constraints(vtk,ch)
# end