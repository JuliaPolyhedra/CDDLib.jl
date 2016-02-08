import Base.round

function myfree(ine::InequalityDescription{GMPRational})
  myfree(ine.A)
  myfree(ine.b)
end

function myfree(desc::GeneratorDescription{GMPRational})
  myfree(desc.V)
  myfree(desc.R)
end

# converters Description -> CDDMatrix

function Base.convert{T<:MyType}(::Type{CDDInequalityMatrix{T}}, ine::InequalityDescription{T})
  M = [ine.b -ine.A]
  matrix = initmatrix(M, ine.linset, true)
  CDDInequalityMatrix{T}(matrix)
end

Base.convert{T<:MyType}(::Type{CDDMatrix{T}}, ine::InequalityDescription{T}) = Base.convert(CDDInequalityMatrix{T}, ine)

function settoCarray{T<:MyType}(::Type{T}, set::IntSet, m::Integer)
  s = zeros(T, m)
  for el in set
    s[el] = Base.convert(T, 1)
  end
  s
end

function Base.convert{T<:MyType}(::Type{CDDGeneratorMatrix{T}}, ext::GeneratorDescription{T})
  mA = [ext.V; ext.R]
  b = settoCarray(T, ext.vertex, size(mA, 1))
  matrix = initmatrix([b mA], ext.Rlinset, false)
  mat = unsafe_load(matrix)
  intsettosettype(mat.linset, ext.Vlinset, size(ext.V, 1))
  CDDGeneratorMatrix(matrix)
end

Base.convert{T<:MyType}(::Type{CDDMatrix{T}}, ext::GeneratorDescription{T}) = Base.convert(CDDGeneratorMatrix{T}, ext)

# Specified T
Base.convert{T<:MyType, S<:Real}(::Type{CDDMatrix{T}}, desc::Description{S}) = Base.convert(CDDMatrix{T}, Base.convert(Description{T}, desc))
# Unspecified T
Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Description{S}) = Base.convert(CDDMatrix{GMPRational}, Base.convert(Description{GMPRational}, desc))
Base.convert{S<:Integer}(::Type{CDDMatrix}, desc::Description{Rational{S}}) = Base.convert(CDDMatrix{GMPRational}, Base.convert(Description{GMPRational}, desc))
Base.convert{S<:BigFloat}(::Type{CDDMatrix}, desc::Description{S}) = error("not implemented yet")
Base.convert(::Type{CDDMatrix}, desc::Description{Float32}) = Base.convert(CDDMatrix{Cdouble}, Base.convert(Description{Cdouble}, desc))
Base.convert(::Type{CDDMatrix}, desc::Description{Float64}) = Base.convert(CDDMatrix{Cdouble}, desc)
Base.convert(::Type{CDDMatrix}, desc::Description{GMPRational}) = Base.convert(CDDMatrix{GMPRational}, desc)

Base.convert{T<:Real}(::Type{CDDInequalityMatrix}, ine::InequalityDescription{T}) = Base.convert(CDDMatrix, ine)
Base.convert{T<:Real}(::Type{CDDGeneratorMatrix}, ext::GeneratorDescription{T}) = Base.convert(CDDMatrix, ext)


# converters CDDMatrix -> Description

function extractAb(mat::CDDMatrixData{Cdouble})
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

function extractAb(mat::CDDMatrixData{GMPRational})
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

function Base.convert{T<:MyType}(::Type{InequalityDescription{T}}, matrix::CDDInequalityMatrix{T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 1

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  InequalityDescription(-A, b, linset)
end

Base.convert{T<:MyType}(::Type{Description{T}}, ine::CDDInequalityMatrix{T}) = Base.convert(InequalityDescription{T}, ine)

function Base.convert{T<:MyType}(::Type{GeneratorDescription{T}}, matrix::CDDGeneratorMatrix{T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 2

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  (b, A) = extractAb(mat)
  GeneratorDescription(A, myconvert(IntSet, b), linset)
end

Base.convert{T<:MyType}(::Type{Description{T}}, ine::CDDGeneratorMatrix{T}) = Base.convert(GeneratorDescription{T}, ine)


Base.convert{T<:MyType, S<:Real}(::Type{Description{S}}, matrix::CDDMatrix{T}) = Base.convert(Description{S}, Base.convert(Description{T}, matrix))
Base.convert{T<:MyType}(::Type{Description}, matrix::CDDMatrix{T}) = Base.convert(Description{T}, matrix)
