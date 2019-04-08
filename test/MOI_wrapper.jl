using Test
import MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges
using Polyhedra
using CDDLib

@testset "Continuous Linear problems with CDDLib.Optimizer" begin
    optimizer = CDDLib.Optimizer{Float64}()
    @testset "SolverName" begin
        @test MOI.get(optimizer, MOI.SolverName()) == "CDD"
    end
    cache = MOIU.UniversalFallback(Polyhedra._MOIModel{Float64}())
    cached = MOIU.CachingOptimizer(cache, optimizer)
    bridged = MOIB.full_bridge_optimizer(cached, Float64)
    config = MOIT.TestConfig(duals=false)
    MOIT.contlineartest(bridged, config,
                        # linear8a and linear12 will be solved by https://github.com/JuliaOpt/MathOptInterface.jl/pull/702
                        ["linear8a", "linear12", "partial_start"])
end
