const polyhedra_test = joinpath(Pkg.dir("Polyhedra"), "test")

include(joinpath(polyhedra_test, "alltests.jl"))
@testset "Polyhedra tests" for arith in [:float, :exact]
    runtests(CDDLibrary(arith))
end
