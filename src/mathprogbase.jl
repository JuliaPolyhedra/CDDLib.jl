import MathProgBase
importall MathProgBase.SolverInterface

type CDDMathProgModel <: AbstractMathProgModel
  solver_type::Symbol
  exact::Bool
  A::AbstractMatrix
  collb
  colub
  obj
  rowlb
  rowub
  sense

  status
  objval
  solution
  constrsolution
  reducedcosts
  constrduals
  infeasibilityray
end

type CDDSolver <: AbstractMathProgSolver
  solver_type::Symbol
  exact::Bool

  function CDDSolver(;solver_type::Symbol=:DualSimplex, exact::Bool=false)
    if !(solver_type in [:CrissCross, :DualSimplex])
      error("Invalid solver type, it should be :CrissCross or :DualSimplex")
    end
    new(solver_type, exact)
  end
end

function LinearQuadraticModel(s::CDDSolver)
  CDDMathProgModel(s.solver_type, s.exact, Array(Float64,0,0), [], [], [], [], [], [], :Undefined, 0, [], [], [], [], [])
end

function loadproblem!(lpm::CDDMathProgModel, A::AbstractMatrix, collb, colub, obj, rowlb, rowub, sense)
  lpm.A = A
  lpm.collb = collb
  lpm.colub = colub
  lpm.obj = obj
  lpm.rowlb = rowlb
  lpm.rowub = rowub
  lpm.sense = sense
end

nonnull(x) = (x != nothing && !isempty(x))

