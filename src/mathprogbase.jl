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

  ine = SimpleHRepresentation(A, b, linset)

  matrix = CDDMatrix(ine)
  setobjective(matrix, lpm.obj, lpm.sense)

  lp = matrix2lp(matrix)
  lpsolve(lp, lpm.solver_type)
  sol = copylpsolution(lp)
  lpm.status = simplestatus(sol)
  # We have just called lpsolve so it shouldn't be Undecided
  # if no error occured
  lpm.status == :Undecided && (lpm.status = :Error)
  lpm.objval = getobjval(sol)
  lpm.solution = getsolution(sol)
  lpm.constrsolution = lpm.A * lpm.solution
  lpm.reducedcosts = getreducedcosts(sol)
  # FIXME if A has equalities, cddlib splits them as 2 inequalities
  lpm.reducedcosts = lpm.reducedcosts[1:size(A, 1)]
  # FIXME if A is GMPRational, check that no creation/leak
  if lpm.exact
    lpm.constrduals = Matrix{Rational{BigInt}}(A)' * lpm.reducedcosts
  else
    lpm.constrduals = A' * lpm.reducedcosts
  end

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
