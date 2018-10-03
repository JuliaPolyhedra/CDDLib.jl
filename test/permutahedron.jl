@testset "Low-level permutahedron tests" begin
    A = [1 1 1; 1 0 0; 0 1 0; 0 0 1; -1 0 0; 0 -1 0; 0 0 -1]
    b = [6, 3, 3, 3, -1, -1, -1]
    ls = BitSet([1])
    V = [2 3 1; 1 3 2; 3 1 2; 3 2 1; 2 1 3; 1 2 3]
    ine = hrep(A, b, ls)
    #@test !isempty(ine)
    inef = hrep(Array{Float64}(A), Array{Float64}(b), ls)
    #@test !isempty(inef)
    poly = CDDPolyhedra(ine)
    polyf = CDDPolyhedra(inef)
    ineoutm  = copyinequalities(poly)
    ineoutmf = copyinequalities(polyf)
    extm     = copygenerators(poly)
    extmf    = copygenerators(polyf)
    @test string(unsafe_load(ineoutm.matrix)) == "H-representation
linearity 1 1
begin
 7 4 rational
 6//1 -1//1 -1//1 -1//1
 3//1 -1//1 0//1 0//1
 3//1 0//1 -1//1 0//1
 3//1 0//1 0//1 -1//1
 -1//1 1//1 0//1 0//1
 -1//1 0//1 1//1 0//1
 -1//1 0//1 0//1 1//1
end"
    @test string(unsafe_load(ineoutmf.matrix)) == "H-representation
linearity 1 1
begin
 7 4 real
 6.0 -1.0 -1.0 -1.0
 3.0 -1.0 -0.0 -0.0
 3.0 -0.0 -1.0 -0.0
 3.0 -0.0 -0.0 -1.0
 -1.0 1.0 -0.0 -0.0
 -1.0 -0.0 1.0 -0.0
 -1.0 -0.0 -0.0 1.0
end"
    @test string(unsafe_load(extm.matrix)) == "V-representation
begin
 6 4 rational
 1//1 2//1 3//1 1//1
 1//1 1//1 3//1 2//1
 1//1 3//1 1//1 2//1
 1//1 3//1 2//1 1//1
 1//1 2//1 1//1 3//1
 1//1 1//1 2//1 3//1
end"
    @test string(unsafe_load(extmf.matrix)) == "V-representation
begin
 6 4 real
 1.0 2.0 3.0 0.9999999999999998
 1.0 0.9999999999999997 3.0 2.0
 1.0 3.0000000000000004 1.0 1.9999999999999993
 1.0 3.0 2.0 0.9999999999999997
 1.0 1.9999999999999991 1.0 2.9999999999999996
 1.0 0.9999999999999996 2.0 3.0
end"
    ineout  = MixedMatHRep{Int}(ineoutm)
    ineoutf = MixedMatHRep{Int}(ineoutmf)
    ext     = MixedMatVRep{Int}(extm)
    extf    = MixedMatVRep(extmf)
    inequality_simpletest(ineout, A, b, ls)
    inequality_simpletest(ineoutf, A, b, ls)
    R = Matrix{Int}(undef, 0, 3)
    generator_simpletest(ext, V, R)
    generator_simpletest(extf, V, R)


    # x1___x4____________1
    #      |         |
    #      V         V
    # x2___x5___x6_______2
    #           |
    #           V
    # x3_________________3
    Alift = [-1  0  0  1  0  0;
              0 -1  0  1  0  0;
             -1 -1  0  1  1  0;
              1  1  0 -1 -1  0;
              0  0 -1  0  0  1;
              0  0  0  0 -1  1;
              0  0 -1  0 -1  1;
              0  0  1  0  1 -1;
              0  0  0 -1  0  0;
              0  0  0  0  0 -1;
              0  0  0 -1  0 -1;
              0  0  0  1  0  1]
    blift = [0; 0; 0; 0; 0; 0; -3; 3; -1; -1; -(1+2); (1+2)]
    linsetlift = BitSet()
    inelift3 = hrep(Alift, blift, linsetlift)
    inelift3f = MixedMatHRep{Float64}(inelift3)
    inelift2 = fourierelimination(inelift3)
    inelift2f = fourierelimination(inelift3f)
    inelift1 = blockelimination(inelift2)
    inelift1f = blockelimination(inelift2f)
    inelift0 = blockelimination(inelift1, BitSet([fulldim(inelift1)]))
    inelift0f = blockelimination(inelift1f, BitSet([fulldim(inelift1f)]))
    canonicalize!(inelift0)
    canonicalize!(inelift0f)
    inelift0d = MixedMatHRep{Int}(inelift0)
    inelift0df = MixedMatHRep{Int}(inelift0f)
    @test inelift0d.linset == BitSet(1)
    @test length(inelift0d.b) == 7
    @test inelift0d.b[1] / sign(inelift0d.b[1]) == 6
    @test vec(Array{Int}(inelift0d.A[1,:] / sign(inelift0d.b[1]))) == [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
    @test inelift0df.linset == BitSet(1)
    @test length(inelift0df.b) == 7
    @test inelift0df.b[1] / sign(inelift0df.b[1]) == 6
    @test vec(Array{Int}(inelift0df.A[1,:] / sign(inelift0df.b[1]))) == [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
    polylift = CDDPolyhedra(inelift0)
    polyliftf = CDDPolyhedra(inelift0f)
    extunlift = MixedMatVRep{Int}(copygenerators(polylift))
    extunliftf = MixedMatVRep(copygenerators(polyliftf))
    generator_simpletest(extunlift, V, R)
    generator_simpletest(extunliftf, V, R)
end
