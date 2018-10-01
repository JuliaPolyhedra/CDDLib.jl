mutable struct Cdd_MatrixData{T <: MyType}
    rowsize::Cdd_rowrange
    linset::Cdd_rowset
    colsize::Cdd_colrange
    representation::Cdd_RepresentationType
    numbtype::Cdd_NumberType
    matrix::Ptr{Ptr{T}}
    objective::Cdd_LPObjectiveType
    rowvec::Ptr{T}
end

function dd_creatematrix(::Type{Cdouble}, m::Cdd_rowrange, n::Cdd_colrange)
    @ddf_ccall CreateMatrix Ptr{Cdd_MatrixData{Cdouble}} (Cdd_rowrange, Cdd_colrange) m n
end
function dd_creatematrix(::Type{GMPRational}, m::Cdd_rowrange, n::Cdd_colrange)
    @dd_ccall CreateMatrix Ptr{Cdd_MatrixData{GMPRational}} (Cdd_rowrange, Cdd_colrange) m n
end

# function dd_copyAmatrixvectorizedbycolumn(mat::Cdd_Amatrix{Cdouble}, M::Matrix{Cdouble}, m::Cdd_rowrange, n::Cdd_colrange)
#   @ddf_ccall CopyAmatrixVectorizedByColumn Nothing (Cdd_Amatrix{Cdouble}, Ptr{Cdouble}, Cdd_rowrange, Cdd_colrange) mat M m n
# end
# function dd_copyAmatrixvectorizedbycolumn(mat::Cdd_Amatrix{GMPRational}, M::Matrix{GMPRational}, m::Cdd_rowrange, n::Cdd_colrange)
#   @dd_ccall CopyAmatrixVectorizedByColumn Nothing (Cdd_Amatrix{GMPRational}, Ptr{GMPRational}, Cdd_rowrange, Cdd_colrange) mat M m n
# end

function dd_copyArow(acopy::Cdd_Arow{Cdouble}, a::Vector{Cdouble})
    @ddf_ccall CopyArow Nothing (Cdd_Arow{Cdouble}, Cdd_Arow{Cdouble}, Cdd_colrange) acopy a length(a)
end
function dd_copyArow(acopy::Cdd_Arow{GMPRational}, a::Vector{Rational{BigInt}})
    b = Vector{GMPRational}(a)
    @dd_ccall CopyArow Nothing (Cdd_Arow{GMPRational}, Cdd_Arow{GMPRational}, Cdd_colrange) acopy b length(b)
    myfree(b)
end

dd_copyArow(acopy::Cdd_Arow, a::AbstractVector) = dd_copyArow(acopy, collect(a)) # e.g. for sparse a

function dd_setmatrixobjective(matrix::Ptr{Cdd_MatrixData{Cdouble}}, objective::Cdd_LPObjectiveType)
    @ddf_ccall SetMatrixObjective Nothing (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_LPObjectiveType) matrix objective
end
function dd_setmatrixobjective(matrix::Ptr{Cdd_MatrixData{GMPRational}}, objective::Cdd_LPObjectiveType)
    @dd_ccall SetMatrixObjective Nothing (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_LPObjectiveType) matrix objective
end

function dd_setmatrixnumbertype(matrix::Ptr{Cdd_MatrixData{Cdouble}})
    @ddf_ccall SetMatrixNumberType Nothing (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_NumberType) matrix dd_Real
end
function dd_setmatrixnumbertype(matrix::Ptr{Cdd_MatrixData{GMPRational}})
    @dd_ccall SetMatrixNumberType Nothing (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_NumberType) matrix dd_Rational
end

function dd_setmatrixrepresentationtype(matrix::Ptr{Cdd_MatrixData{Cdouble}}, inequality::Bool)
    @ddf_ccall SetMatrixRepresentationType Nothing (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_RepresentationType) matrix (inequality ? dd_Inequality : dd_Generator)
end
function dd_setmatrixrepresentationtype(matrix::Ptr{Cdd_MatrixData{GMPRational}}, inequality::Bool)
    @dd_ccall SetMatrixRepresentationType Nothing (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_RepresentationType) matrix (inequality ? dd_Inequality : dd_Generator)
end

function dd_matrixcopy(matrix::Ptr{Cdd_MatrixData{Cdouble}})
    @ddf_ccall MatrixCopy Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_matrixcopy(matrix::Ptr{Cdd_MatrixData{GMPRational}})
    @dd_ccall MatrixCopy Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end

