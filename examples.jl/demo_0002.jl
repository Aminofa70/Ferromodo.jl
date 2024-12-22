using Revise
using Comodo
using Ferrite
using Ferromodo
using PUPM
using GLMakie
using GeometryBasics

par = DynamicParams()
# Parameters for the box domain and mesh
sampleSize = 10
pointSpacing = 2
boxDim = sampleSize .* [1, 1, 1]  # Dimensions of the box in each direction
boxEl = ceil.(Int, boxDim ./ pointSpacing)  # Number of elements to use in each direction

# Generate the hexahedral mesh using hexbox
E, V, F, Fb, CFb_type = hexbox(boxDim, boxEl)
type = "hex8"
grid = cogrid(type, E, V, F, Fb, CFb_type)
# addnodeset!(grid, "force", x -> x[2] ≈ sampleSize)

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
    dbc = Dirichlet(:u, getfacetset(grid, "top"), (x, t) -> [0.0, 0.0, 0.0], [1,2,3])
    add!(ch, dbc)
    Ferrite.close!(ch)
    return ch
end
par.grid = grid
par.dh = create_dofhandler(grid)
par.ch = create_bc(par.dh, grid)

# par.cell_values, par.facet_values = create_values()
# par.loads = [LoadCondition_3d("nodal_load", [0.0, 0.0, 1e10])]
# # Material properties
# par.E = 210e9
# par.ν = 0.3
# par.Neumann_bc = "force"

# # Solve the FEM problem using OptiUPM
# result = fem_solver_3d(par)

# DD = result.u # displacement
# Reshape DD to match the number of nodes and components (e.g., 216×3)
# DD = reshape(DD, :, 3)
# DD = [vec(DD[i, :]) for i in 1:size(DD, 1)]
# fig = Figure(size=(800,800))
# stepRange = 0:1:length(DD)-1
# hSlider = Slider(fig[2, 1], range = stepRange, startvalue = length(DD)-1,linewidth=30)

# VTKGridFile("linear_elasticity", par.dh) do vtk
#     write_solution(vtk, par.dh, DD) 
# end
VTKGridFile("boundary-conditions", par.dh) do vtk
    Ferrite.write_constraints(vtk,par.ch)
end
getfacetset(grid, "back")