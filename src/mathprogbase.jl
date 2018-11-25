using SparseArrays

export CDDPolyhedraModel, CDDSolver

mutable struct CDDPolyhedraModel <: Polyhedra.AbstractPolyhedraModel
    solver_type::Symbol
    exact::Bool

    prob::Union{Nothing, CDDInequalityMatrix}

    status
    objval
    solution
    constrsolution
    constrduals
    infeasibilityray
end

mutable struct CDDSolver <: MPB.AbstractMathProgSolver
    solver_type::Symbol
    exact::Bool

    function CDDSolver(;solver_type::Symbol=:DualSimplex, exact::Bool=false)
        if !(solver_type in [:CrissCross, :DualSimplex])
            error("Invalid solver type, it should be :CrissCross or :DualSimplex")
        end
        new(solver_type, exact)
    end
end

function Polyhedra.PolyhedraModel(s::CDDSolver)
    CDDPolyhedraModel(s.solver_type, s.exact, nothing, :Undefined, 0, [], [], [], [])
end

function Polyhedra.PolyhedraToLPQPBridge(lpm::CDDPolyhedraModel)
    T = lpm.exact ? Rational{BigInt} : Float64
    Polyhedra.PolyhedraToLPQPBridge(lpm, sparse(Int[],Int[],T[]), T[], T[], T[], T[], T[], :Min, nothing, nothing)
end

MPB.LinearQuadraticModel(s::CDDSolver) = Polyhedra.PolyhedraToLPQPBridge(Polyhedra.PolyhedraModel(s))

function MPB.loadproblem!(lpm::CDDPolyhedraModel, rep::HRep, obj, sense)
    T = lpm.exact ? Rational{BigInt} : Float64
    prob = convert(CDDInequalityMatrix{T, mytype(T)}, rep)
    setobjective(prob, obj, sense)
    lpm.prob = prob
end

nonnull(x) = (x != nothing && !isempty(x))

function MPB.optimize!(lpm::CDDPolyhedraModel)
    if lpm.prob === nothing
        error("Problem not loaded")
    end
    prob = lpm.prob
    lp = matrix2lp(prob)
    lpsolve(lp, lpm.solver_type)
    sol = copylpsolution(lp)
    lpm.status = simplestatus(sol)
    # We have just called lpsolve so it shouldn't be Undecided
    # if no error occured
    lpm.status == :Undecided && (lpm.status = :Error)
    lpm.objval = MPB.getobjval(sol)
    lpm.solution = MPB.getsolution(sol)

    lpm.constrduals = MPB.getconstrduals(sol)
    # if A has equalities, cddlib splits them as 2 inequalities
    m = nhreps(prob)
    if length(lpm.constrduals) > m
        secondeqduals = lpm.constrduals[m+1:end]
        lpm.constrduals = lpm.constrduals[1:m]
        lpm.constrduals[collect(linset(prob))] -= secondeqduals
    end
    # FIXME if A is GMPRational, check that no creation/leak

    T = Polyhedra.coefficient_type(prob)

    lpm.constrsolution = Vector{T}(undef, nhreps(prob))
    lpm.infeasibilityray = zeros(T, nhreps(prob))

    eps = 1e-7
    for i in 1:nhreps(prob)
        a, β = extractrow(prob, i)
        lpm.constrsolution[i] = dot(a, lpm.solution)
        if Polyhedra._gt(lpm.constrsolution[i], β)
            lpm.infeasibilityray[i] = -1
        end
    end

    # A and b free'd by ine
end

function MPB.status(lpm::CDDPolyhedraModel)
    lpm.status
end

function MPB.getobjval(lpm::CDDPolyhedraModel)
    lpm.objval
end

function MPB.getsolution(lpm::CDDPolyhedraModel)
    copy(lpm.solution)
end

function MPB.getconstrsolution(lpm::CDDPolyhedraModel)
    copy(lpm.constrsolution)
end

function MPB.getreducedcosts(lpm::CDDPolyhedraModel)
    prob = lpm.prob
    spzeros(Polyhedra.coefficienttype(prob), fulldim(prob))
end

function MPB.getconstrduals(lpm::CDDPolyhedraModel)
    copy(lpm.constrduals)
end

function MPB.getinfeasibilityray(lpm::CDDPolyhedraModel)
    copy(lpm.infeasibilityray)
end

function MPB.getunboundedray(lpm::CDDPolyhedraModel)
    copy(lpm.solution)
end
