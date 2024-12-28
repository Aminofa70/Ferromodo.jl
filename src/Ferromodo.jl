module Ferromodo

using Comodo
using Ferrite
using OrderedCollections
using Statistics
using GeometryBasics
###############################################

export hex8
export quad4plate, tri3plate
export assign_cell_ids
export find_cell_ids_for_faces
export create_facetsets
export create_facetsets_quad4
export find_edge_cells
export cogrid

include("utils.jl")



end
