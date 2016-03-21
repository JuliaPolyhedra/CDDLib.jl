A = [1 1 1; 1 0 0; 0 1 0; 0 0 1; -1 0 0; 0 -1 0; 0 0 -1]
b = [6, 3, 3, 3, -1, -1, -1]
linset = IntSet([1])
V = [2 3 1; 1 3 2; 3 1 2; 3 2 1; 2 1 3; 1 2 3]
ine = Polyhedra.HRepresentation(A, b, linset)
#@test !isempty(ine)
inef = Polyhedra.HRepresentation(Array{Float64}(A), Array{Float64}(b), linset)
#@test !isempty(inef)
poly = CDDPolyhedra(ine)
polyf = CDDPolyhedra(inef)
ineoutm  = copyinequalities(poly)
ineoutmf = copyinequalities(polyf)
extm     = copygenerators(poly)
extmf    = copygenerators(polyf)
@test string(ineoutm) == "H-representation
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
@test string(ineoutmf) == "H-representation
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
@test string(extm) == "V-representation
begin
 6 4 rational
 1//1 2//1 3//1 1//1
 1//1 1//1 3//1 2//1
 1//1 3//1 1//1 2//1
 1//1 3//1 2//1 1//1
 1//1 2//1 1//1 3//1
 1//1 1//1 2//1 3//1
end"
@test string(extmf) == "V-representation
begin
 6 4 real
 1.0 2.0 3.0 0.9999999999999998
 1.0 0.9999999999999997 3.0 2.0
 1.0 3.0000000000000004 1.0 1.9999999999999993
 1.0 3.0 2.0 0.9999999999999997
 1.0 1.9999999999999991 1.0 2.9999999999999996
 1.0 0.9999999999999996 2.0 3.0
end"
ineout  = Polyhedra.Representation{Int}(ineoutm)
ineoutf = Polyhedra.Representation{Int}(ineoutmf)
ext     = Polyhedra.Representation{Int}(extm)
extf    = Polyhedra.Representation{Int}(round(Polyhedra.Representation{Float64}(extmf)))
inequality_simpletest(ineout, A, b, linset)
inequality_simpletest(ineoutf, A, b, linset)
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
linsetlift = IntSet([])
inelift3 = Polyhedra.HRepresentation(Alift, blift, linsetlift)
inelift3f = Polyhedra.Representation{Float64}(Polyhedra.HRepresentation(Alift, blift, linsetlift))
inelift2 = fourierelimination(inelift3)
inelift2f = fourierelimination(inelift3f)
inelift1 = blockelimination(inelift2)
inelift1f = blockelimination(inelift2f)
inelift0 = blockelimination(inelift1, IntSet([size(inelift1, 2)-1]))
inelift0f = blockelimination(inelift1f, IntSet([size(inelift1f, 2)-1]))
canonicalize!(inelift0)
canonicalize!(inelift0f)
inelift0d = Polyhedra.HRepresentation{Int}(Polyhedra.Representation(inelift0))
inelift0df = Polyhedra.HRepresentation{Int}(Polyhedra.Representation(inelift0f))
@test inelift0d.linset == IntSet([1])
@test length(inelift0d.b) == 7
@test inelift0d.b[1] / sign(inelift0d.b[1]) == 6
@test vec(Array{Int}(inelift0d.A[1,:] / sign(inelift0d.b[1]))) == [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
@test inelift0df.linset == IntSet([1])
@test length(inelift0df.b) == 7
@test inelift0df.b[1] / sign(inelift0df.b[1]) == 6
@test vec(Array{Int}(inelift0df.A[1,:] / sign(inelift0df.b[1]))) == [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
polylift = CDDPolyhedra(inelift0)
polyliftf = CDDPolyhedra(inelift0f)
extunlift = Polyhedra.VRepresentation{Int}(Polyhedra.Representation(copygenerators(polylift)))
extunliftf = Polyhedra.VRepresentation{Int}(round(Polyhedra.Representation(copygenerators(polyliftf))))
generator_simpletest(extunlift, V, Array(Int, 0, 3))
generator_simpletest(extunliftf, V, Array(Int, 0, 3))
