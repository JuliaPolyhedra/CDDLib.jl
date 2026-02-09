using Test
using Polyhedra
using CDDLib

# Generate test functions that test incident* functions
plural(x) = Symbol(x, "s")
idx(x) = Symbol(x, "idx")
inc(x) = Symbol("incident", plural(x))
incidx(x) = Symbol("incident", x, "indices")

v_kinds = (:point, :line, :ray)
h_kinds = (:hyperplane, :halfspace)

vars = Dict(
    :hyperplane => :hp,
    :halfspace  => :hs,
    :point      => :pt,
    :line       => :ln,
    :ray        => :ry,
)

patterns = [
    # {hyperplane, halfspace} -> {point, line, ray}
    [(plural(s), idx(vars[s]), vars[s], plural(t), inc(t), incidx(t))
     for s in h_kinds for t in v_kinds]...,
    # {point, line, ray} -> {hyperplane, halfspace}
    [(plural(s), idx(vars[s]), vars[s], plural(t), inc(t), incidx(t))
     for s in v_kinds for t in h_kinds]...
]  # 12 patterns

# Code generation
for (src_plural, src_idx, src_var, tgt_plural, inc_fun, incidx_fun) in patterns
    fname = Symbol("test_", src_plural, "_", inc_fun)

    @eval function $(fname)(p::CDDLib.Polyhedron)
        T = Polyhedra.coefficient_type(p)
        tol = Polyhedra._default_tol(T)

        srcs = $(src_plural)(p)
        for ($(src_idx), $(src_var)) in zip(eachindex(srcs), srcs)
            inc_elems = @inferred $(inc_fun)(p, $(src_idx))
            inc_inds  = @inferred $(incidx_fun)(p, $(src_idx))

            for elems in (inc_elems, get.(p, inc_inds))
                for el in elems
                    @test Polyhedra.isincident(el, $(src_var), tol=tol)
                end
            end

            # Test against the generic versions in Polyhedra.jl
            @test inc_elems == $(inc_fun)(p, $(src_idx), tol=tol)
            @test inc_inds  == $(incidx_fun)(p, $(src_idx), tol=tol)
        end
        return nothing
    end
end


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

    @testset "incident* functions $precision" for precision in [:float, :exact]
        lib = CDDLib.Library(precision)

        # Case 1: points + lines
        A1 = [-1 0; 1 0]
        b1 = [0, 1]
        p1 = polyhedron(hrep(A1, b1), lib)
        vrep(p1)

        # Case 2: points + rays + lines + halfspaces + hyperplanes
        # P = { (x,y,z,w) | -1 <= x <= 1, y >= 0, z == 0, w free }.
        A2 = [
             1  0  0  0;   # x <= 1
            -1  0  0  0;   # -x <= 1  (x >= -1)
             0 -1  0  0;   # -y <= 0  (y >= 0)
             0  0  1  0;   # z <= 0, marked as equality -> z == 0
        ]
        b2 = [1, 1, 0, 0]
        linset2 = BitSet([4])
        p2 = polyhedron(hrep(A2, b2, linset2), lib)
        vrep(p2)

        # Case 3: bounded triangle (points + halfspaces)
        p3 = polyhedron(hrep([1 1; 1 -1; -1 0], [1, 0, 0]), lib)
        vrep(p3)

        # Case 4: homogeneous cone from rays (V-input; exercises the cone branch)
        p4 = polyhedron(conichull([1, 0], [0, 1]), lib)
        hrep(p4)

        # Case 5: non-homogeneous cone / translated orthant (point + rays)
        # P = { (x, y) | x >= 1, y >= 1 }.
        p5 = polyhedron(hrep([-1 0; 0 -1], [-1, -1]), lib)
        vrep(p5)

        # Case 6: empty / infeasible (H-side elements only)
        # x == 0, x == 1, y >= 0.
        p_empty = polyhedron(hrep([1 0; 1 0; 0 -1], [0, 1, 0], BitSet([1, 2])), lib)
        vrep(p_empty)

        # Case 7: whole space, represented by line directions (no constraints)
        p_full = polyhedron(vrep([Line([1, 0]), Line([0, 1])]), lib)
        hrep(p_full)

        ps = (p1, p2, p3, p4, p5, p_empty, p_full)

        for (src_plural, src_idx, src_var, tgt_plural, inc_fun, incidx_fun) in patterns
            fname = Symbol("test_", src_plural, "_", inc_fun)
            @testset "$(src_plural) -> $(tgt_plural)" begin
                for p in ps
                    getfield(@__MODULE__, fname)(p)
                end
            end
        end
    end
end
