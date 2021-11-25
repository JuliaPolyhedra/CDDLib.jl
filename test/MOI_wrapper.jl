using Test
import MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges
using Polyhedra
using CDDLib

@testset "MOI wrapper with $T" for T in [Rational{BigInt}, Float64]
    @testset "coefficient_type" begin
        @test Polyhedra.coefficient_type(CDDLib.Optimizer{T}()) == T
    end
    optimizer = CDDLib.Optimizer{T}()
    @testset "SolverName" begin
        @test MOI.get(optimizer, MOI.SolverName()) == "CDD"
    end
    @testset "Continuous Linear problems with CDDLib.Optimizer{$T}" begin
        cache = MOIU.UniversalFallback(Polyhedra._MOIModel{T}())
        cached = MOIU.CachingOptimizer(cache, optimizer)
        bridged = MOIB.full_bridge_optimizer(cached, T)
        config = MOIT.Config(
            T,
            exclude = Any[
                MOI.ObjectiveBound,
                MOI.DualObjectiveValue,
                MOI.ConstraintDual,
                MOI.SolveTimeSec,
                MOI.SolverVersion,
                MOI.VariableBasisStatus,
                MOI.ConstraintBasisStatus,
            ]
        )
        MOIT.runtests(
            bridged,
            config,
            exclude = String[
            # TODO remove as it is fixed in MOI master
            "test_model_UpperBoundAlreadySet",
            "test_model_LowerBoundAlreadySet",
        ])
    end
end
