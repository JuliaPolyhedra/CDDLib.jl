import Base.isempty

type CDDLPData{T<:MyType}
  # Not needed
end

function dd_lpsolve(lp::Ptr{CDDLPData{Cdouble}})
  err = Ref{Cint}(0)
  found = (@cddf_ccall LPSolve Cint (Ptr{CDDLPData{Cdouble}}, Cint, Ref{Cint}) lp 1 err)
  myerror(err[])
  found
end
function dd_lpsolve(lp::Ptr{CDDLPData{GMPRational}})
  err = Ref{Cint}(0)
  found = (@cdd_ccall LPSolve Cint (Ptr{CDDLPData{GMPRational}}, Cint, Ref{Cint}) lp 1 err)
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

function Base.isempty{T<:MyType}(matrix::CDDInequalityMatrix{T})
  !Bool(dd_lpsolve(dd_matrix2feasibility(matrix.matrix)))
end
function Base.isempty{T<:Real}(ine::InequalityDescription{T})
  Base.isempty(CDDInequalityMatrix(ine))
end
