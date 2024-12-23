using Revise
using GLMakie
using GeometryBasics
using Ferrite
using Comodo
using OrderedCollections
using PUPM

#=
Finite Element programming for 2D plane stress 
Plate under tension
Reference:
https://shop.elsevier.com/books/practical-programming-of-finite-element-procedures-for-solids-and-structures-with-matlab/farahmand-tabar/978-0-443-15338-9

=#

par = DynamicParams()
plateDim1 = [1.0,1.0]
plateElem1 = [4,4]
orientation1 = :up
## Warning the origin is zero

F1,V1 = quadplate(plateDim1,plateElem1; orientation=orientation1)
# Adjust coordinates to start from (0, 0)
min_x = minimum([v[1] for v in V1])  # Find minimum x-coordinate
min_y = minimum([v[2] for v in V1])  # Find minimum y-coordinate
V1 = [(v[1] - min_x, v[2] - min_y) for v in V1]

grid = cogrid(quad4plate, F1, V1)
addnodeset!(grid, "support_1", x -> x[1] ≈ 0.0)  # left side; Dirichlet BC
addnodeset!(grid, "support_2", x -> x[2] ≈ 0.0)  # bottom side; Dirichlet BC
# Function to create CellValues and FacetValues
function create_values()
    dim, order = 2, 1
    ip = Ferrite.Lagrange{Ferrite.RefQuadrilateral, order}()^dim
    qr = Ferrite.QuadratureRule{Ferrite.RefQuadrilateral}(2)
    qr_face = Ferrite.FacetQuadratureRule{Ferrite.RefQuadrilateral}(1)
    cell_values = Ferrite.CellValues(qr, ip)
    facet_values = Ferrite.FacetValues(qr_face, ip)
    return cell_values, facet_values
end

# Function to create DofHandler
function create_dofhandler(grid)
    dh = Ferrite.DofHandler(grid)
    Ferrite.add!(dh, :u, Ferrite.Lagrange{Ferrite.RefQuadrilateral, 1}()^2)
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
par.Neumann_bc = Ferrite.getfacetset(dh.grid, "right")
par.grid = grid

# Solve the FEM problem using OptiUPM
result = fem_solver(par)

u = result.u

display(maximum(u)) ## 0.04761904761904768
display(minimum(u)) ## -0.04761904761904768