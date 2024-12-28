using Revise
using Comodo # https://github.com/COMODO-research/Comodo.jl
using Ferrite
using Ferromodo
using PUPM

par = DynamicParams()  # Create a dynamic parameter object

###### 
# Control parameters 
sampleSize = 10.0
pointSpacing = 2.0
strainApplied = 0.5 # Equivalent linear strain
loadingOption ="tension" # "tension" or "compression"

###### 
# Creating a hexahedral mesh for a cube 
boxDim = sampleSize.*[1,1,1] # Dimensionsions for the box in each direction
boxEl = ceil.(Int64,boxDim./pointSpacing) # Number of elements to use in each direction 
E,V,F,Fb,CFb_type = hexbox(boxDim,boxEl)

# Defining displacement of the top surface in terms of x, y, and z components
if loadingOption=="tension"
    displacement_prescribed = strainApplied*sampleSize
elseif loadingOption=="compression"
    displacement_prescribed = -strainApplied*sampleSize
end

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

    dbc = Dirichlet(:u, getfacetset(grid, "bottom"), (x, t) -> [0.0], [3]) # bcSupportList_Z
    add!(ch, dbc)
    dbc = Dirichlet(:u, getfacetset(grid, "left"), (x, t) -> [0.0], [1]) # bcSupportList_X
    add!(ch, dbc)
    dbc = Dirichlet(:u, getfacetset(grid, "front"), (x, t) -> [0.0], [2]) # bcSupportList_Y
    add!(ch, dbc)
    dbc = Dirichlet(:u, getfacetset(grid, "top"), (x, t) -> [displacement_prescribed], [3]) # bcPrescribeList
    add!(ch, dbc)
    Ferrite.close!(ch)
    return ch
end

par.grid = grid
par.dh = create_dofhandler(grid)
par.ch = create_bc(par.dh, grid)

par.cell_values, par.facet_values = create_values()
par.E = 210e9
par.ν = 0.3 # Poisson's ratio

dh = par.dh
par.loads = []
par.Neumann_bc = []
res = fem_solver_3d(par)

DD = res.u;

# VTKGridFile("my_solution", grid) do vtk
#     write_solution(vtk, dh, DD)
# end;

