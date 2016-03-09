import Base.round

function myfree(ine::InequalityDescription{GMPRational})
  myfree(ine.A)
  myfree(ine.b)
end

function myfree(desc::GeneratorDescription{GMPRational})
  myfree(desc.V)
  myfree(desc.R)
end

# CDDMatrix -> Description
InequalityDescription{N, T<:Real}(matrix::CDDInequalityMatrix{N, T}) = InequalityDescription{T}(matrix)
GeneratorDescription{N, T<:Real}(matrix::CDDGeneratorMatrix{N, T}) = GeneratorDescription{T}(matrix)

Base.convert{T}(::Type{Description{T}}, ine::InequalityDescription{GMPRational}) = Base.convert(InequalityDescription{T}, ine)
Base.convert{T}(::Type{Description{T}}, ext::GeneratorDescription{GMPRational}) = Base.convert(GeneratorDescription{T}, ext)

Base.convert{T}(::Type{InequalityDescription{T}}, ine::InequalityDescription{GMPRational}) = InequalityDescription{T}(Array{T}(ine.A), Array{T}(ine.b), ine.linset)

Base.convert{T}(::Type{GeneratorDescription{T}}, ext::GeneratorDescription{GMPRational}) = GeneratorDescription{T}(Array{T}(ext.V), Array{T}(ext.R), ext.vertex, ext.Vlinset, ext.Rlinset)

# converters Description -> CDDMatrix

function Base.convert{N, T<:MyType}(::Type{CDDInequalityMatrix{N, T}}, ine::InequalityDescription{T})
  if N != fulldim(ine)
    error("N should be equal to the number of columns of A")
  end
  M = [ine.b -ine.A]
  matrix = initmatrix(M, ine.linset, true)
  CDDInequalityMatrix{N, T}(matrix)
end

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ine::InequalityDescription{T}) = Base.convert(CDDInequalityMatrix{N, T}, ine)

function settoCarray{T<:MyType}(::Type{T}, set::IntSet, m::Integer)
  s = zeros(T, m)
  for el in set
    s[el] = Base.convert(T, 1)
  end
  s
end

function Base.convert{N, T<:MyType}(::Type{CDDGeneratorMatrix{N, T}}, ext::GeneratorDescription{T})
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

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ext::GeneratorDescription{T}) = Base.convert(CDDGeneratorMatrix{N, T}, ext)

# Specified T
Base.convert{N, T<:MyType, S<:Real}(::Type{CDDMatrix{N, T}}, desc::Description{S}) = Base.convert(CDDMatrix{N, T}, Base.convert(Description{T}, desc))
# Unspecified T
Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Description{S}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, Base.convert(Description{GMPRational}, desc))
Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Description{Rational{S}}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, Base.convert(Description{GMPRational}, desc))
Base.convert{S<:BigFloat}(::Type{CDDMatrix}, desc::Description{S}) = error("not implemented yet")
Base.convert(::Type{CDDMatrix}, desc::Description{Float32}) = Base.convert(CDDMatrix{fulldim(desc), Cdouble}, Base.convert(Description{Cdouble}, desc))
Base.convert(::Type{CDDMatrix}, desc::Description{Float64}) = Base.convert(CDDMatrix{fulldim(desc), Cdouble}, desc)
Base.convert(::Type{CDDMatrix}, desc::Description{GMPRational}) = Base.convert(CDDMatrix{fulldim(desc), GMPRational}, desc)

Base.convert{T<:Real}(::Type{CDDInequalityMatrix}, ine::InequalityDescription{T}) = Base.convert(CDDMatrix, ine)
Base.convert{T<:Real}(::Type{CDDGeneratorMatrix}, ext::GeneratorDescription{T}) = Base.convert(CDDMatrix, ext)


# converters CDDMatrix -> Description

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

function Base.convert{N, T<:MyType}(::Type{InequalityDescription{T}}, matrix::CDDInequalityMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 1

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  InequalityDescription(-A, b, linset)
end

Base.convert{N, T<:MyType}(::Type{Description{T}}, ine::CDDInequalityMatrix{N, T}) = Base.convert(InequalityDescription{T}, ine)

function Base.convert{N, T<:MyType}(::Type{GeneratorDescription{T}}, matrix::CDDGeneratorMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 2

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  GeneratorDescription(A, myconvert(IntSet, b), linset)
end

Base.convert{N, T<:MyType}(::Type{Description{T}}, ine::CDDGeneratorMatrix{N, T}) = Base.convert(GeneratorDescription{T}, ine)

Base.convert{N, T<:MyType, S<:Real}(::Type{Description{S}}, matrix::CDDMatrix{N, T}) = Base.convert(Description{S}, Base.convert(Description{T}, matrix))
Base.convert{N, T<:MyType}(::Type{Description}, matrix::CDDMatrix{N, T}) = Base.convert(Description{T}, matrix)
