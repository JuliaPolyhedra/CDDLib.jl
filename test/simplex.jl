function inequality_fulltest(ine, A, b, linset)
  @test A == ine.A
  @test b == ine.b
  @test linset == ine.linset
end
function generator_fulltest(ext, V, R)
  Polyhedra.splitvertexrays!(ext)
  @test sortrows(V) == sortrows(ext.V)
  @test sortrows(R) == sortrows(ext.R)
end
function generator_fulltest(ext, V, vertex::IntSet)
  @test V == ext.V
  @test vertex == ext.vertex
end


A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]
vertex = IntSet([1,2])

@test_throws ErrorException Polyhedra.InequalityDescription(A, [0, 0], linset)
@test_throws ErrorException Polyhedra.InequalityDescription(A, [0, 0], IntSet([4]))
ine = Polyhedra.InequalityDescription(A, b, linset)
@test !isempty(ine)
inef = Polyhedra.InequalityDescription(Array{Float64}(A), Array{Float64}(b), linset)
@test !isempty(inef)
poly1 = CDDPolyhedra(ine)
poly1f = CDDPolyhedra(inef)
ineout1  = Polyhedra.Description{Int}(copyinequalities(poly1 ))
ineout1f = Polyhedra.Description{Int}(copyinequalities(poly1f))
extout1  = Polyhedra.Description{Int}(  copygenerators(poly1 ))
extout1f = Polyhedra.Description{Int}(  copygenerators(poly1f))
inequality_fulltest(ineout1, A, b, linset)
inequality_fulltest(ineout1f, A, b, linset)
generator_fulltest(extout1, V, vertex)
generator_fulltest(extout1f, V, vertex)

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
linsetalt = IntSet([3])
@test_throws ErrorException Polyhedra.GeneratorDescription(V, [1 0 0], vertex, IntSet([]), IntSet([]))
@test_throws ErrorException Polyhedra.GeneratorDescription(V, [1 1], vertex, IntSet([]), IntSet([2]))
@test_throws ErrorException Polyhedra.GeneratorDescription(V, [1 1], vertex, IntSet([4]), IntSet([]))
@test_throws ErrorException Polyhedra.GeneratorDescription(V, IntSet([4]))
ext = Polyhedra.GeneratorDescription(V, vertex)
extf = Polyhedra.GeneratorDescription(Array{Float64}(V), vertex)
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = Polyhedra.Description{Int}(copyinequalities(poly2 ))
ineout2f = Polyhedra.Description{Int}(copyinequalities(poly2f))
extout2  = Polyhedra.Description{Int}(  copygenerators(poly2 ))
extout2f = Polyhedra.Description{Int}(  copygenerators(poly2f))
inequality_fulltest(ineout2, Aalt, balt, linsetalt)
inequality_fulltest(ineout2f, Aalt, balt, linsetalt)
generator_fulltest(extout2, V, vertex)
generator_fulltest(extout2f, V, vertex)

# x_1 cannot be 2
@test isempty(Polyhedra.InequalityDescription([A; 1 0], [b; 2], union(linset, IntSet([4]))))

V0 = [0 0]
vertex0 = IntSet([1])
ext0 = Polyhedra.GeneratorDescription(V0, vertex0)
ext0f = Polyhedra.GeneratorDescription(Array{Float64}(V0), vertex0)
push!(poly1, ext0)
push!(poly1f, ext0f)
push!(poly2, ext0)
push!(poly2f, ext0)
ineout3  = Polyhedra.Description{Int}(copyinequalities(poly1 ))
ineout3f = Polyhedra.Description{Int}(copyinequalities(poly1f))
extout3  = Polyhedra.Description{Int}(  copygenerators(poly1 ))
extout3f = Polyhedra.Description{Int}(  copygenerators(poly1f))
ineout4  = Polyhedra.Description{Int}(copyinequalities(poly2 ))
ineout4f = Polyhedra.Description{Int}(copyinequalities(poly2f))
extout4  = Polyhedra.Description{Int}(  copygenerators(poly2 ))
extout4f = Polyhedra.Description{Int}(  copygenerators(poly2f))
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

Vray = [1 0; 0 1]
vertexray = IntSet([])
extray = Polyhedra.GeneratorDescription(Vray, vertexray)
extrayf = Polyhedra.GeneratorDescription(Array{Float64}(Vray), vertexray)
generator_fulltest(extray, Array(Int, 0, 2), Vray)
generator_fulltest(extrayf, Array(Int, 0, 2), Vray)
polyray = CDDPolyhedra(extray)
polyrayf = CDDPolyhedra(extrayf)
Acut = [1 1]
bcut = [1]
linsetcut = IntSet([1])
inecut = Polyhedra.InequalityDescription(Acut, bcut, linsetcut)
push!(polyray, inecut)
push!(polyrayf, inecut)
ineout5 = Polyhedra.Description{Int}(copyinequalities(polyray))
ineout5f = Polyhedra.Description{Int}(copyinequalities(polyrayf))
extout5 = Polyhedra.Description{Int}(copygenerators(polyray))
extout5f = Polyhedra.Description{Int}(copygenerators(polyrayf))
inequality_fulltest(ineout5, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
inequality_fulltest(ineout5f, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
generator_fulltest(extout5, V, vertex)
generator_fulltest(extout5f, V, vertex)
generator_fulltest(extout5, V, Array(Int, 0, 2))
generator_fulltest(extout5f, V, Array(Int, 0, 2))
