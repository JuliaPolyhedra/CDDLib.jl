function inequality_simpletest(ine::Polyhedra.SimpleHRepresentation, A, b, linset)
  @test A == ine.A
  @test b == ine.b
  @test linset == ine.linset
end
inequality_simpletest(ine::Polyhedra.HRepresentation, A, b, linset) = inequality_simpletest(Polyhedra.SimpleHRepresentation(ine), A, b, linset)
function generator_simpletest(ext::Polyhedra.SimpleVRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2)))
  @test sortrows(V) == sortrows(ext.V)
  @test sortrows(R) == sortrows(ext.R)
end
generator_simpletest(ext::Polyhedra.VRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2))) = generator_simpletest(Polyhedra.SimpleVRepresentation(ext), V, R)

A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
linset = IntSet([1])
V = [0 1; 1 0]

ine = Polyhedra.SimpleHRepresentation(A, b, linset)
#@test !isempty(ine)
inef = Polyhedra.SimpleHRepresentation(Array{Float64}(A), Array{Float64}(b), linset)
#@test !isempty(inef)
poly1 = CDDPolyhedra(ine)
poly1f = CDDPolyhedra(inef)
ineout1  = Polyhedra.Representation{2,Int}(copyinequalities(poly1 ))
ineout1f = Polyhedra.Representation{2,Int}(copyinequalities(poly1f))
extout1  = Polyhedra.Representation{2,Int}(  copygenerators(poly1 ))
extout1f = Polyhedra.Representation{2,Int}(  copygenerators(poly1f))
inequality_simpletest(ineout1, A, b, linset)
inequality_simpletest(ineout1f, A, b, linset)
generator_simpletest(extout1, V)
generator_simpletest(extout1f, V)

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
linsetalt = IntSet([3])
ext = Polyhedra.SimpleVRepresentation(V)
extf = Polyhedra.SimpleVRepresentation(Array{Float64}(V))
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = Polyhedra.Representation{2,Int}(copyinequalities(poly2 ))
ineout2f = Polyhedra.Representation{2,Int}(copyinequalities(poly2f))
extout2  = Polyhedra.Representation{2,Int}(  copygenerators(poly2 ))
extout2f = Polyhedra.Representation{2,Int}(  copygenerators(poly2f))
inequality_simpletest(ineout2, Aalt, balt, linsetalt)
inequality_simpletest(ineout2f, Aalt, balt, linsetalt)
generator_simpletest(extout2, V)
generator_simpletest(extout2f, V)

# x_1 cannot be 2
#@test isempty(Polyhedra.HRepresentation([A; 1 0], [b; 2], union(linset, IntSet([4]))))

V0 = [0 0]
ext0 = Polyhedra.SimpleVRepresentation(V0)
ext0f = Polyhedra.SimpleVRepresentation(Array{Float64}(V0))
push!(poly1, ext0)
push!(poly1f, ext0f)
push!(poly2, ext0)
push!(poly2f, ext0)
ineout3  = Polyhedra.Representation{2,Int}(copyinequalities(poly1 ))
ineout3f = Polyhedra.Representation{2,Int}(copyinequalities(poly1f))
extout3  = Polyhedra.Representation{2,Int}(  copygenerators(poly1 ))
extout3f = Polyhedra.Representation{2,Int}(  copygenerators(poly1f))
ineout4  = Polyhedra.Representation{2,Int}(copyinequalities(poly2 ))
ineout4f = Polyhedra.Representation{2,Int}(copyinequalities(poly2f))
extout4  = Polyhedra.Representation{2,Int}(  copygenerators(poly2 ))
extout4f = Polyhedra.Representation{2,Int}(  copygenerators(poly2f))
Vfull = [V;V0]
linsetfull = IntSet([])
inequality_simpletest(ineout3, A, b, linsetfull)
inequality_simpletest(ineout3f, A, b, linsetfull)
generator_simpletest(extout3, Vfull)
generator_simpletest(extout3f, Vfull)
inequality_simpletest(ineout4, A, b, linsetfull)
inequality_simpletest(ineout4f, A, b, linsetfull)
generator_simpletest(extout4, Vfull)
generator_simpletest(extout4f, Vfull)

Rray = [1 0; 0 1]
extray = Polyhedra.SimpleVRepresentation(Matrix{Int}(0,2), Rray)
extrayf = Polyhedra.SimpleVRepresentation(Matrix{Float64}(0,2), Array{Float64}(Rray))
generator_simpletest(extray, Array(Int, 0, 2), Rray)
generator_simpletest(extrayf, Array(Int, 0, 2), Rray)
polyray = CDDPolyhedra(extray)
polyrayf = CDDPolyhedra(extrayf)
Acut = [1 1]
bcut = [1]
linsetcut = IntSet([1])
inecut = Polyhedra.SimpleHRepresentation(Acut, bcut, linsetcut)
push!(polyray, inecut)
push!(polyrayf, inecut)
ineout5 = Polyhedra.Representation{2,Int}(copyinequalities(polyray))
ineout5f = Polyhedra.Representation{2,Int}(copyinequalities(polyrayf))
extout5 = Polyhedra.Representation{2,Int}(copygenerators(polyray))
extout5f = Polyhedra.Representation{2,Int}(copygenerators(polyrayf))
inequality_simpletest(ineout5, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
inequality_simpletest(ineout5f, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
generator_simpletest(extout5, V)
generator_simpletest(extout5f, V)
generator_simpletest(extout5, V, Array(Int, 0, 2))
generator_simpletest(extout5f, V, Array(Int, 0, 2))
