using Test
using Polyhedra
using CDDLib

@testset "Polyhedral Function #38" begin
    pf = HalfSpace([-0.0, -0.0, -1.0], 0.0) ∩ HalfSpace([-0.0, -0.0, -1.0], 0.0) ∩ HalfSpace([-2.88822, -2.88814, -1.0], -0.5201649970233834) ∩ HalfSpace([-3.82659e-8, -2.21789e-8, -1.0], 3.175592530991495e-7) ∩ HalfSpace([0.000233009, 0.000201829, -1.0], 0.0014080138136517413) ∩ HalfSpace([0.000305723, 0.000298892, -1.0], 0.0013853823633649016) ∩ HalfSpace([0.000452778, 0.000564088, -1.0], 0.0023422004969333083) ∩ HalfSpace([-0.0, -0.0, -0.0], 1.0) ∩ HalfSpace([-2.0, -1.0, -0.0], 1.0) ∩ HalfSpace([-2.0, -2.0, -0.0], 1.0) ∩ HalfSpace([2.0, 1.0, -0.0], 6.7) ∩ HalfSpace([-0.0, -0.0, -0.0], 1.0) ∩ HalfSpace([-0.0, -1.0, -0.0], 5.0) ∩ HalfSpace([1.0, 1.0, -0.0], 2.85) ∩ HalfSpace([-0.0, 1.0, -0.0], 4.0) ∩ HalfSpace([-0.0, -0.0, -0.0], 1.0) ∩ HalfSpace([-1.0, -0.0, -0.0], 0.5) ∩ HalfSpace([1.0, -0.0, -0.0], 0.5) ∩ HalfSpace([-0.0, -1.0, -0.0], -0.5) ∩ HalfSpace([-0.0, 1.0, -0.0], 2.0)
    p = polyhedron(pf, CDDLib.Library())
    @test npoints(p) == 6
    @test nrays(p) == 1
    @test nlines(p) == 0
end
