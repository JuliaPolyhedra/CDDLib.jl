A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]
ine = InequalityDescription(A, b, linset)
@test !isempty(ine)
inef = InequalityDescription(Array{Float64}(A), Array{Float64}(b), linset)
@test !isempty(inef)
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

# x_1 cannot be 2
@test isempty(InequalityDescription([A; 1 0], [b; 2], union(linset, IntSet([4]))))
