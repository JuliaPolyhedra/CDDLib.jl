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

function Base.push!(poly::CDDPolyhedra{T}, ine::CDDInequalityMatrix{T}) where {T<:PolyType}
    if !poly.inequality
        switchinputtype!(poly)
    end
    poly.poly = dd_inputappend(poly.poly, ine.matrix)
end

function Base.push!(poly::CDDPolyhedra{T}, ext::CDDGeneratorMatrix{T}) where {T<:PolyType}
    if poly.inequality
        switchinputtype!(poly)
    end
    poly.poly = dd_inputappend(poly.poly, ext.matrix)
end

function Base.push!(poly::CDDPolyhedra{T}, rep::Representation{S}) where {T,S}
    Base.push!(poly, cddmatrix(T, rep))
end

function dd_matrixappend(matrix1::Ptr{Cdd_MatrixData{Cdouble}}, matrix2::Ptr{Cdd_MatrixData{Cdouble}})
    @ddf_ccall MatrixAppend Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ptr{Cdd_MatrixData{Cdouble}}) matrix1 matrix2
end
function dd_matrixappend(matrix1::Ptr{Cdd_MatrixData{GMPRational}}, matrix2::Ptr{Cdd_MatrixData{GMPRational}})
    @dd_ccall MatrixAppend Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ptr{Cdd_MatrixData{GMPRational}}) matrix1 matrix2
end
function matrixappend(matrix1::CDDInequalityMatrix{T, S}, matrix2::CDDInequalityMatrix{T, S}) where {T, S}
    CDDInequalityMatrix{T, S}(dd_matrixappend(matrix1.matrix, matrix2.matrix))
end
function matrixappend(matrix1::CDDGeneratorMatrix{T, S}, matrix2::CDDGeneratorMatrix{T, S}) where {T, S}
    CDDGeneratorMatrix{T, S}(dd_matrixappend(matrix1.matrix, matrix2.matrix))
end
function matrixappend(matrix::CDDMatrix{T}, repr::Representation{S}) where {S, T}
    matrixappend(matrix, cddmatrix(T, repr))
end

# Redundant
function dd_redundant(matrix::Ptr{Cdd_MatrixData{Cdouble}}, i::Cdd_rowrange, len::Int)
    err = Ref{Cdd_ErrorType}(0)
    certificate = Vector{Cdouble}(undef, len)
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
    # myfree(certificateGMPRat)  # disabled due to https://github.com/JuliaPolyhedra/CDDLib.jl/issues/13
    (found, certificate)
end
function redundant(matrix::CDDMatrix, i::Integer)
    if dd_set_member(unsafe_load(matrix.matrix).linset, i)
        error("Redundancy check for equality not supported")
    end
    (found, certificate) = dd_redundant(matrix.matrix, Cdd_rowrange(i), fulldim(matrix)+1)
    # FIXME what is the meaning of the first element of the certificate ?
    (Bool(found), certificate[2:end])
end
function redundant(repr::Representation, i::Integer)
    redundant(CDDMatrix(repr), i)
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
    Base.convert(BitSet, CDDSet(dd_redundantrows(matrix.matrix), length(matrix)))
end
function redundantrows(repr::Representation)
    redundantrows(CDDMatrix(repr))
end

# Strictly redundant
function dd_sredundant(matrix::Ptr{Cdd_MatrixData{Cdouble}}, i::Cdd_rowrange, len::Int)
    err = Ref{Cdd_ErrorType}(0)
    certificate = Vector{Cdouble1}(undef, len)
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
    # myfree(certificateGMPRat)  # disabled due to https://github.com/JuliaPolyhedra/CDDLib.jl/issues/13
    (found, certificate)
end
function sredundant(matrix::CDDMatrix, i::Integer)
    if dd_set_member(unsafe_load(matrix.matrix).linset, i)
        error("Redundancy check for equality not supported")
    end
    (found, certificate) = dd_sredundant(matrix.matrix, Cdd_rowrange(i), fulldim(matrix)+1)
    # FIXME what is the meaning of the first element of the certificate ? 1 for point, 0 for ray ?
    (Bool(found), certificate[2:end])
end
function sredundant(repr::Representation, i::Integer)
    sredundant(CDDMatrix(repr), i)
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
    iszero(length(matrix)) && return # See https://github.com/JuliaPolyhedra/CDDLib.jl/issues/24
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
    (found, matptr[], redset[], newpos[])
end
function redundancyremove!(matrix::CDDMatrix)
    (found, matrix.matrix, redset, newpos) = dd_matrixredundancyremove(matrix.matrix)
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
function fourierelimination(matrix::CDDInequalityMatrix{T, S}) where {T, S}
    CDDInequalityMatrix{T, S}(dd_fourierelimination(matrix.matrix))
end
function fourierelimination(ine::HRepresentation)
    fourierelimination(CDDInequalityMatrix(ine))
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
function blockelimination(matrix::CDDInequalityMatrix{T, S}, delset=BitSet([fulldim(matrix)])) where {T, S}
    if last(delset) > fulldim(matrix)
        error("Invalid variable to eliminate")
    end
    # offset of 1 because 1 is for the first column of the matrix
    # (indicating the linearity) so 2 is the first dimension
    CDDInequalityMatrix{T, S}(dd_blockelimination(matrix.matrix, CDDSet(delset, fulldim(matrix)+1, 1).s))
end
function blockelimination(ine::HRepresentation, delset=BitSet([fulldim(ine)]))
    blockelimination(Base.convert(CDDInequalityMatrix, ine), delset)
end

export redundant, redundantrows, sredundant, fourierelimination, blockelimination, canonicalize!, redundancyremove!
