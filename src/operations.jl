function dd_inputappend(poly::CDDPolyhedra{Cdouble}, matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  polyptr = Ref{Ptr{Cdd_PolyhedraData{Cdouble}}}(poly.poly)
  found = (@ddf_ccall DDInputAppend Cdd_boolean (Ref{Ptr{Cdd_PolyhedraData{Cdouble}}}, Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) polyptr matrix err)
  poly.poly = polyptr[]
  myerror(err[])
  if !Bool(found)
    println("Double description not found")
  end
end

function dd_inputappend(poly::CDDPolyhedra{GMPRational}, matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  polyptr = Ref{Ptr{Cdd_PolyhedraData{GMPRational}}}(poly.poly)
  found = (@dd_ccall DDInputAppend Cdd_boolean (Ref{Ptr{Cdd_PolyhedraData{GMPRational}}}, Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) polyptr matrix err)
  poly.poly = polyptr[]
  myerror(err[])
  if !Bool(found)
    println("Double description not found") # FIXME
  end
end

function Base.push!{T<:MyType}(poly::CDDPolyhedra{T}, ine::CDDInequalityMatrix{T})
  if !poly.inequality
    switchinputtype!(poly)
  end
  dd_inputappend(poly, ine.matrix)
end

function Base.push!{T<:MyType}(poly::CDDPolyhedra{T}, ext::CDDGeneratorMatrix{T})
  if poly.inequality
    switchinputtype!(poly)
  end
  dd_inputappend(poly, ext.matrix)
end

function Base.push!{T<:MyType,S<:Real}(poly::CDDPolyhedra{T}, desc::Description{S})
  Base.push!(poly, convert(CDDMatrix{T}, desc))
end

# Redundant
function dd_redundant(matrix::CDDMatrix{Cdouble}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(size(matrix, 2))
  found = (@ddf_ccall Redundant Cdd_boolean (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_redundant(matrix::CDDMatrix{GMPRational}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, size(matrix, 2))
  found = (@dd_ccall Redundant Cdd_boolean (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix.matrix i certificateGMPRat err)
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
  redundant_list = (@ddf_ccall RedundantRows Ptr{Culong} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  redundant_list
end
function dd_redundantrows(matrix::CDDMatrix{GMPRational})
  err = Ref{Cdd_ErrorType}(0)
  redundant_list = (@dd_ccall RedundantRows Ptr{Culong} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  redundant_list
end
function redundantrows{T<:MyType}(matrix::CDDMatrix{T})
  Base.convert(IntSet, CDDSet(dd_redundantrows(matrix), size(matrix, 2)))
end
function redundantrows{S<:Real}(desc::Description{S})
  redundantrows(Base.convert(CDDMatrix, desc))
end

# Strictly redundant
function dd_sredundant(matrix::CDDMatrix{Cdouble}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificate = Array{Cdouble, 1}(size(matrix, 2))
  found = (@ddf_ccall SRedundant Cdd_boolean (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_rowrange, Ptr{Cdouble}, Ref{Cdd_ErrorType}) matrix.matrix  i certificate err)
  myerror(err[])
  (found, certificate)
end
function dd_sredundant(matrix::CDDMatrix{GMPRational}, i::Cdd_rowrange)
  err = Ref{Cdd_ErrorType}(0)
  certificateGMPRat = zeros(GMPRational, size(matrix, 2))
  found = (@dd_ccall SRedundant Cdd_boolean (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_rowrange, Ptr{GMPRational}, Ref{Cdd_ErrorType}) matrix.matrix i certificateGMPRat err)
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
function canonicalize!{T<:MyType}(matrix::CDDMatrix{T})
  (found, matrix.matrix, impl_linset, redset, newpos) = dd_matrixcanonicalize(matrix.matrix)
  if !Bool(found)
    error("Redundancy removal not found")
  end
  (impl_linset, redset, newpos) # TODO transform and free
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
function redundancyremove!{T<:MyType}(matrix::CDDMatrix{T})
  println("before $(matrix.matrix)")
  (found, matrix.matrix, redset, newpos) = dd_matrixredundancyremove(matrix.matrix)
  println("after $(matrix.matrix)")
  if !Bool(found)
    error("Redundancy removal not found")
  end
  (redset, newpos) # TODO transform and free
end

# Fourier Elimination

function dd_fourierelimination(matrix::CDDInequalityMatrix{Cdouble})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@ddf_ccall FourierElimination Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  CDDInequalityMatrix{Cdouble}(newmatrix)
end
function dd_fourierelimination(matrix::CDDInequalityMatrix{GMPRational})
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@dd_ccall FourierElimination Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix.matrix err)
  myerror(err[])
  CDDInequalityMatrix{GMPRational}(newmatrix)
end
function fourierelimination{T<:MyType}(matrix::CDDInequalityMatrix{T})
  dd_fourierelimination(matrix)
end
function fourierelimination{S<:Real}(ine::InequalityDescription{S})
  fourierelimination(Base.convert(CDDInequalityMatrix, ine))
end

# Block Elimination

function dd_blockelimination(matrix::CDDInequalityMatrix{Cdouble}, delset::Cdd_colset)
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@ddf_ccall BlockElimination Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_colset, Ref{Cdd_ErrorType}) matrix.matrix delset err)
  myerror(err[])
  CDDInequalityMatrix{Cdouble}(newmatrix)
end
function dd_blockelimination(matrix::CDDInequalityMatrix{GMPRational}, delset::Cdd_colset)
  err = Ref{Cdd_ErrorType}(0)
  newmatrix = (@dd_ccall BlockElimination Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_colset, Ref{Cdd_ErrorType}) matrix.matrix delset err)
  myerror(err[])
  CDDInequalityMatrix{GMPRational}(newmatrix)
end
function blockelimination{T<:MyType}(matrix::CDDInequalityMatrix{T}, delset::IntSet=IntSet([size(matrix, 2)]))
  dd_blockelimination(matrix, CDDSet(delset, size(matrix, 2)).s)
end
function blockelimination{S<:Real}(ine::InequalityDescription{S}, delset::IntSet=IntSet([size(ine.A, 2)]))
  blockelimination(Base.convert(CDDInequalityMatrix, ine), delset)
end

export redundant, redundantrows, sredundant, fourierelimination, blockelimination, canonicalize!, redundancyremove!
