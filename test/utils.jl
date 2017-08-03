function inequality_simpletest(ine::SimpleHRepresentation, A, b, linset)
    @test A == ine.A
    @test b == ine.b
    @test linset == ine.linset
end
inequality_simpletest(ine::HRepresentation, A, b, linset) = inequality_simpletest(SimpleHRepresentation(ine), A, b, linset)
function generator_simpletest(ext::SimpleVRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2)))
    @test sortrows(V) == sortrows(round.(ext.V))
    @test sortrows(R) == sortrows(round.(ext.R))
end
generator_simpletest(ext::VRepresentation, V, R = Matrix{eltype(V)}(0, size(V, 2))) = generator_simpletest(SimpleVRepresentation(ext), V, R)

