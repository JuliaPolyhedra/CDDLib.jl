function dd_inputappend(poly::Ptr{CDDPolyhedraData{Cdouble}}, matrix::Ptr{CDDMatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  found = (@cddf_ccall DDInputAppend Cdd_Boolean (Ptr{CDDPolyhedraData{Cdouble}}, Ptr{CDDMatrixData{Cdouble}}, Ref{Cdd_ErrorType}) poly matrix err)
  myerror(err[])
  if !found
    warning("Double description not found")
  end
end

function dd_inputappend(poly::Ptr{CDDPolyhedraData{GMPRational}}, matrix::Ptr{CDDMatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  found = (@cdd_ccall DDInputAppend Cdd_Boolean (Ptr{CDDPolyhedraData{GMPRational}}, Ptr{CDDMatrixData{GMPRational}}, Ref{Cdd_ErrorType}) poly matrix err)
  myerror(err[])
  if !found
    warning("Double description not found")
  end
end

function Base.push!{T<:MyType}(poly::CDDPolyhedra{T}, ine::CDDInequalityMatrix{T})
  if !poly.inequality
    switchinputtype!(poly)
  end
  dd_inputappend(poly.poly, ine.matrix)
end

function Base.push!{T<:MyType}(poly::CDDPolyhedra{T}, ext::CDDGeneratorMatrix{T})
  if poly.inequality
    switchinputtype!(poly)
  end
  dd_inputappend(poly.poly, ext.matrix)
end

function Base.push!{T<:MyType,S<:Real}(poly::CDDPolyhedra{T}, desc::Description{S})
  Base.push!(poly, convert(CDDMatrix{T}, desc))
end

# Redundant
function dd_redundant(matrix::CDDMatrix{Cdouble}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(unsafe_load(matrix.matrix).colsize)
  found = (@cddf_ccall Redundant Cdd_boolean (Ptr{CDDMatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_redundant(matrix::CDDMatrix{GMPRational}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, unsafe_load(matrix.matrix).colsize)
  found = (@cdd_ccall Redundant Cdd_boolean (Ptr{CDDMatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix.matrix i certificateGMPRat err)
  myerror(err[])
  certificate = Array{Rational{BigInt}}(certificateGMPRat)
  myfree(certificateGMPRat)
  (found, certificate)
end
function redundant{T<:MyType}(matrix::CDDMatrix{T}, i::Integer)
  if dd_set_member(unsafe_load(matrix.matrix).linset, i)
    error("Redundancy check for equality not supported")
  end
  (found, certificate) = dd_redundant(matrix, Cdd_rowrange(i))
  # FIXME what is the meaning of the first element of the certificate ?
  (Bool(found), certificate)
end
function redundant{S<:Real}(desc::Description{S}, i::Integer)
  redundant(Base.convert(CDDMatrix, desc), i)
end

# Redundant rows
function dd_redundantrows(matrix::CDDMatrix{Cdouble})
  err = Ref{Cdd_ErrorType}(0)
  redundant_list = (@cddf_ccall RedundantRows Ptr{Culong} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  redundant_list
end
function dd_redundantrows(matrix::CDDMatrix{GMPRational})
  err = Ref{Cdd_ErrorType}(0)
  redundant_list = (@cdd_ccall RedundantRows Ptr{Culong} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  redundant_list
end
function redundantrows{T<:MyType}(matrix::CDDMatrix{T})
  Base.convert(IntSet, CDDSet(dd_redundantrows(matrix), size(matrix, 1)))
end
function redundantrows{S<:Real}(desc::Description{S})
  redundantrows(Base.convert(CDDMatrix, desc))
end

# Strictly redundant
function dd_sredundant(matrix::CDDMatrix{Cdouble}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(unsafe_load(matrix.matrix).colsize)
  found = (@cddf_ccall SRedundant Cdd_boolean (Ptr{CDDMatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_sredundant(matrix::CDDMatrix{GMPRational}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, unsafe_load(matrix.matrix).colsize)
  found = (@cdd_ccall SRedundant Cdd_boolean (Ptr{CDDMatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix.matrix i certificateGMPRat err)
  myerror(err[])
  certificate = Array{Rational{BigInt}}(certificateGMPRat)
  myfree(certificateGMPRat)
  (found, certificate)
end
function sredundant{T<:MyType}(matrix::CDDMatrix{T}, i::Integer)
  if dd_set_member(unsafe_load(matrix.matrix).linset, i)
    error("Redundancy check for equality not supported")
  end
  (found, certificate) = dd_sredundant(matrix, Cdd_rowrange(i))
  # FIXME what is the meaning of the first element of the certificate ? 1 for point, 0 for ray ?
  (Bool(found), certificate)
end
function sredundant{S<:Real}(desc::Description{S}, i::Integer)
  sredundant(Base.convert(CDDMatrix, desc), i)
end

# Fourier Elimination

function dd_fourierelimination(matrix::CDDInequalityMatrix{Cdouble})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@cddf_ccall FourierElimination Ptr{CDDMatrixData{Cdouble}} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  CDDInequalityMatrix{Cdouble}(newmatrix)
end
function dd_fourierelimination(matrix::CDDInequalityMatrix{GMPRational})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@cddf_ccall FourierElimination Ptr{CDDMatrixData{GMPRational}} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  CDDInequalityMatrix{GMPRational}(newmatrix)
end
function fourierelimination{T<:MyType}(matrix::CDDInequalityMatrix{T})
  dd_fourierelimination(matrix)
end
function fourierelimination{S<:Real}(ine::InequalityDescription{S})
  fourierelimination(Base.convert(CDDInequalityMatrix, ine))
end

export redundant, redundantrows, sredundant
