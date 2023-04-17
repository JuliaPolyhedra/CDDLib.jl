using Test
import MathOptInterface as MOI
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
        if T == Float64
            MOIT.runtests(
                bridged,
                config,
                exclude = String[
                    # TODO investigate
                    "test_unbounded_MAX_SENSE",
                    "test_unbounded_MAX_SENSE_offset",
                    "test_unbounded_MIN_SENSE",
                    "test_unbounded_MIN_SENSE_offset",
                    # TODO Should be fixed in MOI master
                    "test_model_LowerBoundAlreadySet",
                    "test_model_UpperBoundAlreadySet",
                    "test_linear_open_intervals",
                ],
            )
        else
            MOIT.runtests(
                bridged,
                config,
                # Other tests do not support non-`Float64`
                include = String["test_linear"],
                exclude = String[
                    "test_linear_Indicator",
                    "test_linear_SOS1",
                    "test_linear_SOS2",
                    "test_linear_Semicontinuous",
                    "test_linear_Semiinteger",
                    "test_linear_integer",
                    # TODO Should be fixed in MOI master
                    "test_linear_open_intervals",
                ]
            )
        end
    end
end
