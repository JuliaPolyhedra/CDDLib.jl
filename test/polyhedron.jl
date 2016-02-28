const polyhedra_test = joinpath(Pkg.dir("Polyhedra"), "test")

include(joinpath(polyhedra_test, "alltests.jl"))
alltests(CDDPolyhedron, :float)
alltests(CDDPolyhedron, :exact)
