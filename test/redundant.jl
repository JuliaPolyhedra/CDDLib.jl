using Test
using Polyhedra
using CDDLib

@testset "Redundant test $precision" for precision in [:float, :exact]
    lib = CDDLib.Library(precision)
    V = [3 0; 1 1; 0 3; 0 0]
    p = polyhedron(vrep(V), lib)
    @show CDDLib.getvredundantindices(p)

    A = [1 0; 1 1; 0 1; -1 0; 0 -1]
    b = [1, 2, 1, -1, -1]
    p = polyhedron(hrep(A, b, ls), lib)
    @show CDDLib.gethredundantindices(p)
end
