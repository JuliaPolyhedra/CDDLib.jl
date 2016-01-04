A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]
ine = InequalityDescription(A, b, linset)
inef = InequalityDescription(Array{Float64}(A), Array{Float64}(b), linset)
poly = CDDPolyhedra(ine)
polyf = CDDPolyhedra(inef)
ineout  = Description{Int}(copyinequalities(poly ))
ineoutf = Description{Int}(copyinequalities(polyf))
ext     = Description{Int}(  copygenerators(poly ))
extf    = Description{Int}(  copygenerators(polyf))
@test A == ineout.A
@test b == ineout.b
@test A == ineoutf.A
@test b == ineoutf.b
@test V == ext.V
@test V == extf.V
