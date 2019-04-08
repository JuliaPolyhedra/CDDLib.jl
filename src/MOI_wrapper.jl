using SparseArrays

"""
    CDDLib.Optimizer{T} <: AbstractPolyhedraOptimizer{T}

CDDLib Linear Programming solver, supports either exact arithmetic or floating point arithmetic.
"""
mutable struct Optimizer{T} <: Polyhedra.AbstractPolyhedraOptimizer{T}
    solver_type::Symbol
    lphrep::LPHRep{T}
    # Feasible set defined by user
    rep::Union{Rep{T}, Nothing}
    # Either `rep` or `polyhedron(lphrep, library)`.
    # It is kept between consecutive solve if not modified,
    # e.g. if only the objective is changed.
    feasible_set::Union{Rep{T}, Nothing}

    objective_sense::MOI.OptimizationSense
    objective_func::Union{SparseVector{T, Int64}, Nothing}
    objective_constant::T

    sol::Union{Nothing, CDDLPSolution} # TODO {S} where S = mytype(T)
    solution::Union{AbstractVector{T}, Nothing}

    function Optimizer{T}(solver_type::Symbol = :DualSimplex) where T
        if !(solver_type in [:CrissCross, :DualSimplex])
            error("Invalid solver type `$solver_type`, it should be `:CrissCross` or `:DualSimplex`.")
        end
        new(solver_type, LPHRep(Polyhedra._MOIModel{T}()), nothing, nothing,
            MOI.FEASIBILITY_SENSE, nothing, zero(T),
            nothing, nothing)
    end
end

coefficient_type(::Optimizer{T}) where {T} = T
MOI.get(::Optimizer, ::MOI.SolverName) = "CDD"

function MOI.empty!(lpm::Optimizer{T}) where T
    lpm.lphrep = LPHRep(Polyhedra._MOIModel{T}())
    lpm.rep = nothing
    lpm.feasible_set = nothing
    lpm.objective_sense = MOI.FEASIBILITY_SENSE
    lpm.objective_func = nothing
    lpm.objective_constant = zero(T)
    lpm.sol = nothing
    lpm.solution = nothing
end
function MOI.is_empty(lpm::Optimizer{T}) where T
    MOI.is_empty(lpm.lphrep.model) &&
    lpm.rep === nothing &&
    lpm.feasible_set === nothing &&
    lpm.objective_sense == MOI.FEASIBILITY_SENSE &&
    lpm.objective_func === nothing &&
    iszero(lpm.objective_constant) &&
    lpm.sol === nothing &&
    lpm.solution === nothing
end


function MOI.optimize!(lpm::Optimizer{T}) where T
    if lpm.rep === nothing
        lpm.feasible_set = lpm.lphrep
    else
        if hasallhalfspaces(lpm.lphrep)
            error("Cannot provide both a polyhedral feasible set and additional constraints.")
        end
        lpm.feasible_set = lpm.rep
    end
    prob = convert(CDDInequalityMatrix{T, mytype(T)}, lpm.feasible_set)
    if lpm.objective_sense == MOI.FEASIBILITY_SENSE
        @assert lpm.objective_func === nothing
        # Otherwise CDD throws the error "No LP objective"
        setobjective(prob, zeros(T, fulldim(lpm.feasible_set)), true)
    else
        @assert lpm.objective_func !== nothing
        setobjective(prob, lpm.objective_func, lpm.objective_sense == MOI.MAX_SENSE)
    end
    lp = matrix2lp(prob)
    lpsolve(lp, lpm.solver_type)
    lpm.sol = copylpsolution(lp)
    lpm.solution = getsolution(lpm.sol)

    # FIXME if A is GMPRational, check that no creation/leak

    # A and b free'd by ine
end

function MOI.get(sol::CDDLPSolution, ::MOI.RawStatusString)
    ["Undecided", "Optimal", "Inconsistent",
     "Dual inconsistent", "Struct inconsistent", "Struct dual inconsistent",
     "Unbounded", "Dual unbounded"][unsafe_load(sol.sol).LPS+1]
end
function MOI.get(sol::CDDLPSolution, ::MOI.TerminationStatus)
    [MOI.OPTIMIZE_NOT_CALLED, MOI.OPTIMAL, MOI.INFEASIBLE,
     MOI.DUAL_INFEASIBLE, MOI.INFEASIBLE, MOI.DUAL_INFEASIBLE,
     MOI.DUAL_INFEASIBLE, MOI.INFEASIBLE][unsafe_load(sol.sol).LPS+1]
end
function MOI.get(sol::CDDLPSolution{GMPRational}, ::MOI.ObjectiveValue)
    convert(Rational{Int}, unsafe_load(sol.sol).optvalue)
end
function MOI.get(lpm::Optimizer,
                 attr::Union{MOI.RawStatusString,
                             MOI.TerminationStatus})
    if lpm.sol === nothing
        return MOI.OPTIMIZE_NOT_CALLED
    else
        return MOI.get(lpm.sol, attr)
    end
end

function MOI.get(sol::CDDLPSolution{Cdouble}, ::MOI.ObjectiveValue)
    unsafe_load(sol.sol).optvalue
end
function MOI.get(lpm::Optimizer, attr::MOI.ObjectiveValue)
    return MOI.get(lpm.sol, attr) + lpm.objective_constant
end

function MOI.get(lpm::Optimizer, ::MOI.ResultCount)
    status = MOI.get(lpm, MOI.TerminationStatus())
    if status == MOI.OPTIMAL || status == MOI.DUAL_INFEASIBLE
        return 1
    else
        return 0
    end
end

function MOI.get(lpm::Optimizer, ::MOI.PrimalStatus)
    term = MOI.get(lpm, MOI.TerminationStatus())
    if term == MOI.OPTIMAL
        return MOI.FEASIBLE_POINT
    elseif term == MOI.DUAL_INFEASIBLE
        return MOI.INFEASIBILITY_CERTIFICATE
    else
        return MOI.NO_SOLUTION
    end
end
function MOI.get(lpm::Optimizer, ::MOI.VariablePrimal, vi::MOI.VariableIndex)
    return lpm.solution[vi.value]
end
function MOI.get(lpm::Optimizer{T}, attr::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T},
                                         <:Union{MOI.EqualTo{T},
                                                 MOI.LessThan{T}}}) where T
    return MOI.Utilities.get_fallback(lpm, attr, ci)
end

# TODO dual
