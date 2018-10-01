using CDDLib
using Polyhedra
using Test

using JuMP
lpsolver = tuple()

include("utils.jl")
include("simplex.jl")
include("permutahedron.jl")
include("board.jl")
include("mathprogbase.jl")
include("polyhedron.jl")
