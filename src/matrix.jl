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
#   @ddf_ccall CopyAmatrixVectorizedByColumn Void (Cdd_Amatrix{Cdouble}, Ptr{Cdouble}, Cdd_rowrange, Cdd_colrange) mat M m n
# end
# function dd_copyAmatrixvectorizedbycolumn(mat::Cdd_Amatrix{GMPRational}, M::Matrix{GMPRational}, m::Cdd_rowrange, n::Cdd_colrange)
#   @dd_ccall CopyAmatrixVectorizedByColumn Void (Cdd_Amatrix{GMPRational}, Ptr{GMPRational}, Cdd_rowrange, Cdd_colrange) mat M m n
# end

function dd_copyArow(acopy::Cdd_Arow{Cdouble}, a::Vector{Cdouble})
  @ddf_ccall CopyArow Void (Cdd_Arow{Cdouble}, Cdd_Arow{Cdouble}, Cdd_colrange) acopy a length(a)
end
function dd_copyArow(acopy::Cdd_Arow{GMPRational}, a::Vector{Rational{BigInt}})
  b = Vector{GMPRational}(a)
  @dd_ccall CopyArow Void (Cdd_Arow{GMPRational}, Cdd_Arow{GMPRational}, Cdd_colrange) acopy b length(b)
  myfree(b)
end

dd_copyArow(acopy::Cdd_Arow, a::AbstractVector) = dd_copyArow(acopy, collect(a)) # e.g. for sparse a

function dd_setmatrixobjective(matrix::Ptr{Cdd_MatrixData{Cdouble}}, objective::Cdd_LPObjectiveType)
  @ddf_ccall SetMatrixObjective Void (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_LPObjectiveType) matrix objective
end
function dd_setmatrixobjective(matrix::Ptr{Cdd_MatrixData{GMPRational}}, objective::Cdd_LPObjectiveType)
  @dd_ccall SetMatrixObjective Void (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_LPObjectiveType) matrix objective
end

