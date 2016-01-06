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
ineout  = Description{Int}(copyinequalities(poly))
ineoutf = Description{Int}(copyinequalities(polyf))
ext     = Description{Int}(  copygenerators(poly))
extf    = Description{Int}(round(Description{Float64}(copygenerators(polyf))))
@test A == ineout.A
@test b == ineout.b
@test A == ineoutf.A
@test b == ineoutf.b
@test V == ext.V
@test V == extf.V
