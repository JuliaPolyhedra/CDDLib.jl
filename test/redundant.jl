using Test
using Polyhedra
using CDDLib

@testset "Via shooting $(via_shooting)" for via_shooting in [false, true]
    @testset "Redundant test $precision" for precision in [:float, :exact]
        lib = CDDLib.Library(precision)
        V = [3 0; 1 1; 0 3; 0 0]
        p = polyhedron(vrep(V), lib)
        @test collect(CDDLib.getvredundantindices(p; via_shooting)) == [2]

        A = [1 0; 1 1; 0 1; -1 0; 0 -1]
        b = [1, 2, 1, -1, -1]
        p = polyhedron(hrep(A, b), lib)
        @test collect(CDDLib.gethredundantindices(p; via_shooting)) == [1, 3]
    end
end
