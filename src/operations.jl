function dd_inputappend(poly::Ptr{CDDPolyhedraData{Cdouble}}, matrix::Ptr{CDDMatrixData{Cdouble}})
  err = Ref{Cint}(0)
  found = (@cddf_ccall DDInputAppend Cint (Ptr{CDDPolyhedraData{Cdouble}}, Ptr{CDDMatrixData{Cdouble}}, Ref{Cint}) poly matrix err)
  myerror(err[])
  if !found
    warning("Double description not found")
  end
end

function dd_inputappend(poly::Ptr{CDDPolyhedraData{GMPRational}}, matrix::Ptr{CDDMatrixData{GMPRational}})
  err = Ref{Cint}(0)
  found = (@cdd_ccall DDInputAppend Cint (Ptr{CDDPolyhedraData{GMPRational}}, Ptr{CDDMatrixData{GMPRational}}, Ref{Cint}) poly matrix err)
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
function dd_redundant(matrix::CDDMatrix{Cdouble}, i::Clong)
  err = Ref{Cint}(0)
  certificate = Array{Cdouble, 1}(unsafe_load(matrix.matrix).colsize)
  found = (@cddf_ccall Redundant Cint (Ptr{CDDMatrixData{Cdouble}}, Clong, Ptr{Cdouble}, Ref{Cint}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_redundant(matrix::CDDMatrix{GMPRational}, i::Clong)
  err = Ref{Cint}(0)
  certificate = zeros(GMPRational, unsafe_load(matrix.matrix).colsize)
  found = (@cdd_ccall Redundant Cint (Ptr{CDDMatrixData{GMPRational}}, Clong, Ptr{GMPRational}, Ref{Cint}) matrix.matrix i certificate err)
  myerror(err[])
  (found, certificate)
end
function redundant{T<:MyType}(matrix::CDDMatrix{T}, i::Integer)
  (found, certificate) = dd_redundant(matrix, Clong(i))
  # FIXME what is the meaning of the first element of the certificate ?
  (Bool(found), certificate)
end
function redundant{S<:Real}(desc::Description{S}, i::Integer)
  redundant(Base.convert(CDDMatrix, desc), i)
end

# Redundant rows
function dd_redundantrows(matrix::CDDMatrix{Cdouble})
  err = Ref{Cint}(0)
  redundant_list = (@cddf_ccall RedundantRows Ptr{Culong} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cint}) matrix.matrix err)
  myerror(err[])
  redundant_list
end
function dd_redundantrows(matrix::CDDMatrix{GMPRational})
  err = Ref{Cint}(0)
  redundant_list = (@cdd_ccall RedundantRows Ptr{Culong} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cint}) matrix.matrix err)
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
function dd_sredundant(matrix::CDDMatrix{Cdouble}, i::Clong)
  err = Ref{Cint}(0)
  certificate = Array{Cdouble, 1}(unsafe_load(matrix.matrix).colsize)
  found = (@cddf_ccall SRedundant Cint (Ptr{CDDMatrixData{Cdouble}}, Clong, Ptr{Cdouble}, Ref{Cint}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_sredundant(matrix::CDDMatrix{GMPRational}, i::Clong)
  err = Ref{Cint}(0)
  certificate = zeros(GMPRational, unsafe_load(matrix.matrix).colsize)
  found = (@cdd_ccall SRedundant Cint (Ptr{CDDMatrixData{GMPRational}}, Clong, Ptr{GMPRational}, Ref{Cint}) matrix.matrix i certificate err)
  myerror(err[])
  (found, certificate)
end
function sredundant{T<:MyType}(matrix::CDDMatrix{T}, i::Integer)
  (found, certificate) = dd_sredundant(matrix, Clong(i))
  # FIXME what is the meaning of the first element of the certificate ?
  (Bool(found), certificate)
end
function sredundant{S<:Real}(desc::Description{S}, i::Integer)
  sredundant(Base.convert(CDDMatrix, desc), i)
end

# Fourier Elimination

function dd_fourierelimination(matrix::CDDInequalityMatrix{Cdouble})
  err = Ref{Cint}(0)
  newmatrix = (@cddf_ccall FourierElimination Ptr{CDDMatrixData{Cdouble}} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cint}) matrix.matrix err)
  myerror(err[])
  CDDInequalityMatrix{Cdouble}(newmatrix)
end
function dd_fourierelimination(matrix::CDDInequalityMatrix{GMPRational})
  err = Ref{Cint}(0)
  newmatrix = (@cddf_ccall FourierElimination Ptr{CDDMatrixData{GMPRational}} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cint}) matrix.matrix err)
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
