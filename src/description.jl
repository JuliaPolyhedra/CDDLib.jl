import Base.round
abstract Description{T <: Real}

# No copy since I do not modify anything and cddlib does a copy

type InequalityDescription{T <: Real} <: Description{T}
  # Ax <= b
  A::Array{T, 2}
  b::Array{T, 1}
  linset::IntSet

  function InequalityDescription(A::Array{T, 2}, b::Array{T, 1}, linset::IntSet)
    if size(A, 1) != length(b)
      error("The length of b must be equal to the number of rows of A")
    end
    if ~isempty(linset) && last(linset) > length(b)
      error("The elements of linset should be between 1 and the number of rows of A/length of b")
    end
    ine = new(A, b, linset)
    finalizer(ine, myfree)
    ine
  end
end

function myfree{T<:Real}(ine::InequalityDescription{T})
  # Nothing to free
end
function myfree(ine::InequalityDescription{GMPRational})
  myfree(ine.A)
  myfree(ine.b)
end

InequalityDescription{T <: Real}(A::Array{T, 2}, b::Array{T, 1}, linset::IntSet) = InequalityDescription{T}(A, b, linset)

InequalityDescription{T <: Real}(A::Array{T, 2}, b::Array{T, 1}) = InequalityDescription(A, b, IntSet([]))

Base.round{T<:AbstractFloat}(ine::InequalityDescription{T}) = InequalityDescription{T}(Base.round(ine.A), Base.round(ine.b), ine.linset)

type GeneratorDescription{T <: Real} <: Description{T}
  V::Array{T, 2} # each row is a vertex/ray
  R::Array{T, 2} # rays
  vertex::IntSet # vertex or ray in V
  Vlinset::IntSet # linear or not
  Rlinset::IntSet # linear or not

  function GeneratorDescription(V::Array{T, 2}, R::Array{T, 2}, vertex::IntSet, Vlinset::IntSet, Rlinset::IntSet)
    if length(R) > 0 && length(V) > 0 && size(V, 2) != size(R, 2)
      error("The dimension of the vertices and rays should be the same")
    end
    if ~isempty(vertex) && last(vertex) > size(V, 1)
      error("The elements of vertex should be between 1 and the number of rows of V")
    end
    if ~isempty(Vlinset) && last(Vlinset) > size(V, 1)
      error("The elements of Vlinset should be between 1 and the number of rows of V")
    end
    if ~isempty(Rlinset) && last(Rlinset) > size(R, 1)
      error("The elements of Rlinset should be between 1 and the number of rows of R")
    end
    desc = new(V, R, vertex, Vlinset, Rlinset)
    finalizer(desc, myfree)
    desc
  end
end

function myfree{T<:Real}(desc::GeneratorDescription{T})
  # Nothing to free
end
function myfree(desc::GeneratorDescription{GMPRational})
  myfree(desc.V)
  myfree(desc.R)
end

GeneratorDescription{T}(V::Array{T, 2}, R::Array{T, 2}, vertex::IntSet, Vlinset::IntSet, Rlinset::IntSet) = GeneratorDescription{T}(V, R, vertex, Vlinset, Rlinset)

GeneratorDescription{T <: Real}(V::Array{T, 2}, vertex::IntSet, linset::IntSet) = GeneratorDescription(V, Array{T, 2}(0, size(V, 2)), vertex, linset, IntSet([]))
GeneratorDescription{T <: Real}(V::Array{T, 2}, vertex::IntSet) = GeneratorDescription(V, vertex, IntSet([]))

Base.round{T<:AbstractFloat}(ext::GeneratorDescription{T}) = GeneratorDescription{T}(Base.round(ext.V), Base.round(ext.R), ext.vertex, ext.Vlinset, ext.Rlinset)

function splitvertexrays!{T<:Real}(ext::GeneratorDescription{T})
  nV = length(ext.vertex)
  if nV != size(ext.V, 1)
    nR = size(ext.R, 1) + size(ext.V, 1) - nV
    newV = Array(T, nV, size(ext.V, 2))
    newR = Array(T, nR, size(ext.V, 2))
    curV = 1
    curR = 1
    newR[1:size(ext.R, 1), :] = ext.R
    for i = 1:size(ext.V, 1)
      if i in ext.vertex
        newV[curV, :] = ext.V[i, :]
        curV += 1
      else
        newR[curR, :] = ext.V[i, :]
        curR += 1
      end
    end
    ext.V = newV
    ext.R = newR
    ext.vertex = IntSet(1:nV)
  end
end

# Description -> Description

Base.convert{T, S}(::Type{Description{T}}, ine::InequalityDescription{S}) = Base.convert(InequalityDescription{T}, ine)
Base.convert{T, S}(::Type{Description{T}}, ext::GeneratorDescription{S}) = Base.convert(GeneratorDescription{T}, ext)

Base.convert{T, S}(::Type{InequalityDescription{T}}, ine::InequalityDescription{S}) = InequalityDescription{T}(Array{T}(ine.A), Array{T}(ine.b), ine.linset)

Base.convert{T, S}(::Type{GeneratorDescription{T}}, ext::GeneratorDescription{S}) = GeneratorDescription{T}(Array{T}(ext.V), Array{T}(ext.R), ext.vertex, ext.Vlinset, ext.Rlinset)

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

export Description, InequalityDescription, GeneratorDescription, extractAb, splitvertexrays!
