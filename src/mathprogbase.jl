export CDDPolyhedraModel, CDDSolver

mutable struct CDDPolyhedraModel <: AbstractPolyhedraModel
  solver_type::Symbol
  exact::Bool

  prob::Nullable{CDDInequalityMatrix}

  status
  objval
  solution
  constrsolution
  constrduals
  infeasibilityray
end

mutable struct CDDSolver <: AbstractMathProgSolver
  solver_type::Symbol
  exact::Bool

  function CDDSolver(;solver_type::Symbol=:DualSimplex, exact::Bool=false)
    if !(solver_type in [:CrissCross, :DualSimplex])
      error("Invalid solver type, it should be :CrissCross or :DualSimplex")
    end
    new(solver_type, exact)
  end
end

function PolyhedraModel(s::CDDSolver)
  CDDPolyhedraModel(s.solver_type, s.exact, nothing, :Undefined, 0, [], [], [], [])
end
LinearQuadraticModel(s::CDDSolver) = PolyhedraToLPQPBridge(PolyhedraModel(s))

function loadproblem!(lpm::CDDPolyhedraModel, rep::HRep{N}, obj, sense) where N
  T = lpm.exact ? Rational{BigInt} : Float64
  prob = CDDInequalityMatrix{N, T, mytype(T)}(rep)
  setobjective(prob, obj, sense)
  lpm.prob = prob
end

nonnull(x) = (x != nothing && !isempty(x))

function optimize!(lpm::CDDPolyhedraModel)
  if isnull(lpm.prob)
    error("Problem not loaded")
  end
  prob = get(lpm.prob)
  lp = matrix2lp(prob)
  lpsolve(lp, lpm.solver_type)
  sol = copylpsolution(lp)
  lpm.status = simplestatus(sol)
  # We have just called lpsolve so it shouldn't be Undecided
  # if no error occured
  lpm.status == :Undecided && (lpm.status = :Error)
  lpm.objval = getobjval(sol)
  lpm.solution = getsolution(sol)

  lpm.constrduals = getconstrduals(sol)
  # if A has equalities, cddlib splits them as 2 inequalities
  m = nhreps(prob)
  if length(lpm.constrduals) > m
      secondeqduals = lpm.constrduals[m+1:end]
      lpm.constrduals = lpm.constrduals[1:m]
      lpm.constrduals[collect(linset(prob))] -= secondeqduals
  end
  # FIXME if A is GMPRational, check that no creation/leak

  #T = eltype(prob) # FIXME how did it work, where is eltype defined for prob ?
  T = typeof(lpm.objval)

  lpm.constrsolution = Vector{T}(nhreps(prob))
  lpm.infeasibilityray = zeros(T, nhreps(prob))

  eps = 1e-7
  for (i,h) in enumerate(hreps(prob))
    lpm.constrsolution[i] = dot(coord(h), lpm.solution)
    if Polyhedra.mygt(lpm.constrsolution[i], h.β)
      lpm.infeasibilityray[i] = -1
    end
  end

  # A and b free'd by ine
end

function status(lpm::CDDPolyhedraModel)
  lpm.status
end

function getobjval(lpm::CDDPolyhedraModel)
  lpm.objval
end

function getsolution(lpm::CDDPolyhedraModel)
  copy(lpm.solution)
end

function getconstrsolution(lpm::CDDPolyhedraModel)
  copy(lpm.constrsolution)
end

function getreducedcosts(lpm::CDDPolyhedraModel)
  prob = get(lpm.prob)
  spzeros(eltype(prob), fulldim(prob))
end

function getconstrduals(lpm::CDDPolyhedraModel)
  copy(lpm.constrduals)
end

function getinfeasibilityray(lpm::CDDPolyhedraModel)
  copy(lpm.infeasibilityray)
end

function getunboundedray(lpm::CDDPolyhedraModel)
  copy(lpm.solution)
end
