function Hello()
    println("Hello, Ferromodo!")
end
#####################################
# Assign unique IDs to **all faces** in the mesh
function assign_face_ids(faces::Vector{GeometryBasics.QuadFace{Int64}})
    # Create a dictionary mapping each QuadFace to a unique ID
    face_ids = Dict(face => idx for (idx, face) in enumerate(faces))
    return face_ids
end
#####################################
# Function to retrieve face IDs for a set of boundary faces
function get_face_ids(face_ids::Dict{GeometryBasics.QuadFace{Int64},Int}, query_faces::Vector{GeometryBasics.QuadFace{Int64}})
    # Return IDs of queried faces or `nothing` if not found
    return [get(face_ids, query_face, nothing) for query_face in query_faces]
end
# Function to create OrderedSet of FacetIndex from face IDs and local facet ID
function create_facetindex_set(face_ids::Vector{Int}, local_facet_id::Int)
    return OrderedSet{FacetIndex}([FacetIndex((id, local_facet_id)) for id in face_ids])
end

#####################################
function cogrid(type::String, E, V, F, Fb, CFb_type)

    if type == "Hex8"
        # # Create nodes and cells
        nodes = map(v -> Ferrite.Node((v[1], v[2], v[3])), V)
        cells = [Ferrite.Hexahedron((e[1], e[2], e[3], e[4], e[5], e[6], e[7], e[8])) for e in E]
        # Categorize face IDs based on CFb_type
        face_ids_top = get_face_ids(face_ids, Fb[CFb_type.==1])
        face_ids_bottom = get_face_ids(face_ids, Fb[CFb_type.==2])
        face_ids_right = get_face_ids(face_ids, Fb[CFb_type.==6])
        face_ids_left = get_face_ids(face_ids, Fb[CFb_type.==3])
        face_ids_front = get_face_ids(face_ids, Fb[CFb_type.==4])
        face_ids_back = get_face_ids(face_ids, Fb[CFb_type.==5])

        # Initialize facetsets dictionary with FacetIndex
        facetsets = Dict{String,OrderedSet{FacetIndex}}()
        facetsets["top"] = create_facetindex_set(face_ids_top, 6)
        facetsets["bottom"] = create_facetindex_set(face_ids_bottom, 2)
        facetsets["right"] = create_facetindex_set(face_ids_right, 5)
        facetsets["left"] = create_facetindex_set(face_ids_left, 3)
        facetsets["front"] = create_facetindex_set(face_ids_front, 4)
        facetsets["back"] = create_facetindex_set(face_ids_back, 1)
    else
        println("Invalid type")
    end

    return Ferrite.Grid(cells, nodes, facetsets=facetsets)
end