function dd_setmatrixnumbertype(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall SetMatrixNumberType Void (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_NumberType) matrix dd_Real
end
function dd_setmatrixnumbertype(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall SetMatrixNumberType Void (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_NumberType) matrix dd_Rational
end

function dd_setmatrixrepresentationtype(matrix::Ptr{Cdd_MatrixData{Cdouble}}, inequality::Bool)
  @ddf_ccall SetMatrixRepresentationType Void (Ptr{Cdd_MatrixData{Cdouble}}, Cdd_RepresentationType) matrix (inequality ? dd_Inequality : dd_Generator)
end
function dd_setmatrixrepresentationtype(matrix::Ptr{Cdd_MatrixData{GMPRational}}, inequality::Bool)
  @dd_ccall SetMatrixRepresentationType Void (Ptr{Cdd_MatrixData{GMPRational}}, Cdd_RepresentationType) matrix (inequality ? dd_Inequality : dd_Generator)
end

function dd_matrixcopy(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall MatrixCopy Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_matrixcopy(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall MatrixCopy Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end

function fillmatrix(inequality::Bool, matrix::Ptr{Ptr{T}}, itr, linset::IntSet, offset) where T
  for (i, item) in enumerate(itr)
    row = unsafe_load(matrix, offset+i)
    if islin(item)
      push!(linset, offset + i)
    end
    # CDD is expected <a, x> >= 0 but Polyhedra uses <a, x> <= 0
    a = vec(coord(lift(item)))
    dd_copyArow(row, inequality ? -a : a)
  end
  linset
end

# If ElemIt contains AbstractVector{T}, we cannot infer FullDim so we add both as argument
function initmatrix(::Polyhedra.FullDim{N}, ::Type{T}, inequality::Bool, itr::Polyhedra.ElemIt...) where {N, T}
  n = N+1
  cs = cumsum(collect(length.(itr))) # cumsum not defined for tuple :(
  m = cs[end]
  offset = [0; cs[1:end-1]]
  matrix = dd_creatematrix(mytype(T), Cdd_rowrange(m), Cdd_colrange(n))
  mat = unsafe_load(matrix)
  linset = IntSet()
  fillmatrix.(inequality, mat.matrix, itr, linset, offset)
  dd_settype(mat.linset, linset)
  dd_setmatrixnumbertype(matrix)
  dd_setmatrixrepresentationtype(matrix, inequality)
  matrix
end

# Representation

mutable struct CDDInequalityMatrix{N, T <: PolyType, S <: MyType} <: Polyhedra.MixedHRep{N, T}
  matrix::Ptr{Cdd_MatrixData{S}}

  function CDDInequalityMatrix{N, T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {N, T <: PolyType, S <: MyType}
    @assert polytype(S) == T
    m = new{N, T, S}(matrix)
    finalizer(m, myfree)
    m
  end

end

mutable struct CDDGeneratorMatrix{N, T <: PolyType, S <: MyType} <: Polyhedra.MixedVRep{N, T}
  matrix::Ptr{Cdd_MatrixData{S}}
  cone::Bool # If true, CDD will not return any point so we need to add the origin

  function CDDGeneratorMatrix{N, T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {N, T <: PolyType, S <: MyType}
      @assert polytype(S) == T
      cone = !iszero(_length(matrix, N)) # If there is no ray and no point, it is empty so we should not add the origin
      for i in 1:_length(matrix, N)
          if isrowpoint(matrix, i, T)
              cone = false
              break
          end
      end
      m = new{N, T, S}(matrix, cone)
      finalizer(m, myfree)
      m
  end
end

const CDDMatrix{N, T, S} = Union{CDDInequalityMatrix{N, T, S}, CDDGeneratorMatrix{N, T, S}}
CDDMatrix{N, T}(rep) where {N, T} = CDDMatrix{N, T, mytype(T)}(rep)
Polyhedra.arraytype(::Union{CDDMatrix{N, T}, Type{<:CDDMatrix{N, T}}}) where {N, T} = Vector{T}
Polyhedra.similar_type(::Type{<:CDDInequalityMatrix}, ::FullDim{N}, ::Type{T}) where {N, T} = CDDInequalityMatrix{N, T, mytype(T)}
Polyhedra.similar_type(::Type{<:CDDGeneratorMatrix}, ::FullDim{N}, ::Type{T}) where {N, T} = CDDGeneratorMatrix{N, T, mytype(T)}

function linset(matrix::CDDMatrix)
  mat = unsafe_load(matrix.matrix)
  Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
end

CDDMatrix(hrep::HRepresentation) = CDDInequalityMatrix(hrep)
CDDMatrix(vrep::VRepresentation) = CDDGeneratorMatrix(vrep)
cddmatrix{N,T}(::Type{T}, hrep::HRepresentation{N}) = CDDInequalityMatrix{N,T,mytype(T)}(hrep)
cddmatrix{N,T}(::Type{T}, vrep::VRepresentation{N}) = CDDGeneratorMatrix{N,T,mytype(T)}(vrep)
#(::Type{CDDMatrix{N,T,S}}){N,T,S}(hrep::HRepresentation{N}) = CDDInequalityMatrix{N,T,S}(hrep)
#(::Type{CDDMatrix{N,T,S}}){N,T,S}(vrep::VRepresentation{N}) = CDDGeneratorMatrix{N,T,S}(vrep)
# Does not work
#Base.convert{N,T,S}(::Type{CDDMatrix{N,T,S}}, vrep::VRepresentation{N}) = CDDGeneratorMatrix{N,T,S}(vrep)

function _length(matrix::Ptr{Cdd_MatrixData{S}}, N) where S
    mat = unsafe_load(matrix)
    @assert Int(mat.colsize) == N+1
    Int(mat.rowsize)
end
Base.length(matrix::CDDInequalityMatrix{N}) where N = _length(matrix.matrix, N)
Base.length(matrix::CDDGeneratorMatrix{N}) where N = _length(matrix.matrix, N) + matrix.cone

function dd_freematrix(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_freematrix(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end
function myfree(matrix::CDDMatrix)
  dd_freematrix(matrix.matrix)
end

Base.done(idxs::Polyhedra.Indices{N, T, ElemT, <:CDDMatrix{N, T}}, idx::Polyhedra.Index{N, T, ElemT}) where {N, T, ElemT} = idx.value > length(idxs.rep)
Base.get(hrep::CDDMatrix{N, T}, idx::Polyhedra.Index{N, T}) where {N, T} = Polyhedra.valuetype(idx)(extractrow(hrep, idx.value)...)

# H-representation

CDDInequalityMatrix(rep::Rep{N,T}) where {N,T} = CDDInequalityMatrix{N,polytypefor(T), mytypefor(T)}(rep)

CDDInequalityMatrix(matrix::Ptr{Cdd_MatrixData{T}}) where {T} = CDDInequalityMatrix{unsafe_load(matrix).colsize-1, polytype(T), T}(matrix)

function CDDInequalityMatrix{N, T, S}(eqs::Polyhedra.ElemIt{<:HyperPlane{N, T}}, ineqs::Polyhedra.ElemIt{<:HalfSpace{N, T}}) where {N, T, S}
    CDDInequalityMatrix(initmatrix(Polyhedra.FullDim{N}(), T, true, eqs, ineqs))
end

nhreps(matrix::CDDInequalityMatrix) = length(matrix)
neqs(matrix::CDDInequalityMatrix) = dd_set_card(unsafe_load(matrix.matrix).linset)
Base.length(idxs::Polyhedra.Indices{N, T, <:HyperPlane{N, T}, <:CDDInequalityMatrix{N, T}}) where {N, T} = neqs(idxs.rep)
Base.length(idxs::Polyhedra.Indices{N, T, <:HalfSpace{N, T}, <:CDDInequalityMatrix{N, T}}) where {N, T} = nhreps(idxs.rep) - neqs(idxs.rep)

function Base.copy(matrix::CDDInequalityMatrix{N, T, S}) where {N, T, S}
  CDDInequalityMatrix{N, T, S}(dd_matrixcopy(matrix.matrix))
end

function extractrow(mat::Cdd_MatrixData{Cdouble}, i)
  @assert 1 <= i <= mat.rowsize
  n = mat.colsize
  b = Vector{Cdouble}(n)
  row = unsafe_load(mat.matrix, i)
  for j = 1:n
    b[j] = unsafe_load(row, j)
  end
  b
end

function extractrow(mat::Cdd_MatrixData{GMPRational}, i)
  @assert 1 <= i <= mat.rowsize
  n = mat.colsize
  b = Vector{GMPRationalMut}(n)
  row = unsafe_load(mat.matrix, i)
  for j = 1:n
    b[j] = GMPRationalMut()
    ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(b[j]), row + ((j-1)*sizeof(GMPRational)))
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
function extractrow(ext::CDDGeneratorMatrix{N,T}, i) where {N,T}
    if ext.cone && i == nvreps(ext)
        a = zero(arraytype(ext))
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
function isrowpoint(ext::CDDGeneratorMatrix{N, T}, i) where {N, T}
    (ext.cone && i == nvreps(ext)) || isrowpoint(ext.matrix, i, T)
end
_islin(rep::CDDMatrix, idx::Polyhedra.Index) = dd_set_member(unsafe_load(rep.matrix).linset, idx.value)
Polyhedra.islin(hrep::CDDInequalityMatrix{N, T}, idx::Polyhedra.HIndex{N, T}) where {N, T} = _islin(hrep, idx)
Polyhedra.islin(vrep::CDDGeneratorMatrix{N, T}, idx::Polyhedra.VIndex{N, T}) where {N, T} = !(vrep.cone && idx.value == nvreps(vrep)) && _islin(vrep, idx)

function Base.isvalid(hrep::CDDInequalityMatrix{N, T}, idx::Polyhedra.HIndex{N, T}) where {N, T}
    0 < idx.value <= length(hrep) && Polyhedra.islin(hrep, idx) == islin(idx)
end

function isaninequalityrepresentation(matrix::CDDInequalityMatrix)
  true
end

function setobjective(matrix::CDDInequalityMatrix{N, T}, c, sense) where {N, T}
  dd_setmatrixobjective(matrix.matrix, sense == :Max ? dd_LPmax : dd_LPmin)
  obj = [zero(T); Vector{T}(c)]
  dd_copyArow(unsafe_load(matrix.matrix).rowvec, obj)
end

# V-representation

CDDGeneratorMatrix(rep::Rep{N,T}) where {N,T} = CDDGeneratorMatrix{N,polytypefor(T), mytypefor(T)}(rep)

CDDGeneratorMatrix(matrix::Ptr{Cdd_MatrixData{T}}) where {T} = CDDGeneratorMatrix{unsafe_load(matrix).colsize-1, polytype(T), T}(matrix)

function Base.copy(matrix::CDDGeneratorMatrix{N, T, S}) where {N, T, S}
  CDDGeneratorMatrix{N, T, S}(dd_matrixcopy(matrix.matrix))
end

function CDDGeneratorMatrix{N,T,S}(sympoints::Polyhedra.ElemIt{<:SymPoint{N, T}}, points::Polyhedra.ElemIt{<:Polyhedra.MyPoint{N, T}}, lines::Polyhedra.ElemIt{<:Line{N, T}}, rays::Polyhedra.ElemIt{<:Ray{N, T}}) where {N, T, S}
    CDDGeneratorMatrix(initmatrix(Polyhedra.FullDim{N}(), T, false, lines, sympoints, rays, points))
end

nvreps(matrix::CDDGeneratorMatrix) = length(matrix)
function Base.length(idxs::Polyhedra.PointIndices{N, T, <:CDDGeneratorMatrix{N, T}}) where {N, T}
    if idxs.rep.cone
        1
    else
        Polyhedra.mixedlength(idxs)
    end
end

Base.isvalid(vrep::CDDGeneratorMatrix{N, T}, idx::Polyhedra.VIndex{N, T}) where {N, T} = 0 < idx.value <= length(vrep) && Polyhedra.islin(vrep, idx) == islin(idx) && isrowpoint(vrep, idx.value) == ispoint(idx)

isaninequalityrepresentation(matrix::CDDGeneratorMatrix) = false

function extractA(mat::Cdd_MatrixData{Cdouble})
  m = mat.rowsize
  n = mat.colsize
  A = Array{Cdouble, 2}(m, n)
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
  A = Array{GMPRationalMut, 2}(m, n)
  for i = 1:m
    row = unsafe_load(mat.matrix, i)
    for j = 1:n
      A[i, j] = GMPRationalMut()
      ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(A[i,j]), row + ((j-1)*sizeof(GMPRational)))
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

Base.show(io::IO, matrix::CDDMatrix) = Base.show(io, unsafe_load(matrix.matrix))

export CDDMatrix, CDDInequalityMatrix, CDDGeneratorMatrix, isaninequalityrepresentation
