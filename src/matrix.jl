type Cdd_MatrixData{T <: MyType}
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

function fillmatrix{T}(inequality::Bool, matrix::Ptr{Ptr{T}}, itr1, linset=IntSet(), offset=0)
  for (i, item) in enumerate(itr1)
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

function initmatrix{N, T}(inequality::Bool, itr1::AbstractRepIterator{N, T}, itr2=nothing)
  n = N+1
  m = length(itr1)
  if !(itr2 === nothing)
    m += length(itr2)
  end
  matrix = dd_creatematrix(mytype(T), Cdd_rowrange(m), Cdd_colrange(n))
  mat = unsafe_load(matrix)
  linset = fillmatrix(inequality, mat.matrix, itr1)
  if !(itr2 === nothing)
    fillmatrix(inequality, mat.matrix, itr2, linset, length(itr1))
  end
  dd_settype(mat.linset, linset)
  dd_setmatrixnumbertype(matrix)
  dd_setmatrixrepresentationtype(matrix, inequality)
  matrix
end

# Representation

type CDDInequalityMatrix{N, T <: PolyType, S <: MyType} <: HRepresentation{N, T}
  matrix::Ptr{Cdd_MatrixData{S}}

  function CDDInequalityMatrix{N, T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {N, T <: PolyType, S <: MyType}
    @assert polytype(S) == T
    m = new{N, T, S}(matrix)
    finalizer(m, myfree)
    m
  end

end
changeeltype{N, T, S, NewT}(::Type{CDDInequalityMatrix{N, T, S}}, ::Type{NewT}) = CDDInequalityMatrix{N, NewT, mytype(NewT)}
changefulldim{N, T, S}(::Type{CDDInequalityMatrix{N, T, S}}, NewN) = CDDInequalityMatrix{NewN, T, S}
changeboth{N, T, S, NewT}(::Type{CDDInequalityMatrix{N, T, S}}, NewN, ::Type{NewT}) = CDDInequalityMatrix{NewN, NewT, mytype(NewT)}
decomposedfast(ine::CDDInequalityMatrix) = false

type CDDGeneratorMatrix{N, T <: PolyType, S <: MyType} <: VRepresentation{N, T}
  matrix::Ptr{Cdd_MatrixData{S}}

  function CDDGeneratorMatrix{N, T, S}(matrix::Ptr{Cdd_MatrixData{S}}) where {N, T <: PolyType, S <: MyType}
    @assert polytype(S) == T
    m = new{N, T, S}(matrix)
    finalizer(m, myfree)
    m
  end

end
changeeltype{N, T, S, NewT}(::Type{CDDGeneratorMatrix{N, T, S}}, ::Type{NewT}) = CDDGeneratorMatrix{N, NewT, mytype(NewT)}
changefulldim{N, T, S}(::Type{CDDGeneratorMatrix{N, T, S}}, NewN) = CDDGeneratorMatrix{NewN, T, S}
changeboth{N, T, S, NewT}(::Type{CDDGeneratorMatrix{N, T, S}}, NewN, ::Type{NewT}) = CDDGeneratorMatrix{NewN, NewT, mytype(NewT)}
decomposedfast(ine::CDDGeneratorMatrix) = false

const CDDMatrix{N, T, S} = Union{CDDInequalityMatrix{N, T, S}, CDDGeneratorMatrix{N, T, S}}
(::Type{CDDMatrix{N, T}}){N, T}(rep) = CDDMatrix{N, T, mytype(T)}(rep)

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

function Base.length{N}(matrix::CDDMatrix{N})
  mat = unsafe_load(matrix.matrix)
  @assert Int(mat.colsize) == N+1
  Int(mat.rowsize)
end

function dd_freematrix(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_freematrix(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end
function myfree(matrix::CDDMatrix)
  dd_freematrix(matrix.matrix)
end

# H-representation

CDDInequalityMatrix{N,T}(rep::Rep{N,T}) = CDDInequalityMatrix{N,polytypefor(T), mytypefor(T)}(rep)

CDDInequalityMatrix{T}(matrix::Ptr{Cdd_MatrixData{T}}) = CDDInequalityMatrix{unsafe_load(matrix).colsize-1, polytype(T), T}(matrix)

function (::Type{CDDInequalityMatrix{N, T, S}}){N,T,S}(it::HRepIterator{N, T})
  CDDInequalityMatrix(initmatrix(true, it))
end
function (::Type{CDDInequalityMatrix{N, T, S}}){N,T,S}(; eqs=nothing, ineqs=nothing)
  CDDInequalityMatrix(initmatrix(true, eqs, ineqs))
end

nhreps(matrix::CDDInequalityMatrix) = length(matrix)
neqs(matrix::CDDInequalityMatrix) = dd_set_card(unsafe_load(matrix.matrix).linset)
nineqs(matrix::CDDInequalityMatrix) = length(matrix) - neqs(matrix)

function Base.copy{N, T, S}(matrix::CDDInequalityMatrix{N, T, S})
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
  if dd_set_member(mat.linset, i)
    HyperPlane(a, β)
  else
    HalfSpace(a, β)
  end
end
function extractrow{N,T}(ext::CDDGeneratorMatrix{N,T}, i)
  mat = unsafe_load(ext.matrix)
  b = extractrow(mat, i)
  ispoint = b[1]
  @assert ispoint == zero(T) || ispoint == one(T)
  a = b[2:end]
  if ispoint == one(T)
    if dd_set_member(mat.linset, i)
      SymPoint(a)
    else
      a
    end
  else
    if dd_set_member(mat.linset, i)
      Line(a)
    else
      Ray(a)
    end
  end
end
function isrowpoint{N,T}(ext::CDDGeneratorMatrix{N,T}, i)
  mat = unsafe_load(ext.matrix)
  b = extractrow(unsafe_load(ext.matrix), i)
  ispoint = b[1]
  @assert ispoint == zero(T) || ispoint == one(T)
  ispoint == one(T)
end

starthrep(ine::CDDInequalityMatrix) = 1
donehrep(ine::CDDInequalityMatrix, state) = state > length(ine)
nexthrep(ine::CDDInequalityMatrix, state) = (extractrow(ine, state), state+1)

function nextnz(is::Cset_type, i, n)
  while i <= n && !dd_set_member(is, i)
    i += 1
  end
  i
end
starteq(ine::CDDInequalityMatrix) = nextnz(unsafe_load(ine.matrix).linset, 1, length(ine))
doneeq(ine::CDDInequalityMatrix, state) = state > length(ine)
nexteq(ine::CDDInequalityMatrix, state) = (extractrow(ine, state), nextnz(unsafe_load(ine.matrix).linset, state+1, length(ine)))

function nextz(is::Cset_type, i, n)
  while i <= n && dd_set_member(is, i)
    i += 1
  end
  i
end
startineq(ine::CDDInequalityMatrix) = nextz(unsafe_load(ine.matrix).linset, 1, length(ine))
doneineq(ine::CDDInequalityMatrix, state) = state > length(ine)
nextineq(ine::CDDInequalityMatrix, state) = (extractrow(ine, state), nextz(unsafe_load(ine.matrix).linset, state+1, length(ine)))

function isaninequalityrepresentation(matrix::CDDInequalityMatrix)
  true
end

function setobjective{N, T}(matrix::CDDInequalityMatrix{N, T}, c, sense)
  dd_setmatrixobjective(matrix.matrix, sense == :Max ? dd_LPmax : dd_LPmin)
  obj = [zero(T); Vector{T}(c)]
  dd_copyArow(unsafe_load(matrix.matrix).rowvec, obj)
end

# V-representation

CDDGeneratorMatrix{N,T}(rep::Rep{N,T}) = CDDGeneratorMatrix{N,polytypefor(T), mytypefor(T)}(rep)

CDDGeneratorMatrix{T}(matrix::Ptr{Cdd_MatrixData{T}}) = CDDGeneratorMatrix{unsafe_load(matrix).colsize-1, polytype(T), T}(matrix)

function Base.copy{N, T, S}(matrix::CDDGeneratorMatrix{N, T, S})
  CDDGeneratorMatrix{N, T, S}(dd_matrixcopy(matrix.matrix))
end

function (::Type{CDDGeneratorMatrix{N,T,S}}){N,T,S}(it::VRepIterator{N, T})
  CDDGeneratorMatrix(initmatrix(false, it))
end
function (::Type{CDDGeneratorMatrix{N,T,S}}){N,T,S}(; rays=nothing, points=nothing)
  CDDGeneratorMatrix(initmatrix(false, rays, points))
end

nvreps(matrix::CDDGeneratorMatrix) = length(matrix)
function npoints(matrix::CDDGeneratorMatrix)
  count = 0
  for i in 1:length(matrix)
    if isrowpoint(matrix, i)
      count += 1
    end
  end
  count
end
nrays(matrix::CDDGeneratorMatrix) = length(matrix) - npoints(matrix)

startvrep(ext::CDDGeneratorMatrix) = 1
donevrep(ext::CDDGeneratorMatrix, state) = state > length(ext)
nextvrep(ext::CDDGeneratorMatrix, state) = (extractrow(ext, state), state+1)

function nextrayidx(ext::CDDGeneratorMatrix, i, n)
  while i <= n && isrowpoint(ext, i)
    i += 1
  end
  i
end
function nextpointidx(ext::CDDGeneratorMatrix, i, n)
  while i <= n && !isrowpoint(ext, i)
    i += 1
  end
  i
end

startray(ext::CDDGeneratorMatrix) = nextrayidx(ext, 1, length(ext))
doneray(ext::CDDGeneratorMatrix, state) = state > length(ext)
nextray(ext::CDDGeneratorMatrix, state) = (extractrow(ext, state), nextrayidx(ext, state+1, length(ext)))

startpoint(ext::CDDGeneratorMatrix) = nextpointidx(ext, 1, length(ext))
donepoint(ext::CDDGeneratorMatrix, state) = state > length(ext)
nextpoint(ext::CDDGeneratorMatrix, state) = (extractrow(ext, state), nextpointidx(ext, state+1, length(ext)))

function isaninequalityrepresentation(matrix::CDDGeneratorMatrix)
  false
end

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

function Base.show{T}(io::IO, matrix::Cdd_MatrixData{T})
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
