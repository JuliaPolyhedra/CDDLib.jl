@testset "Low-level simplex tests" begin
    A = [1 1; -1 0; 0 -1]
    b = [1, 0, 0]
    ls = IntSet([1])
    V = [0 1; 1 0]

    ine = hrep(A, b, ls)
    #@test !isempty(ine)
    inef = hrep(Array{Float64}(A), Array{Float64}(b), ls)
    #@test !isempty(inef)
    poly1 = CDDPolyhedra(ine)
    poly1f = CDDPolyhedra(inef)
    ineout1  = MixedMatHRep{2,Int}(copyinequalities(poly1 ))
    ineout1f = MixedMatHRep{2,Int}(copyinequalities(poly1f))
    extout1  = MixedMatVRep{2,Int}(  copygenerators(poly1 ))
    extout1f = MixedMatVRep{2,Int}(  copygenerators(poly1f))
    inequality_simpletest(ineout1, A, b, ls)
    inequality_simpletest(ineout1f, A, b, ls)
    generator_simpletest(extout1, V)
    generator_simpletest(extout1f, V)

    Aalt = [-1 -1; 1 0; -1 0]
    balt = [-1,1,0]
    linsetalt = IntSet([1])
    ext = vrep(V)
    extf = vrep(Array{Float64}(V))
    poly2 = CDDPolyhedra(ext)
    poly2f = CDDPolyhedra(extf)
    ineout2  = MixedMatHRep{2,Int}(copyinequalities(poly2 ))
    ineout2f = MixedMatHRep{2,Int}(copyinequalities(poly2f))
    extout2  = MixedMatVRep{2,Int}(  copygenerators(poly2 ))
    extout2f = MixedMatVRep{2,Int}(  copygenerators(poly2f))
    inequality_simpletest(ineout2, Aalt, balt, linsetalt)
    inequality_simpletest(ineout2f, Aalt, balt, linsetalt)
    generator_simpletest(extout2, V)
    generator_simpletest(extout2f, V)

    # x_1 cannot be 2
    #@test isempty(HRepresentation([A; 1 0], [b; 2], union(linset, IntSet([4]))))

    V0 = [0 0]
    ext0 = vrep(V0)
    ext0f = vrep(Array{Float64}(V0))
    push!(poly1, ext0)
    push!(poly1f, ext0f)
    push!(poly2, ext0)
    push!(poly2f, ext0)
    ineout3  = MixedMatHRep{2,Int}(copyinequalities(poly1 ))
    ineout3f = MixedMatHRep{2,Int}(copyinequalities(poly1f))
    extout3  = MixedMatVRep{2,Int}(  copygenerators(poly1 ))
    extout3f = MixedMatVRep{2,Int}(  copygenerators(poly1f))
    ineout4  = MixedMatHRep{2,Int}(copyinequalities(poly2 ))
    ineout4f = MixedMatHRep{2,Int}(copyinequalities(poly2f))
    extout4  = MixedMatVRep{2,Int}(  copygenerators(poly2 ))
    extout4f = MixedMatVRep{2,Int}(  copygenerators(poly2f))
    Vfull = [V;V0]
    linsetfull = IntSet()
    inequality_simpletest(ineout3, A, b, linsetfull)
    inequality_simpletest(ineout3f, A, b, linsetfull)
    generator_simpletest(extout3, Vfull)
    generator_simpletest(extout3f, Vfull)
    inequality_simpletest(ineout4, A, b, linsetfull)
    inequality_simpletest(ineout4f, A, b, linsetfull)
    generator_simpletest(extout4, Vfull)
    generator_simpletest(extout4f, Vfull)

    Rray = [1 0; 0 1]
    extray = vrep(zeros(Int, 1, 2), Rray)
    extrayf = vrep(zeros(Float64, 1, 2), Array{Float64}(Rray))
    generator_simpletest(extray, zeros(Int, 1, 2), Rray)
    generator_simpletest(extrayf, zeros(Int, 1, 2), Rray)
    polyray = CDDPolyhedra(extray)
    polyrayf = CDDPolyhedra(extrayf)
    Acut = [1 1]
    bcut = [1]
    linsetcut = IntSet([1])
    inecut = hrep(Acut, bcut, linsetcut)
    push!(polyray, inecut)
    push!(polyrayf, inecut)
    ineout5 = MixedMatHRep{2,Int}(copyinequalities(polyray))
    ineout5f = MixedMatHRep{2,Int}(copyinequalities(polyrayf))
    extout5 = MixedMatVRep{2,Int}(copygenerators(polyray))
    extout5f = MixedMatVRep{2,Int}(copygenerators(polyrayf))
    inequality_simpletest(ineout5, [Acut; 0 0; -1 0; 0 -1], [bcut; 1; 0; 0], IntSet([1]))
    inequality_simpletest(ineout5f, [Acut; 0 0; -1 0; 0 -1], [bcut; 1; 0; 0], IntSet([1]))
    generator_simpletest(extout5, V)
    generator_simpletest(extout5f, V)
    generator_simpletest(extout5, V, Array{Int}(0, 2))
    generator_simpletest(extout5f, V, Array{Int}(0, 2))
end
