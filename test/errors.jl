function _invalid(x)
    err = ErrorException("Invalid coefficient : `$x` is not finite.")
    @test_throws err polyhedron(convexhull([x]), CDDLib.Library())
    @test_throws err polyhedron(intersect(HalfSpace([x], zero(x))), CDDLib.Library())
    @test_throws err polyhedron(intersect(HyperPlane([one(x)], -x)), CDDLib.Library())
end

@testset "Infinite $x" for x in [1 // 0, -2 // 0, NaN, Inf, -Inf]
    _invalid(x)
end

@testset "myerror" begin
    err = ErrorException("A : Dimension too large")
    @test_throws err CDDLib.myerror("A", CDDLib.Cdd_ErrorType(0))
    err = ErrorException("A gave an error code of 18 which is out of the range of known error code. Pleasre report this by opening an issue at https://github.com/JuliaPolyhedra/CDDLib.jl.")
    @test_throws err CDDLib.myerror("A", CDDLib.Cdd_ErrorType(18))
    err = ErrorException("A gave an error code of -1 which is out of the range of known error code. Pleasre report this by opening an issue at https://github.com/JuliaPolyhedra/CDDLib.jl.")
    @test_throws err CDDLib.myerror("A", CDDLib.Cdd_ErrorType(-1))
end
