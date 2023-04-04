function _invalid(x)
    err = ErrorException("Invalid coefficient : `$x` is not finite.")
    @test_throws err polyhedron(convexhull([x]), CDDLib.Library())
    @test_throws err polyhedron(intersect(HalfSpace([x], zero(x))), CDDLib.Library())
    @test_throws err polyhedron(intersect(HyperPlane([one(x)], -x)), CDDLib.Library())
end

@testset "Infinite $x" for x in [1 // 0, -2 // 0, NaN, Inf, -Inf]
    _invalid(x)
end