function fillmatrix(inequality::Bool, matrix::Ptr{Ptr{T}}, itr, linset::BitSet, offset) where T
    for (i, item) in enumerate(itr)
        row = unsafe_load(matrix, offset+i)
        if islin(item)
            push!(linset, offset + i)
        end
        # CDD is expected <a, x> >= 0 but Polyhedra uses <a, x> <= 0
        a = vec(coord(lift(item)))
        dd_copyArow(row, inequality ? -a : a)
    end
end

# If ElemIt contains AbstractVector{T}, we cannot infer FullDim so we add both as argument
function initmatrix(d::Polyhedra.FullDim, ::Type{T}, inequality::Bool, itr::Polyhedra.ElemIt...) where {T}
    n = fulldim(d)+1
    cs = cumsum(collect(length.(itr))) # cumsum not defined for tuple :(
    m = cs[end]
    offset = [0; cs[1:end-1]]
    matrix = dd_creatematrix(mytype(T), Cdd_rowrange(m), Cdd_colrange(n))
    mat = unsafe_load(matrix)
    linset = BitSet()
    fillmatrix.(inequality, mat.matrix, itr, Ref(linset), offset)
    dd_settype(mat.linset, linset)
    dd_setmatrixnumbertype(matrix)
    dd_setmatrixrepresentationtype(matrix, inequality)
    matrix
end

# Representation

