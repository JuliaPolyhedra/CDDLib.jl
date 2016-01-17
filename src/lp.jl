import Base.isempty

type CDDLPSolutionData{T<:MyType}
  filename::Cdd_DataFileType
  objective::Cdd_LPObjectiveType
  solver::Cdd_LPSolverType
  m::Cdd_rowrange
  d::Cdd_colrange
  numbtype::Cdd_NumberType

  LPS::Cdd_LPStatusType
  # the current solution status
  optvalue::T
  # optimal value
  sol::Cdd_Arow{T}
  # primal solution
  dsol::Cdd_Arow{T}
  # dual solution
  nbindex::Cdd_colindex
  # current basis represented by nonbasic indices
  re::Cdd_rowrange
  # row index as a certificate in the case of inconsistency
  se::Cdd_colrange
  # col index as a certificate in the case of dual inconsistency
  pivots0::Clong
  pivots1::Clong
  pivots2::Clong
  pivots3::Clong
  pivots4::Clong
  # pivots[0]=setup (to find a basis), pivots[1]=PhaseI or Criss-Cross,
  # pivots[2]=Phase II, pivots[3]=Anticycling, pivots[4]=GMP postopt.
  total_pivots::Clong
end


type CDDLPData{T<:MyType}
  filename::Cdd_DataFileType
  objective::Cdd_LPObjectiveType
  solver::Cdd_LPSolverType
  Homogeneous::Cdd_boolean
  # The first column except for the obj row is all zeros.
  m::Cdd_rowrange
  d::Cdd_colrange
  A::Cdd_Amatrix{T}
  B::Cdd_Bmatrix{T}
  objrow::Cdd_rowrange
  rhscol::Cdd_colrange
  numbtype::Cdd_NumberType
  eqnumber::Cdd_rowrange
  # the number of equalities
  equalityset::Cdd_rowset

  redcheck_extensive::Cdd_boolean
  # Apply the extensive redundancy check.
  ired::Cdd_rowrange
  # the row index for the redundancy checking
  redset_extra::Cdd_rowset
  # a set of rows that are newly recognized redundan by the extensive search.
  redset_accum::Cdd_rowset
  # the accumulated set of rows that are recognized redundant
  posset_extra::Cdd_rowset
  # a set of rows that are recognized non-linearity

  lexicopivot::Cdd_boolean
  # flag to use the lexicogrphic pivot rule (symbolic perturbation).

  LPS::Cdd_LPStatusType
  # the current solution status
  m_alloc::Cdd_rowrange
  # the allocated row size of matrix A
  d_alloc::Cdd_colrange
  # the allocated col size of matrix A
  optvalue::T
  # optimal value
  sol::Cdd_Arow{T}
  # primal solution
  dsol::Cdd_Arow{T}
  # dual solution
  nbindex::Cdd_colindex
  # current basis represented by nonbasic indices
  re::Cdd_rowrange
  # row index as a certificate in the case of inconsistency
  se::Cdd_colrange
  #col index as a certificate in the case of dual inconsistency
  pivots0::Clong
  pivots1::Clong
  pivots2::Clong
  pivots3::Clong
  pivots4::Clong
  # pivots[0]=setup (to find a basis), pivots[1]=PhaseI or Criss-Cross,
  #  pivots[2]=Phase II, pivots[3]=Anticycling, pivots[4]=GMP postopt.
  total_pivots::Clong
  use_given_basis::Cint
  # switch to indicate the use of the given basis
  given_nbindex::Cdd_colindex
  # given basis represented by nonbasic indices
  starttime::Ctime_t
  endtime::Ctime_t
end

function dd_lpsolve(lp::Ptr{CDDLPData{Cdouble}}, solver::Cdd_LPSolverType)
  err = Ref{Cint}(0)
  found = (@cddf_ccall LPSolve Cint (Ptr{CDDLPData{Cdouble}}, Cdd_LPSolverType, Ref{Cint}) lp solver err)
  myerror(err[])
  found
end
function dd_lpsolve(lp::Ptr{CDDLPData{GMPRational}}, solver::Cdd_LPSolverType)
  err = Ref{Cint}(0)
  found = (@cdd_ccall LPSolve Cint (Ptr{CDDLPData{GMPRational}}, Cdd_LPSolverType, Ref{Cint}) lp solver err)
  myerror(err[])
  found
end

function dd_matrix2feasibility(matrix::Ptr{CDDMatrixData{Cdouble}})
  err = Ref{Cint}(0)
  lp = (@cddf_ccall Matrix2Feasibility Ptr{CDDLPData{Cdouble}} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cint}) matrix err)
  myerror(err[])
  lp
end
function dd_matrix2feasibility(matrix::Ptr{CDDMatrixData{GMPRational}})
  err = Ref{Cint}(0)
  lp = (@cdd_ccall Matrix2Feasibility Ptr{CDDLPData{GMPRational}} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cint}) matrix err)
  myerror(err[])
  lp
end

function dd_matrix2lp(matrix::Ptr{CDDMatrixData{Cdouble}})
  err = Ref{Cint}(0)
  lp = (@cddf_ccall Matrix2LP Ptr{CDDLPData{Cdouble}} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cint}) matrix err)
  myerror(err[])
  lp
end
function dd_matrix2lp(matrix::Ptr{CDDMatrixData{GMPRational}})
  err = Ref{Cint}(0)
  lp = (@cdd_ccall Matrix2LP Ptr{CDDLPData{GMPRational}} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cint}) matrix err)
  myerror(err[])
  lp
end

function dd_copylpsolution(lp::Ptr{CDDLPData{Cdouble}})
  @cddf_ccall CopyLPSolution Ptr{CDDLPSolutionData{Cdouble}} (Ptr{CDDLPData{Cdouble}},) lp
end
function dd_copylpsolution(lp::Ptr{CDDLPData{GMPRational}})
  @cdd_ccall CopyLPSolution Ptr{CDDLPSolutionData{GMPRational}} (Ptr{CDDLPData{GMPRational}},) lp
end

function dd_freelpdata(lp::Ptr{CDDLPData{Cdouble}})
  @cddf_ccall FreeLPData Void (Ptr{CDDLPData{Cdouble}},) lp
end
function dd_freelpdata(lp::Ptr{CDDLPData{GMPRational}})
  @cdd_ccall FreeLPData Void (Ptr{CDDLPData{GMPRational}},) lp
end

function dd_freelpsolution(lp::Ptr{CDDLPSolutionData{Cdouble}})
  @cddf_ccall FreeLPSolution Void (Ptr{CDDLPSolutionData{Cdouble}},) lp
end
function dd_freelpsolution(lp::Ptr{CDDLPSolutionData{GMPRational}})
  @cdd_ccall FreeLPSolution Void (Ptr{CDDLPSolutionData{GMPRational}},) lp
end

function Base.isempty{T<:MyType}(matrix::CDDInequalityMatrix{T})
  lp = dd_matrix2feasibility(matrix.matrix)
  found = Bool(dd_lpsolve(lp, dd_DualSimplex))
  if !found
    error("LP could not be solved")
  end
  empty = unsafe_load(lp).LPS != dd_Optimal
  dd_freelpdata(lp)
  empty
end
function Base.isempty{T<:Real}(ine::InequalityDescription{T})
  Base.isempty(CDDInequalityMatrix(ine))
end
