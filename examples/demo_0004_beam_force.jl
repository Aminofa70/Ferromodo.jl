using Revise
using Comodo # https://github.com/COMODO-research/Comodo.jl
using Ferrite
using Ferromodo
using PUPM

par = DynamicParams()  # Create a dynamic parameter object
###### 
# Control parameters 
pointSpacing = 3.0

###### 
# Creating a hexahedral mesh for a cube 
boxDim = [10.0,40.0,10.0] # Dimensionsions for the box in each direction
boxEl = ceil.(Int64,boxDim./pointSpacing) # Number of elements to use in each direction 
E,V,F,Fb,CFb_type = hexbox(boxDim,boxEl)

grid = cogrid(hex8 , E, V, F, Fb, CFb_type)
addnodeset!(grid, "indNodesFront", x -> x[2] ≈ 0.0)

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

function create_bc(dh, grid)
    ch = Ferrite.ConstraintHandler(dh)

    dbc = Dirichlet(:u, getfacetset(grid, "back"), (x, t) -> [0.0, 0.0, 0.0], [1,2,3]) # bcSupportList
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

appliedForce = [0.0, 0.0, -2e-3]
par.loads = [LoadCondition_3d("nodal_load",appliedForce )]

par.Neumann_bc = "indNodesFront"

dh = par.dh

res = fem_solver_3d(par)

DD = res.u;

VTKGridFile("my_solution", grid) do vtk
    write_solution(vtk, dh, DD)
end;