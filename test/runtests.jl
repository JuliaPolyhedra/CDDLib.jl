using Test
using Polyhedra
using CDDLib

include("polyhedral_function.jl")

using JuMP
lpsolver = tuple()

include("utils.jl")
include("simplex.jl")
include("permutahedron.jl")
include("board.jl")
include("MOI_wrapper.jl")
include("polyhedron.jl")
