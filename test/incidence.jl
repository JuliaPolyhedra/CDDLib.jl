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
        hrep(p)
        hs = collect(halfspaces(p))

        incidence_computed = copyinputincidence(p.poly)
        for (vidx, v) in enumerate(points(p))
            for i in incidence_computed[vidx]
                @test Polyhedra.isincident(v, hs[i], tol=0)
            end
        end
    end

    @testset "get[hv]incidence $precision" for precision in [:float, :exact]
        A = [1 1; 1 -1; -1 0]; b = [1, 0, 0]
        p_H = polyhedron(hrep(A, b), CDDLib.Library(precision))
        vrep(p_H)

        V = [[1//2, 1//2], [0, 1], [0, 0]]
        p_V = polyhedron(vrep(V), CDDLib.Library(precision))
        hrep(p_V)

        # Homogeneous cone
        A = [-1 0; 0 -1]; b0 = [0, 0]
        p_hc = polyhedron(hrep(A, b0), CDDLib.Library(precision))

        # Non-homogeneous cone
        A = [-1 0; 0 -1]; b1 = [-1, -1]
        p_nhc = polyhedron(hrep(A, b1), CDDLib.Library(precision))

        for p in [p_H, p_V, p_hc, p_nhc]
            @inferred CDDLib.gethincidence(p)
            @inferred CDDLib.getvincidence(p)

            hs = collect(halfspaces(p))
            vs = [collect(rays(p))..., collect(points(p))...]

            T = Polyhedra.coefficient_type(p)
            tol = Polyhedra._default_tol(T)

            for (vidx, v) in enumerate(vs)
                for i in p.hincidence[vidx]
                    @test Polyhedra.isincident(v, hs[i], tol=tol)
                end
            end

            for (hidx, h) in enumerate(hs)
                for i in p.vincidence[hidx]
                    @test Polyhedra.isincident(vs[i], h, tol=tol)
                end
            end
        end
    end
end
