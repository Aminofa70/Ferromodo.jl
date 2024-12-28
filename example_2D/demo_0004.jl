using Revise
using GLMakie
using GeometryBasics
using Ferrite
using Comodo
using PUPM
using Ferromodo
#=
The generated grid lacks the facetsets for the boundaries, so we add them by using Ferrite's addfacetset!.
It allows us to add facetsets to the grid based on coordinates. 
Note that approximate comparison to 0.0 doesn't work well, so we use a tolerance instead.
=#
par = DynamicParams()
plateDim1 = [1.0, 1.0]
pointSpacing1 = 0.01
orientation1 = :up
F1, V1 = Comodo.triplate(plateDim1, pointSpacing1; orientation=orientation1)
grid = cogrid(tri3plate, F1, V1)

# Find extreme coordinates
min_x = minimum([v[1] for v in V1])
max_x = maximum([v[1] for v in V1])
min_y = minimum([v[2] for v in V1])
max_y = maximum([v[2] for v in V1])

# Add node set for the left side (x ≈ min_x)
addnodeset!(grid, "support_1", x -> abs(x[1] - min_x) < 1e-4)

# Add node set for the bottom side (y ≈ min_y)
addnodeset!(grid, "support_2", x -> abs(x[2] - min_y) < 1e-4)

# Add facet set for the right side (x ≈ max_x)
addfacetset!(grid, "pressure", x -> abs(x[1] - max_x) < 1e-4)

# Function to create CellValues and FacetValues
function create_values()
    dim, order = 2, 1
    ip = Ferrite.Lagrange{Ferrite.RefTriangle, order}()^dim
    qr = Ferrite.QuadratureRule{Ferrite.RefTriangle}(2)
    qr_face = Ferrite.FacetQuadratureRule{Ferrite.RefTriangle}(1)
    cell_values = Ferrite.CellValues(qr, ip)
    facet_values = Ferrite.FacetValues(qr_face, ip)
    return cell_values, facet_values
end

# Function to create DofHandler
function create_dofhandler(grid)
    dh = Ferrite.DofHandler(grid)
    Ferrite.add!(dh, :u, Ferrite.Lagrange{Ferrite.RefTriangle, 1}()^2)
    Ferrite.close!(dh)
    return dh
end

# Function to create Dirichlet boundary conditions
# Function to create Dirichlet boundary conditions
function create_bc(dh)
    ch = Ferrite.ConstraintHandler(dh)
    Ferrite.add!(ch, Ferrite.Dirichlet(:u, Ferrite.getnodeset(dh.grid, "support_1"), (x, t) -> [0.0], [1]))
    Ferrite.add!(ch, Ferrite.Dirichlet(:u, Ferrite.getnodeset(dh.grid, "support_2"), (x, t) -> [0.0], [2]))
    Ferrite.close!(ch)
    return ch
end

# Create DOF handler and constraints
par.dh = create_dofhandler(grid)
par.ch = create_bc(par.dh)

# Create CellValues and FacetValues
par.cell_values, par.facet_values = create_values()

# Define loads
pressure_value = 1e10  # Example pressure in Pascals
par.loads = [LoadCondition("pressure_load", pressure_value)]  # Load applied to "pressure" facet

# Material properties
par.E = 210e9  # Young's modulus (Pa)
par.ν = 0.3    # Poisson's ratio

# Neumann BC facet set
dh = par.dh
par.Neumann_bc = Ferrite.getfacetset(dh.grid, "pressure")
par.grid = grid
ch = par.ch

# Solve the FEM problem using OptiUPM
result = fem_solver(par)

u = result.u

display(maximum(u)) ## 0.047619047619055624
display(minimum(u)) ## -0.014227560205036032