mutable struct CDDInequalityMatrix{T <: PolyType, S <: MyType} <: Polyhedra.MixedHRep{T}
    matrix::Ptr{Cdd_MatrixData{S}}

    function CDDInequalityMatrix{T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {T <: PolyType, S <: MyType}
        @assert polytype(S) == T
        m = new{T, S}(matrix)
        finalizer(myfree, m)
        m
    end

end

mutable struct CDDGeneratorMatrix{T <: PolyType, S <: MyType} <: Polyhedra.MixedVRep{T}
    matrix::Ptr{Cdd_MatrixData{S}}
    cone::Bool # If true, CDD will not return any point so we need to add the origin

    function CDDGeneratorMatrix{T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {T <: PolyType, S <: MyType}
        @assert polytype(S) == T
        cone = !iszero(_length(matrix)) # If there is no ray and no point, it is empty so we should not add the origin
        for i in 1:_length(matrix)
            if isrowpoint(matrix, i, T)
                cone = false
                break
            end
        end
        m = new{T, S}(matrix, cone)
        finalizer(myfree, m)
        m
    end
end

const CDDMatrix{T, S} = Union{CDDInequalityMatrix{T, S}, CDDGeneratorMatrix{T, S}}
CDDMatrix{T}(rep) where {T} = CDDMatrix{T, mytype(T)}(rep)
Polyhedra.FullDim(rep::CDDMatrix) = Int(unsafe_load(rep.matrix).colsize) - 1
Polyhedra.hvectortype(::Union{CDDInequalityMatrix{T}, Type{<:CDDInequalityMatrix{T}}}) where {T} = Vector{T}
Polyhedra.vvectortype(::Union{CDDGeneratorMatrix{T}, Type{<:CDDGeneratorMatrix{T}}}) where {T} = Vector{T}
Polyhedra.similar_type(::Type{<:CDDInequalityMatrix}, ::Polyhedra.FullDim, ::Type{T}) where {T} = CDDInequalityMatrix{T, mytype(T)}
Polyhedra.similar_type(::Type{<:CDDGeneratorMatrix}, ::Polyhedra.FullDim, ::Type{T}) where {T} = CDDGeneratorMatrix{T, mytype(T)}

function linset(matrix::CDDMatrix)
    mat = unsafe_load(matrix.matrix)
    Base.convert(BitSet, CDDSet(mat.linset, mat.rowsize))
end

CDDMatrix(hrep::HRepresentation) = CDDInequalityMatrix(hrep)
CDDMatrix(vrep::VRepresentation) = CDDGeneratorMatrix(vrep)
cddmatrix(::Type{T}, hrep::HRepresentation) where {T} = convert(CDDInequalityMatrix{T, mytype(T)}, hrep)
cddmatrix(::Type{T}, vrep::VRepresentation) where {T} = convert(CDDGeneratorMatrix{T, mytype(T)}, vrep)
#(::Type{CDDMatrix{T,S}}){T,S}(hrep::HRepresentation) = CDDInequalityMatrix{T,S}(hrep)
#(::Type{CDDMatrix{T,S}}){T,S}(vrep::VRepresentation) = CDDGeneratorMatrix{T,S}(vrep)
# Does not work
#Base.convert{T,S}(::Type{CDDMatrix{T,S}}, vrep::VRepresentation) = CDDGeneratorMatrix{T,S}(vrep)

function _length(matrix::Ptr{Cdd_MatrixData{S}}) where S
    mat = unsafe_load(matrix)
    Int(mat.rowsize)
end
Base.length(matrix::CDDInequalityMatrix) = _length(matrix.matrix)
Base.length(matrix::CDDGeneratorMatrix) = _length(matrix.matrix) + matrix.cone

function dd_freematrix(matrix::Ptr{Cdd_MatrixData{Cdouble}})
    @ddf_ccall FreeMatrix Nothing (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_freematrix(matrix::Ptr{Cdd_MatrixData{GMPRational}})
    @dd_ccall FreeMatrix Nothing (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end
function myfree(matrix::CDDMatrix)
    dd_freematrix(matrix.matrix)
end

Polyhedra.done(idxs::Polyhedra.Indices{T, ElemT, <:CDDMatrix{T}}, idx::Polyhedra.Index{T, ElemT}) where {T, ElemT} = idx.value > length(idxs.rep)
Base.get(hrep::CDDMatrix{T}, idx::Polyhedra.Index{T}) where {T} = Polyhedra.valuetype(idx)(extractrow(hrep, idx.value)...)

# H-representation

CDDInequalityMatrix(rep::Rep{T}) where {T} = convert(CDDInequalityMatrix{polytypefor(T), mytypefor(T)}, rep)

CDDInequalityMatrix(matrix::Ptr{Cdd_MatrixData{T}}) where {T} = CDDInequalityMatrix{polytype(T), T}(matrix)

function CDDInequalityMatrix{T, S}(d::Polyhedra.FullDim, hits::Polyhedra.HIt{T}...) where {T, S}
    CDDInequalityMatrix(initmatrix(d, T, true, hits...))
end

nhreps(matrix::CDDInequalityMatrix) = length(matrix)
neqs(matrix::CDDInequalityMatrix) = dd_set_card(unsafe_load(matrix.matrix).linset)
Base.length(idxs::Polyhedra.Indices{T, <:HyperPlane{T}, <:CDDInequalityMatrix{T}}) where {T} = neqs(idxs.rep)
Base.length(idxs::Polyhedra.Indices{T, <:HalfSpace{T}, <:CDDInequalityMatrix{T}}) where {T} = nhreps(idxs.rep) - neqs(idxs.rep)

function Base.copy(matrix::CDDInequalityMatrix{T, S}) where {T, S}
    CDDInequalityMatrix{T, S}(dd_matrixcopy(matrix.matrix))
end

function extractrow(mat::Cdd_MatrixData{Cdouble}, i)
    @assert 1 <= i <= mat.rowsize
    n = mat.colsize
    b = Vector{Cdouble}(undef, n)
    row = unsafe_load(mat.matrix, i)
    for j = 1:n
        b[j] = unsafe_load(row, j)
    end
    b
end

function extractrow(mat::Cdd_MatrixData{GMPRational}, i)
    @assert 1 <= i <= mat.rowsize
    n = mat.colsize
    b = Vector{GMPRationalMut}(undef, n)
    row = unsafe_load(mat.matrix, i)
    for j = 1:n
        b[j] = GMPRationalMut()
        ccall((:__gmpq_set, :libgmp), Nothing, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(b[j]), row + ((j-1)*sizeof(GMPRational)))
    end
    Array{Rational{BigInt}}(Array{GMPRational}(b))
end

function extractrow(ine::CDDInequalityMatrix, i)
    mat = unsafe_load(ine.matrix)
    b = extractrow(mat, i)
    β = b[1]
    a = -b[2:end]
    a, β
end
function extractrow(ext::CDDGeneratorMatrix{T}, i) where {T}
    if ext.cone && i == nvreps(ext)
        a = Polyhedra.origin(Polyhedra.vvectortype(ext), fulldim(ext))
    else
        mat = unsafe_load(ext.matrix)
        b = extractrow(mat, i)
        ispoint = b[1]
        @assert ispoint == zero(T) || ispoint == one(T)
        a = b[2:end]
    end
    (a,) # Needs to be a tuple, see Base.get(::CDDMatrix, ...)
end
function isrowpoint(matrix::Ptr{Cdd_MatrixData{S}}, i, ::Type{T}) where {S, T}
    mat = unsafe_load(matrix)
    b = extractrow(mat, i)
    ispoint = b[1]
    @assert ispoint == zero(T) || ispoint == one(T) # FIXME should we use S ?
    ispoint == one(T)
end
function isrowpoint(ext::CDDGeneratorMatrix{T}, i) where {T}
    (ext.cone && i == nvreps(ext)) || isrowpoint(ext.matrix, i, T)
end
_islin(rep::CDDMatrix, idx::Polyhedra.Index) = dd_set_member(unsafe_load(rep.matrix).linset, idx.value)
Polyhedra.islin(hrep::CDDInequalityMatrix{T}, idx::Polyhedra.HIndex{T}) where {T} = _islin(hrep, idx)
Polyhedra.islin(vrep::CDDGeneratorMatrix{T}, idx::Polyhedra.VIndex{T}) where {T} = !(vrep.cone && idx.value == nvreps(vrep)) && _islin(vrep, idx)

function Base.isvalid(hrep::CDDInequalityMatrix{T}, idx::Polyhedra.HIndex{T}) where {T}
    0 < idx.value <= length(hrep) && Polyhedra.islin(hrep, idx) == islin(idx)
end

function isaninequalityrepresentation(matrix::CDDInequalityMatrix)
    true
end

function setobjective(matrix::CDDInequalityMatrix{T}, c, sense) where {T}
    dd_setmatrixobjective(matrix.matrix, sense == :Max ? dd_LPmax : dd_LPmin)
    obj = [zero(T); Vector{T}(c)]
    dd_copyArow(unsafe_load(matrix.matrix).rowvec, obj)
end

# V-representation

CDDGeneratorMatrix(rep::Rep{T}) where {T} = convert(CDDGeneratorMatrix{polytypefor(T), mytypefor(T)}, rep)

CDDGeneratorMatrix(matrix::Ptr{Cdd_MatrixData{T}}) where {T} = CDDGeneratorMatrix{polytype(T), T}(matrix)

function Base.copy(matrix::CDDGeneratorMatrix{T, S}) where {T, S}
    CDDGeneratorMatrix{T, S}(dd_matrixcopy(matrix.matrix))
end

function CDDGeneratorMatrix{T,S}(d::Polyhedra.FullDim, vits::Polyhedra.VIt{T}...) where {T, S}
    CDDGeneratorMatrix(initmatrix(d, T, false, vits...))
end

nvreps(matrix::CDDGeneratorMatrix) = length(matrix)
function Base.length(idxs::Polyhedra.PointIndices{T, <:CDDGeneratorMatrix{T}}) where {T}
    if idxs.rep.cone
        1
    else
        Polyhedra.mixedlength(idxs)
    end
end

function Base.isvalid(vrep::CDDGeneratorMatrix{T}, idx::Polyhedra.VIndex{T}) where {T}
    isp = isrowpoint(vrep, idx.value)
    isl = Polyhedra.islin(vrep, idx)
    @assert !isp || !isl # if isp && isl, it is a symmetric point but it is not allowed to mix symmetric points and points
    0 < idx.value <= length(vrep) && isl == islin(idx) && isp == ispoint(idx)
end

isaninequalityrepresentation(matrix::CDDGeneratorMatrix) = false

function extractA(mat::Cdd_MatrixData{Cdouble})
    m = mat.rowsize
    n = mat.colsize
    A = Array{Cdouble, 2}(undef, m, n)
    for i = 1:m
        row = unsafe_load(mat.matrix, i)
        for j = 1:n
            A[i,j] = unsafe_load(row, j)
        end
    end
    A
end

function extractA(mat::Cdd_MatrixData{GMPRational})
    m = mat.rowsize
    n = mat.colsize
    A = Array{GMPRationalMut, 2}(undef, m, n)
    for i = 1:m
        row = unsafe_load(mat.matrix, i)
        for j = 1:n
            A[i, j] = GMPRationalMut()
            ccall((:__gmpq_set, :libgmp), Nothing, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(A[i,j]), row + ((j-1)*sizeof(GMPRational)))
        end
    end
    Array{GMPRational}(A)
end

function Base.show(io::IO, matrix::Cdd_MatrixData{T}) where T
    if matrix.representation == dd_Inequality
        println(io, "H-representation")
    else
        println(io, "V-representation")
    end

    linsize = dd_set_card(matrix.linset)
    if linsize > 0
        print(io, "linearity $linsize");
        for i in 1:matrix.rowsize
            if dd_set_member(matrix.linset, i)
                print(io, " $i")
            end
        end
        println(io)
    end

    println(io, "begin")
    println(io, " $(matrix.rowsize) $(matrix.colsize) $(T == Cdouble ? "real" : "rational")")
    A = extractA(matrix)
    for i = 1:size(A, 1)
        for j = 1:size(A, 2)
            print(io, " $(A[i, j])")
        end
        println(io)
    end
    print(io, "end")

    if matrix.objective > 0
        println(io)
        println(io, matrix.objective == 1 ? "maximize" : "minimize")
        for i = 1:matrix.colsize
            print(io, " $(unsafe_load(matrix.rowvec, i))")
        end
    end

end

export CDDMatrix, CDDInequalityMatrix, CDDGeneratorMatrix, isaninequalityrepresentation
