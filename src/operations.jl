function dd_inputappend(poly::Ptr{Cdd_PolyhedraData{Cdouble}}, matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  polyptr = Ref{Ptr{Cdd_PolyhedraData{Cdouble}}}(poly)
  found = (@ddf_ccall DDInputAppend Cdd_boolean (Ref{Ptr{Cdd_PolyhedraData{Cdouble}}}, Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) polyptr matrix err)
  myerror(err[])
  if !Bool(found)
    println("Double description not found")
  end
  polyptr[]
end

function dd_inputappend(poly::Ptr{Cdd_PolyhedraData{GMPRational}}, matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  polyptr = Ref{Ptr{Cdd_PolyhedraData{GMPRational}}}(poly)
  found = (@dd_ccall DDInputAppend Cdd_boolean (Ref{Ptr{Cdd_PolyhedraData{GMPRational}}}, Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) polyptr matrix err)
  myerror(err[])
  if !Bool(found)
    println("Double description not found") # FIXME
  end
  polyptr[]
end

function Base.push!{N, T<:MyType}(poly::CDDPolyhedra{N, T}, ine::CDDInequalityMatrix{N, T})
  if !poly.inequality
    switchinputtype!(poly)
  end
  poly.poly = dd_inputappend(poly.poly, ine.matrix)
end

function Base.push!{N, T<:MyType}(poly::CDDPolyhedra{N, T}, ext::CDDGeneratorMatrix{N, T})
  if poly.inequality
    switchinputtype!(poly)
  end
  poly.poly = dd_inputappend(poly.poly, ext.matrix)
end

function Base.push!{N, T<:MyType,S<:Real}(poly::CDDPolyhedra{N, T}, repr::Representation{S})
  Base.push!(poly, convert(CDDMatrix{N, T}, repr))
end

function dd_matrixappend(matrix1::Ptr{Cdd_MatrixData{Cdouble}}, matrix2::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall MatrixAppend Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ptr{Cdd_MatrixData{Cdouble}}) matrix1 matrix2
end
function dd_matrixappend(matrix1::Ptr{Cdd_MatrixData{GMPRational}}, matrix2::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall MatrixAppend Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ptr{Cdd_MatrixData{GMPRational}}) matrix1 matrix2
end
function matrixappend{N, T}(matrix1::CDDInequalityMatrix{N, T}, matrix2::CDDInequalityMatrix{N, T})
  CDDInequalityMatrix{N, T}(dd_matrixappend(matrix1.matrix, matrix2.matrix))
end
function matrixappend{N, T}(matrix1::CDDGeneratorMatrix{N, T}, matrix2::CDDGeneratorMatrix{N, T})
  CDDGeneratorMatrix{N, T}(dd_matrixappend(matrix1.matrix, matrix2.matrix))
end
function matrixappend{N, S, T}(matrix::CDDMatrix{N, T}, repr::Representation{S})
  matrixappend(matrix, convert(CDDMatrix{N, T}, repr))
end

# Redundant
function dd_redundant(matrix::Ptr{Cdd_MatrixData{Cdouble}}, i::Cdd_rowrange, len::Int)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(len)
  found = (@ddf_ccall Redundant Cdd_boolean (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_redundant(matrix::Ptr{Cdd_MatrixData{GMPRational}}, i::Cdd_rowrange, len::Int)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, len)
  found = (@dd_ccall Redundant Cdd_boolean (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix i certificateGMPRat err)
  myerror(err[])
  certificate = Array{Rational{BigInt}}(certificateGMPRat)
  myfree(certificateGMPRat)
  (found, certificate)
end
function redundant(matrix::CDDMatrix, i::Integer)
  if dd_set_member(unsafe_load(matrix.matrix).linset, i)
    error("Redundancy check for equality not supported")
  end
  (found, certificate) = dd_redundant(matrix.matrix, Cdd_rowrange(i), size(matrix, 2))
  # FIXME what is the meaning of the first element of the certificate ?
  (Bool(found), certificate[2:end])
end
function redundant{S<:Real}(repr::Representation{S}, i::Integer)
  redundant(Base.convert(CDDMatrix, repr), i)
end

# Redundant rows
function dd_redundantrows(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  redundant_list = (@ddf_ccall RedundantRows Ptr{Culong} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  redundant_list
end
function dd_redundantrows(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  redundant_list = (@dd_ccall RedundantRows Ptr{Culong} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  redundant_list
end
function redundantrows(matrix::CDDMatrix)
  Base.convert(IntSet, CDDSet(dd_redundantrows(matrix.matrix), size(matrix, 1)))
end
function redundantrows(repr::Representation)
  redundantrows(Base.convert(CDDMatrix, repr))
end

# Strictly redundant
function dd_sredundant(matrix::Ptr{Cdd_MatrixData{Cdouble}}, i::Cdd_rowrange, len::Int)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(len)
  found = (@ddf_ccall SRedundant Cdd_boolean (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_sredundant(matrix::Ptr{Cdd_MatrixData{GMPRational}}, i::Cdd_rowrange, len::Int)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, len)
  found = (@dd_ccall SRedundant Cdd_boolean (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix i certificateGMPRat err)
  myerror(err[])
  certificate = Array{Rational{BigInt}}(certificateGMPRat)
  myfree(certificateGMPRat)
  (found, certificate)
end
function sredundant(matrix::CDDMatrix, i::Integer)
  if dd_set_member(unsafe_load(matrix.matrix).linset, i)
    error("Redundancy check for equality not supported")
  end
  (found, certificate) = dd_sredundant(matrix.matrix, Cdd_rowrange(i), size(matrix, 2))
  # FIXME what is the meaning of the first element of the certificate ? 1 for point, 0 for ray ?
  (Bool(found), certificate[2:end])
end
function sredundant(repr::Representation, i::Integer)
  sredundant(Base.convert(CDDMatrix, repr), i)
end

function dd_matrixcanonicalize(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  matptr = Ref{Ptr{Cdd_MatrixData{Cdouble}}}(matrix)
  impl_linset = Ref{Cdd_rowset}(0)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@ddf_ccall MatrixCanonicalize Cdd_boolean (Ref{Ptr{Cdd_MatrixData{Cdouble}}}, Ref{Cdd_rowset}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr impl_linset redset newpos err)
  myerror(err[])
  (found, matptr[], impl_linset[], redset[], newpos[])
end
function dd_matrixcanonicalize(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  matptr = Ref{Ptr{Cdd_MatrixData{GMPRational}}}(matrix)
  impl_linset = Ref{Cdd_rowset}(0)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@dd_ccall MatrixCanonicalize Cdd_boolean (Ref{Ptr{Cdd_MatrixData{GMPRational}}}, Ref{Cdd_rowset}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr impl_linset redset newpos err)
  myerror(err[])
  (found, matptr[], impl_linset[], redset[], newpos[])
end
function canonicalize!(matrix::CDDMatrix)
  (found, matrix.matrix, impl_linset, redset, newpos) = dd_matrixcanonicalize(matrix.matrix)
  if !Bool(found)
    error("Canonicalization not found")
  end
  (impl_linset, redset, newpos) # TODO transform and free
end

function dd_matrixcanonicalizelinearity(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  matptr = Ref{Ptr{Cdd_MatrixData{Cdouble}}}(matrix)
  impl_linset = Ref{Cdd_rowset}(0)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@ddf_ccall MatrixCanonicalizeLinearity Cdd_boolean (Ref{Ptr{Cdd_MatrixData{Cdouble}}}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr impl_linset newpos err)
  myerror(err[])
  (found, matptr[], impl_linset[], newpos[])
end
function dd_matrixcanonicalizelinearity(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  matptr = Ref{Ptr{Cdd_MatrixData{GMPRational}}}(matrix)
  impl_linset = Ref{Cdd_rowset}(0)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@dd_ccall MatrixCanonicalizeLinearity Cdd_boolean (Ref{Ptr{Cdd_MatrixData{GMPRational}}}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr impl_linset newpos err)
  myerror(err[])
  (found, matptr[], impl_linset[], newpos[])
end
function canonicalizelinearity!(matrix::CDDMatrix)
  (found, matrix.matrix, impl_linset, newpos) = dd_matrixcanonicalizelinearity(matrix.matrix)
  if !Bool(found)
    error("Linearity canonicalization not found")
  end
  (impl_linset, newpos) # TODO transform and free
end

function dd_matrixredundancyremove(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  matptr = Ref{Ptr{Cdd_MatrixData{Cdouble}}}(matrix)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@ddf_ccall MatrixRedundancyRemove Cdd_boolean (Ref{Ptr{Cdd_MatrixData{Cdouble}}}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr redset newpos err)
  myerror(err[])
  (found, matptr[], redset[], newpos[])
end
function dd_matrixredundancyremove(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  matptr = Ref{Ptr{Cdd_MatrixData{GMPRational}}}(matrix)
  redset = Ref{Cdd_rowset}(0)
  newpos = Ref{Cdd_rowindex}(0)
  err = Ref{Cdd_ErrorType}(0)
  found = (@dd_ccall MatrixRedundancyRemove Cdd_boolean (Ref{Ptr{Cdd_MatrixData{GMPRational}}}, Ref{Cdd_rowset}, Ref{Cdd_rowindex}, Ref{Cdd_ErrorType}) matptr redset newpos err)
  myerror(err[])
  println(matptr[])
  (found, matptr[], redset[], newpos[])
end
function redundancyremove!(matrix::CDDMatrix)
  println("before $(matrix.matrix)")
  (found, matrix.matrix, redset, newpos) = dd_matrixredundancyremove(matrix.matrix)
  println("after $(matrix.matrix)")
  if !Bool(found)
    error("Redundancy removal not found")
  end
  (redset, newpos) # TODO transform and free
end

# Fourier Elimination

function dd_fourierelimination(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@ddf_ccall FourierElimination Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  newmatrix
end
function dd_fourierelimination(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@dd_ccall FourierElimination Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  newmatrix
end
function fourierelimination{N, T}(matrix::CDDInequalityMatrix{N, T})
  CDDInequalityMatrix{N-1, T}(dd_fourierelimination(matrix.matrix))
end
function fourierelimination(ine::HRepresentation)
  fourierelimination(Base.convert(CDDInequalityMatrix, ine))
end

# Block Elimination

function dd_blockelimination(matrix::Ptr{Cdd_MatrixData{Cdouble}}, delset::Cdd_colset)
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@ddf_ccall BlockElimination Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_colset, Ref{Cdd_ErrorType}) matrix delset err)
  myerror(err[])
  newmatrix
end
function dd_blockelimination(matrix::Ptr{Cdd_MatrixData{GMPRational}}, delset::Cdd_colset)
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@dd_ccall BlockElimination Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_colset, Ref{Cdd_ErrorType}) matrix delset err)
  myerror(err[])
  newmatrix
end
function blockelimination{N, T}(matrix::CDDInequalityMatrix{N, T}, delset::IntSet=IntSet([N]))
  if last(delset) > N
    error("Invalid variable to eliminate")
  end
  # offset of 1 because 1 is for the first column of the matrix
  # (indicating the linearity) so 2 is the first dimension
  CDDInequalityMatrix{N-length(delset), T}(dd_blockelimination(matrix.matrix, CDDSet(delset, N+1, 1).s))
end
function blockelimination(ine::HRepresentation, delset::IntSet=IntSet([fulldim(ine)]))
  blockelimination(Base.convert(CDDInequalityMatrix, ine), delset)
end

export redundant, redundantrows, sredundant, fourierelimination, blockelimination, canonicalize!, redundancyremove!
