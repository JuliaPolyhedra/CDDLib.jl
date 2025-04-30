using Test
using Polyhedra
using CDDLib

@testset "Adjacency $precision" for precision in [:float, :exact]
    vsquare = vrep([[i, j] for i in [-1, 1] for j in [-1, 1]])
    p = polyhedron(vsquare, CDDLib.Library(precision))
    @test p isa CDDLib.Polyhedron{precision == :float ? Float64 : Rational{BigInt}}
    @test matrix2adjacency(p.ext) == [
        BitSet([2, 3])
        BitSet([1, 4])
        BitSet([1, 4])
        BitSet([2, 3])
    ]
end
