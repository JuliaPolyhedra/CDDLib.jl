function inequality_fulltest(ine, A, b, linset)
  @test A == ine.A
  @test b == ine.b
  @test linset == ine.linset
end
function generator_fulltest(ext, V, vertex)
  @test V == ext.V
  @test vertex == ext.vertex
end


A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]
vertex = IntSet([1,2])

@test_throws ErrorException InequalityDescription(A, [0, 0], linset)
@test_throws ErrorException InequalityDescription(A, [0, 0], IntSet([4]))
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
inequality_fulltest(ineout1, A, b, linset)
inequality_fulltest(ineout1f, A, b, linset)
generator_fulltest(extout1, V, vertex)
generator_fulltest(extout1f, V, vertex)

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
linsetalt = IntSet([3])
@test_throws ErrorException GeneratorDescription(V, [1 0 0], vertex, IntSet([]), IntSet([]))
@test_throws ErrorException GeneratorDescription(V, [1 1], vertex, IntSet([]), IntSet([2]))
@test_throws ErrorException GeneratorDescription(V, [1 1], vertex, IntSet([4]), IntSet([]))
@test_throws ErrorException GeneratorDescription(V, IntSet([4]))
ext = GeneratorDescription(V, vertex)
extf = GeneratorDescription(Array{Float64}(V), vertex)
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = Description{Int}(copyinequalities(poly2 ))
ineout2f = Description{Int}(copyinequalities(poly2f))
extout2  = Description{Int}(  copygenerators(poly2 ))
extout2f = Description{Int}(  copygenerators(poly2f))
inequality_fulltest(ineout2, Aalt, balt, linsetalt)
inequality_fulltest(ineout2f, Aalt, balt, linsetalt)
generator_fulltest(extout2, V, vertex)
generator_fulltest(extout2f, V, vertex)

# x_1 cannot be 2
@test isempty(InequalityDescription([A; 1 0], [b; 2], union(linset, IntSet([4]))))

V0 = [0 0]
vertex0 = IntSet([1])
ext0 = GeneratorDescription(V0, vertex0)
ext0f = GeneratorDescription(Array{Float64}(V0), vertex0)
push!(poly1, ext0)
push!(poly1f, ext0f)
push!(poly2, ext0)
push!(poly2f, ext0)
ineout3  = Description{Int}(copyinequalities(poly1 ))
ineout3f = Description{Int}(copyinequalities(poly1f))
extout3  = Description{Int}(  copygenerators(poly1 ))
extout3f = Description{Int}(  copygenerators(poly1f))
ineout4  = Description{Int}(copyinequalities(poly2 ))
ineout4f = Description{Int}(copyinequalities(poly2f))
extout4  = Description{Int}(  copygenerators(poly2 ))
extout4f = Description{Int}(  copygenerators(poly2f))
Vfull = [V;V0]
vertexfull = union(vertex, IntSet([3]))
linsetfull = IntSet([])
inequality_fulltest(ineout3, A, b, linsetfull)
inequality_fulltest(ineout3f, A, b, linsetfull)
generator_fulltest(extout3, Vfull, vertexfull)
generator_fulltest(extout3f, Vfull, vertexfull)
inequality_fulltest(ineout4, A, b, linsetfull)
inequality_fulltest(ineout4f, A, b, linsetfull)
generator_fulltest(extout4, Vfull, vertexfull)
generator_fulltest(extout4f, Vfull, vertexfull)
