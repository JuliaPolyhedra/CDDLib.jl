using CDD
using Base.Test

A = [1 1 1; 1 0 0; 0 1 0; 0 0 1; -1 0 0; 0 -1 0; 0 0 -1]
b = [6, 3, 3, 3, -1, -1, -1]
linset = IntSet([1])
V = [2 3 1; 1 3 2; 3 1 2; 3 2 1; 2 1 3; 1 2 3]
ine = InequalityDescription(A, b, linset)
@test !isempty(ine)
inef = InequalityDescription(Array{Float64}(A), Array{Float64}(b), linset)
@test !isempty(inef)
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
ineout  = Description{Int}(ineoutm)
ineoutf = Description{Int}(ineoutmf)
ext     = Description{Int}(extm)
extf    = Description{Int}(round(Description{Float64}(extmf)))
inequality_fulltest(ineout, A, b, linset)
inequality_fulltest(ineoutf, A, b, linset)
generator_fulltest(ext, V, Array(Int, 0, 3))
generator_fulltest(extf, V, Array(Int, 0, 3))


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
inelift3 = InequalityDescription(Alift, blift, linsetlift)
inelift2 = fourierelimination(inelift3)
inelift1 = fourierelimination(inelift2)
inelift0 = fourierelimination(inelift1)
canonicalize!(inelift0)
inelift0d = InequalityDescription{Int}(Description(inelift0))
@test inelift0d.linset == IntSet([1])
@test length(inelift0d.b) == 7
@test inelift0d.b[1] / sign(inelift0d.b[1]) == 6
@test vec(Array{Int}(inelift0d.A[1,:] / sign(inelift0d.b[1]))) == [1; 1; 1] # Array{Int} cast and vec are for julia 0.4
polylift = CDDPolyhedra(inelift0)
extunlift = GeneratorDescription{Int}(Description(copygenerators(polylift)))
generator_fulltest(extunlift, V, Array(Int, 0, 3))
