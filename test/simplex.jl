function inequality_simpletest(ine, A, b, linset)
  @test A == ine.A
  @test b == ine.b
  @test linset == ine.linset
end
function generator_simpletest(ext, V, R)
  Polyhedra.splitvertexrays!(ext)
  @test sortrows(V) == sortrows(ext.V)
  @test sortrows(R) == sortrows(ext.R)
end
function generator_simpletest(ext, V, vertex::IntSet)
  @test V == ext.V
  @test vertex == ext.vertex
end


A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]
vertex = IntSet([1,2])

ine = Polyhedra.HRepresentation(A, b, linset)
#@test !isempty(ine)
inef = Polyhedra.HRepresentation(Array{Float64}(A), Array{Float64}(b), linset)
#@test !isempty(inef)
poly1 = CDDPolyhedra(ine)
poly1f = CDDPolyhedra(inef)
ineout1  = Polyhedra.Representation{Int}(copyinequalities(poly1 ))
ineout1f = Polyhedra.Representation{Int}(copyinequalities(poly1f))
extout1  = Polyhedra.Representation{Int}(  copygenerators(poly1 ))
extout1f = Polyhedra.Representation{Int}(  copygenerators(poly1f))
inequality_simpletest(ineout1, A, b, linset)
inequality_simpletest(ineout1f, A, b, linset)
generator_simpletest(extout1, V, vertex)
generator_simpletest(extout1f, V, vertex)

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
linsetalt = IntSet([3])
ext = Polyhedra.VRepresentation(V, vertex)
extf = Polyhedra.VRepresentation(Array{Float64}(V), vertex)
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = Polyhedra.Representation{Int}(copyinequalities(poly2 ))
ineout2f = Polyhedra.Representation{Int}(copyinequalities(poly2f))
extout2  = Polyhedra.Representation{Int}(  copygenerators(poly2 ))
extout2f = Polyhedra.Representation{Int}(  copygenerators(poly2f))
inequality_simpletest(ineout2, Aalt, balt, linsetalt)
inequality_simpletest(ineout2f, Aalt, balt, linsetalt)
generator_simpletest(extout2, V, vertex)
generator_simpletest(extout2f, V, vertex)

# x_1 cannot be 2
#@test isempty(Polyhedra.HRepresentation([A; 1 0], [b; 2], union(linset, IntSet([4]))))

V0 = [0 0]
vertex0 = IntSet([1])
ext0 = Polyhedra.VRepresentation(V0, vertex0)
ext0f = Polyhedra.VRepresentation(Array{Float64}(V0), vertex0)
push!(poly1, ext0)
push!(poly1f, ext0f)
push!(poly2, ext0)
push!(poly2f, ext0)
ineout3  = Polyhedra.Representation{Int}(copyinequalities(poly1 ))
ineout3f = Polyhedra.Representation{Int}(copyinequalities(poly1f))
extout3  = Polyhedra.Representation{Int}(  copygenerators(poly1 ))
extout3f = Polyhedra.Representation{Int}(  copygenerators(poly1f))
ineout4  = Polyhedra.Representation{Int}(copyinequalities(poly2 ))
ineout4f = Polyhedra.Representation{Int}(copyinequalities(poly2f))
extout4  = Polyhedra.Representation{Int}(  copygenerators(poly2 ))
extout4f = Polyhedra.Representation{Int}(  copygenerators(poly2f))
Vfull = [V;V0]
vertexfull = union(vertex, IntSet([3]))
linsetfull = IntSet([])
inequality_simpletest(ineout3, A, b, linsetfull)
inequality_simpletest(ineout3f, A, b, linsetfull)
generator_simpletest(extout3, Vfull, vertexfull)
generator_simpletest(extout3f, Vfull, vertexfull)
inequality_simpletest(ineout4, A, b, linsetfull)
inequality_simpletest(ineout4f, A, b, linsetfull)
generator_simpletest(extout4, Vfull, vertexfull)
generator_simpletest(extout4f, Vfull, vertexfull)

Vray = [1 0; 0 1]
vertexray = IntSet([])
extray = Polyhedra.VRepresentation(Vray, vertexray)
extrayf = Polyhedra.VRepresentation(Array{Float64}(Vray), vertexray)
generator_simpletest(extray, Array(Int, 0, 2), Vray)
generator_simpletest(extrayf, Array(Int, 0, 2), Vray)
polyray = CDDPolyhedra(extray)
polyrayf = CDDPolyhedra(extrayf)
Acut = [1 1]
bcut = [1]
linsetcut = IntSet([1])
inecut = Polyhedra.HRepresentation(Acut, bcut, linsetcut)
push!(polyray, inecut)
push!(polyrayf, inecut)
ineout5 = Polyhedra.Representation{Int}(copyinequalities(polyray))
ineout5f = Polyhedra.Representation{Int}(copyinequalities(polyrayf))
extout5 = Polyhedra.Representation{Int}(copygenerators(polyray))
extout5f = Polyhedra.Representation{Int}(copygenerators(polyrayf))
inequality_simpletest(ineout5, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
inequality_simpletest(ineout5f, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
generator_simpletest(extout5, V, vertex)
generator_simpletest(extout5f, V, vertex)
generator_simpletest(extout5, V, Array(Int, 0, 2))
generator_simpletest(extout5f, V, Array(Int, 0, 2))
