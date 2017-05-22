const polyhedra_test = joinpath(Pkg.dir("Polyhedra"), "test")

include(joinpath(polyhedra_test, "alltests.jl"))
@testset "Polyhedra tests with $arith arithmetic" for arith in [:float, :exact]
    basicpolyhedrontests(CDDLibrary(arith))
    runtests(CDDLibrary(arith))
end
