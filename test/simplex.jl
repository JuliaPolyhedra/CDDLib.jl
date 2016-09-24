function inequality_simpletest(ine::SimpleHRepresentation, A, b, linset)
# @show ine
# @show SimpleHRepresentation(A, b, linset)
# @test size(A) == size(ine.A)
# @test length(b) == length(ine.b)
# for i in 1:length(b)
#   @assert (i in linset) == (i in ine.linset)
#   if i in linset
#     if b[i] < 0 $ ine.b[i] < 0
#       @test -A[i,:] == ine.A[i,:]
#       @test -b[i] == ine.b[i]
#     else
#       @test A[i,:] == ine.A[i,:]
#       @test b[i] == ine.b[i]
#     end
#   else
#     @test A[i,:] == ine.A[i,:]
#     @test b[i] == ine.b[i]
#   end
# end
  @test A == ine.A
  @test b == ine.b
  @test linset == ine.linset
end
inequality_simpletest(ine::HRepresentation, A, b, linset) = inequality_simpletest(SimpleHRepresentation(ine), A, b, linset)
function generator_simpletest(ext::SimpleVRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2)))
  @test sortrows(V) == sortrows(ext.V)
  @test sortrows(R) == sortrows(ext.R)
end
generator_simpletest(ext::VRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2))) = generator_simpletest(SimpleVRepresentation(ext), V, R)

A = [1 1; -1 0; 0 -1]
b = [1, 0, 0]
ls = IntSet([1])
V = [0 1; 1 0]

ine = SimpleHRepresentation(A, b, ls)
#@test !isempty(ine)
inef = SimpleHRepresentation(Array{Float64}(A), Array{Float64}(b), ls)
#@test !isempty(inef)
poly1 = CDDPolyhedra(ine)
poly1f = CDDPolyhedra(inef)
ineout1  = SimpleHRepresentation{2,Int}(copyinequalities(poly1 ))
ineout1f = SimpleHRepresentation{2,Int}(copyinequalities(poly1f))
extout1  = SimpleVRepresentation{2,Int}(  copygenerators(poly1 ))
extout1f = SimpleVRepresentation{2,Int}(  copygenerators(poly1f))
inequality_simpletest(ineout1, A, b, ls)
inequality_simpletest(ineout1f, A, b, ls)
generator_simpletest(extout1, V)
generator_simpletest(extout1f, V)

Aalt = [1 0; -1 0; -1 -1]
balt = [1,0,-1]
linsetalt = IntSet([3])
ext = SimpleVRepresentation(V)
extf = SimpleVRepresentation(Array{Float64}(V))
poly2 = CDDPolyhedra(ext)
poly2f = CDDPolyhedra(extf)
ineout2  = SimpleHRepresentation{2,Int}(copyinequalities(poly2 ))
ineout2f = SimpleHRepresentation{2,Int}(copyinequalities(poly2f))
extout2  = SimpleVRepresentation{2,Int}(  copygenerators(poly2 ))
extout2f = SimpleVRepresentation{2,Int}(  copygenerators(poly2f))
inequality_simpletest(ineout2, Aalt, balt, linsetalt)
inequality_simpletest(ineout2f, Aalt, balt, linsetalt)
generator_simpletest(extout2, V)
generator_simpletest(extout2f, V)

# x_1 cannot be 2
#@test isempty(HRepresentation([A; 1 0], [b; 2], union(linset, IntSet([4]))))

V0 = [0 0]
ext0 = SimpleVRepresentation(V0)
ext0f = SimpleVRepresentation(Array{Float64}(V0))
push!(poly1, ext0)
push!(poly1f, ext0f)
push!(poly2, ext0)
push!(poly2f, ext0)
ineout3  = SimpleHRepresentation{2,Int}(copyinequalities(poly1 ))
ineout3f = SimpleHRepresentation{2,Int}(copyinequalities(poly1f))
extout3  = SimpleVRepresentation{2,Int}(  copygenerators(poly1 ))
extout3f = SimpleVRepresentation{2,Int}(  copygenerators(poly1f))
ineout4  = SimpleHRepresentation{2,Int}(copyinequalities(poly2 ))
ineout4f = SimpleHRepresentation{2,Int}(copyinequalities(poly2f))
extout4  = SimpleVRepresentation{2,Int}(  copygenerators(poly2 ))
extout4f = SimpleVRepresentation{2,Int}(  copygenerators(poly2f))
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
extray = SimpleVRepresentation(Matrix{Int}(0,2), Rray)
extrayf = SimpleVRepresentation(Matrix{Float64}(0,2), Array{Float64}(Rray))
generator_simpletest(extray, Array(Int, 0, 2), Rray)
generator_simpletest(extrayf, Array(Int, 0, 2), Rray)
polyray = CDDPolyhedra(extray)
polyrayf = CDDPolyhedra(extrayf)
Acut = [1 1]
bcut = [1]
linsetcut = IntSet([1])
inecut = SimpleHRepresentation(Acut, bcut, linsetcut)
push!(polyray, inecut)
push!(polyrayf, inecut)
ineout5 = SimpleHRepresentation{2,Int}(copyinequalities(polyray))
ineout5f = SimpleHRepresentation{2,Int}(copyinequalities(polyrayf))
extout5 = SimpleVRepresentation{2,Int}(copygenerators(polyray))
extout5f = SimpleVRepresentation{2,Int}(copygenerators(polyrayf))
inequality_simpletest(ineout5, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
inequality_simpletest(ineout5f, [-1 0; 0 -1; Acut], [0; 0; bcut], IntSet([3]))
generator_simpletest(extout5, V)
generator_simpletest(extout5f, V)
generator_simpletest(extout5, V, Array(Int, 0, 2))
generator_simpletest(extout5f, V, Array(Int, 0, 2))
