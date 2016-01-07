A = [-1 0; 0 -1; 1 1]
b = [0, 0, 1]
linset = IntSet([3])
V = [0 1; 1 0]
vertex = IntSet([1,2])

ine = InequalityDescription(A, b, linset)
@test !isempty(ine)
inef = InequalityDescription(Array{Float64}(A), Array{Float64}(b), linset)
@test !isempty(inef)
poly1 = CDDPolyhedra(ine)
poly1f = CDDPolyhedra(inef)
ineout1  = Description{Int}(copyinequalities(poly1 ))
ineout1f = Description{Int}(copyinequalities(poly1f))
extout1  = Description{Int}(  copygenerators(poly1 ))
extout1f = Description{Int}(  copygenerators(poly1f))
@test A == ineout1.A
@test b == ineout1.b
@test linset == ineout1.linset
@test A == ineout1f.A
@test b == ineout1f.b
@test linset == ineout1f.linset
@test V == extout1.V
@test vertex == extout1.vertex
@test V == extout1f.V
@test vertex == extout1f.vertex

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
ext = GeneratorDescription(V, vertex)
extf = GeneratorDescription(Array{Float64}(V), vertex)
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = Description{Int}(copyinequalities(poly2 ))
ineout2f = Description{Int}(copyinequalities(poly2f))
extout2  = Description{Int}(  copygenerators(poly2 ))
extout2f = Description{Int}(  copygenerators(poly2f))
@test Aalt == ineout2.A
@test balt == ineout2.b
@test linset == ineout2.linset
@test Aalt == ineout2f.A
@test balt == ineout2f.b
@test linset == ineout2f.linset
@test V == extout2.V
@test vertex == extout2.vertex
@test V == extout2f.V
@test vertex == extout2f.vertex

# x_1 cannot be 2
@test isempty(InequalityDescription([A; 1 0], [b; 2], union(linset, IntSet([4]))))
