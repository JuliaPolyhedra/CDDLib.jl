import Base.round

function myfree(ine::HRepresentation{GMPRational})
  myfree(ine.A)
  myfree(ine.b)
end

function myfree(desc::VRepresentation{GMPRational})
  myfree(desc.V)
  myfree(desc.R)
end

# CDDMatrix -> Representation
HRepresentation{N, T<:Real}(matrix::CDDInequalityMatrix{N, T}) = HRepresentation{T}(matrix)
VRepresentation{N, T<:Real}(matrix::CDDGeneratorMatrix{N, T}) = VRepresentation{T}(matrix)

Base.convert{T}(::Type{Representation{T}}, ine::HRepresentation{GMPRational}) = Base.convert(HRepresentation{T}, ine)
Base.convert{T}(::Type{Representation{T}}, ext::VRepresentation{GMPRational}) = Base.convert(VRepresentation{T}, ext)

Base.convert{T}(::Type{HRepresentation{T}}, ine::HRepresentation{GMPRational}) = HRepresentation{T}(Array{T}(ine.A), Array{T}(ine.b), ine.linset)

Base.convert{T}(::Type{VRepresentation{T}}, ext::VRepresentation{GMPRational}) = VRepresentation{T}(Array{T}(ext.V), Array{T}(ext.R), ext.vertex, ext.Vlinset, ext.Rlinset)

# converters Representation -> CDDMatrix

function Base.convert{N, T<:MyType}(::Type{CDDInequalityMatrix{N, T}}, ine::HRepresentation{T})
  if N != fulldim(ine)
    error("N should be equal to the number of columns of A")
  end
  M = [ine.b -ine.A]
  matrix = initmatrix(M, ine.linset, true)
  CDDInequalityMatrix{N, T}(matrix)
end

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ine::HRepresentation{T}) = Base.convert(CDDInequalityMatrix{N, T}, ine)

function settoCarray{T<:MyType}(::Type{T}, set::IntSet, m::Integer)
  s = zeros(T, m)
  for el in set
    s[el] = Base.convert(T, 1)
  end
  s
end

function Base.convert{N, T<:MyType}(::Type{CDDGeneratorMatrix{N, T}}, ext::VRepresentation{T})
  if N != fulldim(ext)
    error("N should be equal to the number of columns of V and R")
  end
  mA = [ext.V; ext.R]
  b = settoCarray(T, ext.vertex, size(mA, 1))
  matrix = initmatrix([b mA], ext.Rlinset, false)
  mat = unsafe_load(matrix)
  dd_settype(mat.linset, ext.Vlinset, size(ext.V, 1))
  CDDGeneratorMatrix(matrix)
end

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ext::VRepresentation{T}) = Base.convert(CDDGeneratorMatrix{N, T}, ext)

# Specified T
Base.convert{N, T<:MyType, S<:Real}(::Type{CDDMatrix{N, T}}, desc::Representation{S}) = Base.convert(CDDMatrix{N, T}, Base.convert(Representation{T}, desc))
# Unspecified T
#Base.convert{S<:MyType}(::Type{CDDMatrix}, desc::Representation{S}) = Base.convert(CDDMatrix{fulldim(desc), S}, desc)
Base.convert{S}(::Type{CDDMatrix}, desc::Representation{S})         = Base.convert(CDDMatrix{fulldim(desc), mytypefor(S)}, desc)
# Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Representation{S}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, Base.convert(Representation{GMPRational}, desc))
# Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Representation{Rational{S}}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, Base.convert(Representation{GMPRational}, desc))
# Base.convert{S<:BigFloat}(::Type{CDDMatrix}, desc::Representation{S}) = error("not implemented yet")
# Base.convert(::Type{CDDMatrix}, desc::Representation{Float32}) = Base.convert(CDDMatrix{fulldim(desc), Cdouble}, Base.convert(Representation{Cdouble}, desc))
# Base.convert(::Type{CDDMatrix}, desc::Representation{Float64}) = Base.convert(CDDMatrix{fulldim(desc), Cdouble}, desc)
# Base.convert(::Type{CDDMatrix}, desc::Representation{GMPRational}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, desc)

Base.convert{T<:Real}(::Type{CDDInequalityMatrix}, ine::HRepresentation{T}) = Base.convert(CDDMatrix, ine)
Base.convert{T<:Real}(::Type{CDDGeneratorMatrix}, ext::VRepresentation{T}) = Base.convert(CDDMatrix, ext)


# converters CDDMatrix -> Representation

function extractAb(mat::Cdd_MatrixData{Cdouble})
  m = mat.rowsize
  d = mat.colsize-1
  b = Array{Cdouble, 1}(m)
  A = Array{Cdouble, 2}(m, d)
  for i = 1:m
    row = unsafe_load(mat.matrix, i)
    b[i] = unsafe_load(row, 1)
    for j = 1:d
      A[i,j] = unsafe_load(row, j+1)
    end
  end
  (b, A)
end

function extractAb(mat::Cdd_MatrixData{GMPRational})
  m = mat.rowsize
  d = mat.colsize-1
  b = Array{GMPRationalMut, 1}(m)
  A = Array{GMPRationalMut, 2}(m, d)
  for i = 1:m
    row = unsafe_load(mat.matrix, i)
    b[i] = GMPRationalMut()
    ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(b[i]), row)
    for j = 1:d
      A[i, j] = GMPRationalMut()
      ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(A[i,j]), row + (j*sizeof(GMPRational)))
    end
  end
  (Array{GMPRational}(b), Array{GMPRational}(A))
end

function Base.convert{N, T<:MyType}(::Type{HRepresentation{T}}, matrix::CDDInequalityMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 1

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  HRepresentation(-A, b, linset)
end

Base.convert{N, T<:MyType}(::Type{Representation{T}}, ine::CDDInequalityMatrix{N, T}) = Base.convert(HRepresentation{T}, ine)

function Base.convert{N, T<:MyType}(::Type{VRepresentation{T}}, matrix::CDDGeneratorMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 2

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  VRepresentation(A, myconvert(IntSet, b), linset)
end

Base.convert{N, T<:MyType}(::Type{Representation{T}}, ine::CDDGeneratorMatrix{N, T}) = Base.convert(VRepresentation{T}, ine)

Base.convert{N, T<:MyType, S<:Real}(::Type{HRepresentation{S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{S}, Base.convert(Representation{T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{VRepresentation{S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{S}, Base.convert(Representation{T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{Representation{S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{S}, Base.convert(Representation{T}, matrix))
Base.convert{N, T<:MyType}(::Type{Representation}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{T}, matrix)
