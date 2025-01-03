struct hex8 end
struct quad4plate end
struct tri3plate end
# Function to assign cell IDs to each Hexahedron
function assign_cell_ids(elements::Vector{Ferrite.Hexahedron})
    return OrderedDict(element => idx for (idx, element) in enumerate(elements))
end

# Find cell IDs for specific faces
function find_cell_ids_for_faces(faces::Vector{GeometryBasics.QuadFace{Int}}, cell_ids::OrderedDict{Ferrite.Hexahedron,Int})
    face_to_cell_id = OrderedDict{GeometryBasics.QuadFace{Int},Int}()

    for face in faces
        face_vertices = Set(face)
        for (cell, id) in cell_ids
            if issubset(face_vertices, Set(cell.nodes))
                face_to_cell_id[face] = id
                break
            end
        end
    end

    return face_to_cell_id
end

# Define the function to create facetsets
function create_facetsets(face_ids_by_type::Dict{String,OrderedDict{GeometryBasics.QuadFace{Int64},Int64}})
    # Map face types to their intended facet group IDs
    face_type_to_id = Dict(
        "bottom" => 1,
        "front" => 2,
        "top" => 6,
        "back" => 4,
        "right" => 3,
        "left" => 5
    )

    # Initialize the dictionary for facetsets
    facetsets = Dict{String,OrderedSet{Ferrite.FacetIndex}}()

    # Iterate over each face type
    for (face_type, face_ids) in face_ids_by_type
        # Get the facet group ID for this face type
        facet_group_id = face_type_to_id[face_type]

        # Create an OrderedSet to store FacetIndex for this face type
        facetset = OrderedSet{Ferrite.FacetIndex}()

        # Add each face-cell association as a FacetIndex
        for (face, cell_id) in face_ids
            # Use the cell_id and the fixed facet group ID
            push!(facetset, Ferrite.FacetIndex((cell_id, facet_group_id)))
        end

        # Store the facetset for this face type
        facetsets[face_type] = facetset
    end

    return facetsets
end


function cogrid(::Type{hex8}, E::Vector{Hex8{Int64}}, V::Vector{Point{3,Float64}},
    F::Vector{QuadFace{Int64}}, Fb::Vector{QuadFace{Int64}}, CFb_type::Vector{Int64})
    # Convert elements (E) to Ferrite Hexahedrons

    cells = [Ferrite.Hexahedron((e[1], e[2], e[3], e[4], e[5], e[6], e[7], e[8])) for e in E]

    # Convert vertices (V) to Ferrite Nodes
    nodes = map(v -> Ferrite.Node((v[1], v[2], v[3])), V)
    # Assign cell IDs
    cell_ids = assign_cell_ids(cells)
    # Extract faces based on their types
    Fb_bottom = Fb[CFb_type.==1]  # Bottom face (1)
    Fb_front = Fb[CFb_type.==3]   # Front face (2)
    Fb_top = Fb[CFb_type.==2]     # Top face (6)
    Fb_back = Fb[CFb_type.==4]    # Back face (4)
    Fb_right = Fb[CFb_type.==5]   # Right face (3)
    Fb_left = Fb[CFb_type.==6]    # Left face (5)
    # Find cell IDs for each face type
    bottom_id = find_cell_ids_for_faces(Fb_bottom, cell_ids)
    front_id = find_cell_ids_for_faces(Fb_front, cell_ids)
    top_id = find_cell_ids_for_faces(Fb_top, cell_ids)
    back_id = find_cell_ids_for_faces(Fb_back, cell_ids)
    right_id = find_cell_ids_for_faces(Fb_right, cell_ids)
    left_id = find_cell_ids_for_faces(Fb_left, cell_ids)
    # Group face-cell associations by face type
    face_ids_by_type = Dict(
        "left" => left_id,
        "bottom" => bottom_id,
        "right" => right_id,
        "back" => back_id,
        "top" => top_id,
        "front" => front_id
    )

    # Create the facetsets
    facetsets = create_facetsets(face_ids_by_type)

    return Grid(cells, nodes, facetsets=facetsets)
end

# Helper function to find edge cell IDs


function create_facetsets_quad4(face_ids_by_type)
    facetsets = Dict{String,OrderedSet{Ferrite.FacetIndex}}()
# Map edge types to their facet group IDs
face_type_to_id = Dict(
    "left" => 4,
    "right" => 2,
    "bottom" => 1,
    "top" => 3
)
    for (face_type, face_ids) in face_ids_by_type
        facet_group_id = face_type_to_id[face_type]
        facetset = OrderedSet{Ferrite.FacetIndex}()

        for (key, cell_id) in face_ids
            if key isa Int64 || key isa Ferrite.Quadrilateral
                push!(facetset, Ferrite.FacetIndex((cell_id, facet_group_id)))
            else
                throw(ArgumentError("Unsupported key type: $(typeof(key))"))
            end
        end

        facetsets[face_type] = facetset
    end
    return facetsets
end

# Helper function to find edge cell IDs
function find_edge_cells(edge_nodes, cells)
    edge_cells = []
    for (i, cell) in enumerate(cells)
        # Access the node indices using cell.nodes
        if any(node in edge_nodes for node in cell.nodes)
            push!(edge_cells, i)
        end
    end
    return edge_cells
end

function cogrid(::Type{quad4plate}, F1, V1)
    # Convert to Ferrite-compatible types
    cells = [Ferrite.Quadrilateral((e[1], e[2], e[3], e[4])) for e in F1]
    nodes = Ferrite.Node{2,Float64}[Ferrite.Node((v[1], v[2])) for v in V1]
    # Find extreme x and y coordinates
    min_x = minimum([v[1] for v in V1])
    max_x = maximum([v[1] for v in V1])
    min_y = minimum([v[2] for v in V1])
    max_y = maximum([v[2] for v in V1])
    # Identify nodes on each edge
    left_edge_nodes = Set(findall(v -> isapprox(v[1], min_x; atol=1e-8), V1))
    right_edge_nodes = Set(findall(v -> isapprox(v[1], max_x; atol=1e-8), V1))
    bottom_edge_nodes = Set(findall(v -> isapprox(v[2], min_y; atol=1e-8), V1))
    top_edge_nodes = Set(findall(v -> isapprox(v[2], max_y; atol=1e-8), V1))
    
    # Find cells on each edge
    left_edge_cells = find_edge_cells(left_edge_nodes, cells)
    right_edge_cells = find_edge_cells(right_edge_nodes, cells)
    bottom_edge_cells = find_edge_cells(bottom_edge_nodes, cells)
    top_edge_cells = find_edge_cells(top_edge_nodes, cells)

    

    # Create face_ids_by_type dictionary
    face_ids_by_type = Dict(
        "left" => OrderedDict(cells[i] => i for i in left_edge_cells),
        "right" => OrderedDict(cells[i] => i for i in right_edge_cells),
        "bottom" => OrderedDict(cells[i] => i for i in bottom_edge_cells),
        "top" => OrderedDict(cells[i] => i for i in top_edge_cells)
    )

    
    facetsets = create_facetsets_quad4(face_ids_by_type)
    return Grid(cells, nodes, facetsets=facetsets)
end

function cogrid(::Type{tri3plate}, F1, V1)
    cells = [Ferrite.Triangle((e[1], e[2], e[3])) for e in F1]
    nodes = Ferrite.Node{2,Float64}[Ferrite.Node((v[1], v[2])) for v in V1]
    # The generated grid lacks the facetsets for the boundaries, so we add them by using Ferrite's addfacetset!. 
    return Grid(cells, nodes)
   
end