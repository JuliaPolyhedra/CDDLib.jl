using Test
using Polyhedra
using CDDLib

@testset "Incidence tests" begin
    @testset "Incidence $precision" for precision in [:float, :exact]
        A = [1 1; 1 -1; -1 0]; b = [1, 0, 0]
        incidence_extected = Set([
            BitSet([1, 2]),
            BitSet([1, 3]),
            BitSet([2, 3])
        ])
        p = polyhedron(hrep(A, b), CDDLib.Library(precision))
        @test p isa CDDLib.Polyhedron{precision == :float ? Float64 : Rational{BigInt}}
        vrep(p)
        @test Set(copyincidence(p.poly)) == incidence_extected
    end

    @testset "Input incidence $precision" for precision in [:float, :exact]
        V = [[1//2, 1//2], [0, 1], [0, 0]]
        p = polyhedron(vrep(V), CDDLib.Library(precision))
        T = Polyhedra.coefficient_type(p)
        hrep(p)
        incidence_computed = copyinputincidence(p.poly)
        for v in eachindex(points(p))
            for i in incidence_computed[v.value]
                h = Polyhedra.Index{T, HalfSpace{T, Vector{T}}}(i)
                @test Polyhedra.isincident(p, v, h; tol=0)
            end
        end
    end
end
