function inequality_simpletest(ine::Polyhedra.MixedMatHRep, A, b, linset)
    @test A == ine.A
    @test b == ine.b
    @test linset == ine.linset
end
inequality_simpletest(ine::HRepresentation, A, b, linset) = inequality_simpletest(MixedMatHRep(ine), A, b, linset)
function generator_simpletest(ext::MixedMatVRep, V, R = Matrix{eltype(V)}(undef, 0, size(V, 2)))
    @test sortslices(V, dims=1) == sortslices(round.(ext.V), dims=1)
    @test sortslices(R, dims=1) == sortslices(round.(ext.R), dims=1)
end
generator_simpletest(ext::VRepresentation, V, R = Matrix{eltype(V)}(undef, 0, size(V, 2))) = generator_simpletest(MixedMatVRep(ext), V, R)
