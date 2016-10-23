facts("Low-level permutahedron tests") do
    A = [1 1 1; 1 0 0; 0 1 0; 0 0 1; -1 0 0; 0 -1 0; 0 0 -1]
    b = [6, 3, 3, 3, -1, -1, -1]
    ls = IntSet([1])
    V = [2 3 1; 1 3 2; 3 1 2; 3 2 1; 2 1 3; 1 2 3]
    ine = SimpleHRepresentation(A, b, ls)
    #@fact isempty(ine) --> false
    inef = SimpleHRepresentation(Array{Float64}(A), Array{Float64}(b), ls)
    #@fact isempty(inef) --> false
    poly = CDDPolyhedra(ine)
    polyf = CDDPolyhedra(inef)
    ineoutm  = copyinequalities(poly)
    ineoutmf = copyinequalities(polyf)
    extm     = copygenerators(poly)
    extmf    = copygenerators(polyf)
    @fact string(ineoutm) --> "H-representation
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
    @fact string(ineoutmf) --> "H-representation
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
    @fact string(extm) --> "V-representation
begin
 6 4 rational
 1//1 2//1 3//1 1//1
 1//1 1//1 3//1 2//1
 1//1 3//1 1//1 2//1
 1//1 3//1 2//1 1//1
 1//1 2//1 1//1 3//1
 1//1 1//1 2//1 3//1
end"
    @fact string(extmf) --> "V-representation
begin
 6 4 real
 1.0 2.0 3.0 0.9999999999999998
 1.0 0.9999999999999997 3.0 2.0
 1.0 3.0000000000000004 1.0 1.9999999999999993
 1.0 3.0 2.0 0.9999999999999997
 1.0 1.9999999999999991 1.0 2.9999999999999996
 1.0 0.9999999999999996 2.0 3.0
end"
    ineout  = SimpleHRepresentation{3, Int}(ineoutm)
    ineoutf = SimpleHRepresentation{3, Int}(ineoutmf)
    ext     = SimpleVRepresentation{3, Int}(extm)
    extf    = SimpleVRepresentation{3, Int}(round(extmf))
    inequality_simpletest(ineout, A, b, ls)
    inequality_simpletest(ineoutf, A, b, ls)
    generator_simpletest(ext, V, Array(Int, 0, 3))
    generator_simpletest(extf, V, Array(Int, 0, 3))


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
    linsetlift = IntSet()
    inelift3 = SimpleHRepresentation(Alift, blift, linsetlift)
    inelift3f = SimpleHRepresentation{6, Float64}(inelift3)
    inelift2 = fourierelimination(inelift3)
    inelift2f = fourierelimination(inelift3f)
    inelift1 = blockelimination(inelift2)
    inelift1f = blockelimination(inelift2f)
    inelift0 = blockelimination(inelift1, IntSet([fulldim(inelift1)]))
    inelift0f = blockelimination(inelift1f, IntSet([fulldim(inelift1f)]))
    canonicalize!(inelift0)
    canonicalize!(inelift0f)
    inelift0d = SimpleHRepresentation{3,Int}(inelift0)
    inelift0df = SimpleHRepresentation{3,Int}(inelift0f)
    @fact inelift0d.linset --> IntSet(1)
    @fact length(inelift0d.b) --> 7
    @fact inelift0d.b[1] / sign(inelift0d.b[1]) --> 6
    @fact vec(Array{Int}(inelift0d.A[1,:] / sign(inelift0d.b[1]))) --> [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
    @fact inelift0df.linset --> IntSet(1)
    @fact length(inelift0df.b) --> 7
    @fact inelift0df.b[1] / sign(inelift0df.b[1]) --> 6
    @fact vec(Array{Int}(inelift0df.A[1,:] / sign(inelift0df.b[1]))) --> [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
    polylift = CDDPolyhedra(inelift0)
    polyliftf = CDDPolyhedra(inelift0f)
    extunlift = SimpleVRepresentation{3,Int}(copygenerators(polylift))
    extunliftf = SimpleVRepresentation{3,Int}(round(copygenerators(polyliftf)))
    # This does inexact error: WTF why ???
    #extunlift = Representation{3,Int}(copygenerators(polylift))
    #extunliftf = Representation{3,Int}(copygenerators(polyliftf))
    generator_simpletest(extunlift, V, Array(Int, 0, 3))
    generator_simpletest(extunliftf, V, Array(Int, 0, 3))
end