function optimize!(lpm::CDDMathProgModel)
  function count_constraints(lb, ub)
    count = 0
    for i = 1:length(lb)
      if nonnull(lb) && lb[i] != -Inf && (!nonnull(ub) || lb[i] != ub[i])
        count += 1
      end
      if nonnull(ub) && ub[i] != Inf
        count += 1
      end
    end
    count
  end
  m = count_constraints(lpm.rowlb, lpm.rowub) + count_constraints(lpm.collb, lpm.colub)
  if lpm.exact
    T = GMPRationalMut
  else
    T = Cdouble
  end
  A = Array(T, m, size(lpm.A, 2))
  b = Array(T, m)
  linset = IntSet([])
  cur = 1
  for i = 1:size(lpm.A, 1)
    if nonnull(lpm.rowlb) && lpm.rowlb[i] != -Inf && (!nonnull(lpm.rowub) || lpm.rowlb[i] != lpm.rowub[i])
      A[cur, :] = -lpm.A[i, :]
      b[cur] = -lpm.rowlb[i]
      cur += 1
    end
    if nonnull(lpm.rowub) && lpm.rowub[i] != Inf
      A[cur, :] = lpm.A[i, :]
      b[cur] = lpm.rowub[i]
      if nonnull(lpm.rowlb) && lpm.rowlb[i] == lpm.rowub[i]
        push!(linset, cur)
      end
      cur += 1
    end
  end
  for i = 1:size(lpm.A, 2)
    if nonnull(lpm.collb) && lpm.collb[i] != -Inf && (!nonnull(lpm.colub) || lpm.collb[i] != lpm.colub[i])
      A[cur, :] = 0 # May be the same GMPRationalMut but A is not modified anyway
      A[cur, i] = -1
      b[cur] = -lpm.collb[i]
      cur += 1
    end
    if nonnull(lpm.colub) && lpm.colub[i] != Inf
      A[cur, :] = 0
      A[cur, i] = 1
      b[cur] = lpm.colub[i]
      if nonnull(lpm.collb) && lpm.collb[i] == lpm.colub[i]
        push!(linset, cur)
      end
      cur += 1
    end
  end

  if lpm.exact
    A = Array{GMPRational}(A)
    b = Array{GMPRational}(b)
  end

  ine = InequalityDescription(A, b, linset)

  matrix = CDDMatrix(ine)
  dd_setmatrixobjective(matrix.matrix, lpm.sense == :Max ? dd_LPmax : dd_LPmin)
  if lpm.exact
    obj = [GMPRational(0); Array{GMPRational}(lpm.obj)]
  else
    obj = [Cdouble(0); Array{Cdouble}(lpm.obj)]
  end
  dd_copyArow(unsafe_load(matrix.matrix).rowvec, obj, length(obj))

  lp = dd_matrix2lp(matrix.matrix)
  dd_lpsolve(lp, lpm.solver_type == :DualSimplex ? dd_DualSimplex : dd_CrissCross)
  sol = dd_copylpsolution(lp)
  dd_freelpdata(lp)
  soldata = unsafe_load(sol)
  if soldata.LPS == dd_Optimal
    lpm.status = :Optimal
  elseif soldata.LPS == dd_Inconsistent || soldata.LPS == dd_DualUnbounded || soldata.LPS == dd_StrucInconsistent
    lpm.status = :Infeasible
  elseif soldata.LPS == dd_DualInconsistent || soldata.LPS == dd_Unbounded || soldata.LPS == dd_StrucDualInconsistent
    lpm.status = :Unbounded
  else
    lpm.status = :Error
  end
  if lpm.exact
    lpm.objval = Rational{Int}(soldata.optvalue)
  else
    lpm.objval = soldata.optvalue
  end
  solutiontmp = myconvert(Array, soldata.sol, size(A, 2)+1)
  if lpm.exact
    lpm.solution = Array{Rational{BigInt}}(solutiontmp)[2:end]
    myfree(solutiontmp)
  else
    lpm.solution = solutiontmp[2:end]
  end
  lpm.constrsolution = lpm.A * lpm.solution
  reducedcoststmp = myconvert(Array, soldata.dsol, size(A, 1))
  if lpm.exact
    lpm.reducedcosts = Array{Rational{BigInt}}(reducedcoststmp)
  else
    lpm.reducedcosts = reducedcoststmp
  end
  constrdualstmp = A' * reducedcoststmp
  if lpm.exact
    lpm.constrduals = Array{Rational{BigInt}}(constrdualstmp)
    myfree(constrdualstmp)
    myfree(reducedcoststmp)
  else
    lpm.constrduals = constrdualstmp
  end
  dd_freelpsolution(sol)

  lpm.infeasibilityray = zeros(size(lpm.A, 1))
  eps = 1e-7
  for i = 1:size(lpm.A, 1)
    if nonnull(lpm.rowlb) && lpm.rowlb[i] != -Inf
      if (lpm.exact && lpm.constrsolution[i] < lpm.rowlb[i]) || (!lpm.exact && lpm.constrsolution[i] < lpm.rowlb[i] - eps)
        lpm.infeasibilityray[i] = 1
      end
    end
    if nonnull(lpm.rowub) && lpm.rowub[i] != Inf
      if (lpm.exact && lpm.constrsolution[i] > lpm.rowub[i]) || (!lpm.exact && lpm.constrsolution[i] > lpm.rowub[i] + eps)
        lpm.infeasibilityray[i] = -1
      end
    end
  end

  # A and b free'd by ine
end

function status(lpm::CDDMathProgModel)
  lpm.status
end

function getobjval(lpm::CDDMathProgModel)
  lpm.objval
end

function getsolution(lpm::CDDMathProgModel)
  copy(lpm.solution)
end

function getconstrsolution(lpm::CDDMathProgModel)
  copy(lpm.constrsolution)
end

function getreducedcosts(lpm::CDDMathProgModel)
  copy(lpm.reducedcosts)
end

function getconstrduals(lpm::CDDMathProgModel)
  copy(lpm.constrduals)
end

function getinfeasibilityray(lpm::CDDMathProgModel)
  copy(lpm.infeasibilityray)
end

function getunboundedray(lpm::CDDMathProgModel)
  copy(lpm.solution)
end

export CDDMathProgModel, CDDSolver
