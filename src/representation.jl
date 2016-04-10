import Base.round

function myfree(ine::SimpleHRepresentation{GMPRational})
  myfree(ine.A)
  myfree(ine.b)
end

function myfree(ext::LiftedVRepresentation{GMPRational})
  myfree(ext.R)
end

function myfree(ext::SimpleVRepresentation{GMPRational})
  myfree(ext.V)
  myfree(ext.R)
end

# CDDMatrix -> Representation
HRepresentation{N, T<:Real}(matrix::CDDInequalityMatrix{N, T}) = HRepresentation{N,T}(matrix)
VRepresentation{N, T<:Real}(matrix::CDDGeneratorMatrix{N, T}) = VRepresentation{N,T}(matrix)

Base.convert{N,T}(::Type{Representation{N,T}}, ine::SimpleHRepresentation{N,GMPRational}) = Base.convert(SimpleHRepresentation{N,T}, ine)
Base.convert{N,T}(::Type{Representation{N,T}}, ine::LiftedHRepresentation{N,GMPRational}) = Base.convert(LiftedHRepresentation{N,T}, ine)
Base.convert{N,T}(::Type{Representation{N,T}}, ext::SimpleVRepresentation{N,GMPRational}) = Base.convert(SimpleVRepresentation{N,T}, ext)
Base.convert{N,T}(::Type{Representation{N,T}}, ext::LiftedVRepresentation{N,GMPRational}) = Base.convert(LiftedVRepresentation{N,T}, ext)

Base.convert{N,T}(::Type{SimpleHRepresentation{N,T}}, ine::SimpleHRepresentation{N,GMPRational}) = SimpleHRepresentation{N,T}(Array{T}(ine.A), Array{T}(ine.b), copy(ine.linset))
Base.convert{N,T}(::Type{LiftedHRepresentation{N,T}}, ine::LiftedHRepresentation{N,GMPRational}) = LiftedHRepresentation{N,T}(Array{T}(ine.A), copy(ine.linset))

Base.convert{N,T}(::Type{SimpleVRepresentation{N,T}}, ext::SimpleVRepresentation{N,GMPRational}) = SimpleVRepresentation{N,T}(Array{T}(ext.V), Array{T}(ext.R), copy(ext.Vlinset), copy(ext.Rlinset))
Base.convert{N,T}(::Type{LiftedVRepresentation{N,T}}, ext::LiftedVRepresentation{N,GMPRational}) = LiftedVRepresentation{N,T}(Array{T}(ext.R), copy(ext.linset))

# converters Representation -> CDDMatrix

function Base.convert{N, T<:MyType}(::Type{CDDInequalityMatrix{N, T}}, ine::LiftedHRepresentation{N,T})
  matrix = initmatrix(ine.A, ine.linset, true)
  CDDInequalityMatrix{N, T}(matrix)
end
Base.convert{N, T<:MyType}(::Type{CDDInequalityMatrix{N, T}}, ine::HRepresentation{N,T}) = Base.convert(CDDInequalityMatrix{N,T}, LiftedHRepresentation(ine))

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ine::HRepresentation{N,T}) = Base.convert(CDDInequalityMatrix{N, T}, ine)

function Base.convert{N, T<:MyType}(::Type{CDDGeneratorMatrix{N, T}}, ext::LiftedVRepresentation{N,T})
  matrix = initmatrix(ext.R, ext.linset, false)
  CDDGeneratorMatrix{N, T}(matrix)
end
Base.convert{N, T<:MyType}(::Type{CDDGeneratorMatrix{N, T}}, ext::VRepresentation{N,T}) = Base.convert(CDDGeneratorMatrix{N,T}, LiftedVRepresentation{N,T}(ext))

Base.convert{N, T<:MyType}(::Type{CDDMatrix{N, T}}, ext::VRepresentation{N, T}) = Base.convert(CDDGeneratorMatrix{N, T}, ext)

# Specified T
Base.convert{N, T<:MyType, S<:Real}(::Type{CDDMatrix{N, T}}, repr::Representation{N, S}) = Base.convert(CDDMatrix{N, T}, Base.convert(Representation{N, T}, repr))
# Unspecified T
#Base.convert{S<:MyType}(::Type{CDDMatrix}, repr::Representation{S}) = Base.convert(CDDMatrix{fulldim(repr), S}, repr)
Base.convert{N, S}(::Type{CDDMatrix}, repr::Representation{N, S})         = Base.convert(CDDMatrix{fulldim(repr), mytypefor(S)}, repr)
# Base.convert{S<:Integer}(::Type{CDDMatrix}, repr::Representation{S}) = Base.convert(CDDMatrix{fulldim(repr), GMPRational}, Base.convert(Representation{GMPRational}, repr))
# Base.convert{S<:Integer}(::Type{CDDMatrix}, repr::Representation{Rational{S}}) = Base.convert(CDDMatrix{fulldim(repr), GMPRational}, Base.convert(Representation{GMPRational}, repr))
# Base.convert{S<:BigFloat}(::Type{CDDMatrix}, repr::Representation{S}) = error("not implemented yet")
# Base.convert(::Type{CDDMatrix}, repr::Representation{Float32}) = Base.convert(CDDMatrix{fulldim(repr), Cdouble}, Base.convert(Representation{Cdouble}, repr))
# Base.convert(::Type{CDDMatrix}, repr::Representation{Float64}) = Base.convert(CDDMatrix{fulldim(repr), Cdouble}, repr)
# Base.convert(::Type{CDDMatrix}, repr::Representation{GMPRational}) = Base.convert(CDDMatrix{fulldim(repr), GMPRational}, repr)

Base.convert{N,T<:Real}(::Type{CDDInequalityMatrix}, ine::HRepresentation{N,T}) = Base.convert(CDDMatrix, ine)
Base.convert{N,T<:Real}(::Type{CDDGeneratorMatrix}, ext::VRepresentation{N,T}) = Base.convert(CDDMatrix, ext)


# converters CDDMatrix -> Representation

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

function Base.convert{N, T<:MyType}(::Type{LiftedHRepresentation{N, T}}, matrix::CDDInequalityMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 1

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  A = extractA(mat)
  LiftedHRepresentation(A, linset)
end

Base.convert{N, T<:MyType}(::Type{Representation{N, T}}, ine::CDDInequalityMatrix{N, T}) = Base.convert(LiftedHRepresentation{N, T}, ine)

function Base.convert{N, T<:MyType}(::Type{LiftedVRepresentation{N, T}}, matrix::CDDGeneratorMatrix{N, T})
  mat = unsafe_load(matrix.matrix)
  @assert mat.representation == 2

  linset = Base.convert(IntSet, CDDSet(mat.linset, mat.rowsize))
  A = extractA(mat)
  LiftedVRepresentation(A, linset)
end

Base.convert{N, T<:MyType}(::Type{Representation{N, T}}, ine::CDDGeneratorMatrix{N, T}) = Base.convert(LiftedVRepresentation{N, T}, ine)

Base.convert{N, T<:MyType, S<:Real}(::Type{HRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{LiftedHRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{SimpleHRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(SimpleHRepresentation{N, S}, Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix)))
Base.convert{N, T<:MyType, S<:Real}(::Type{VRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{LiftedVRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix))
Base.convert{N, T<:MyType, S<:Real}(::Type{SimpleVRepresentation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(SimpleVRepresentation{N, S}, Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix)))
Base.convert{N, T<:MyType, S<:Real}(::Type{Representation{N, S}}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, S}, Base.convert(Representation{N, T}, matrix))
Base.convert{N, T<:MyType}(::Type{Representation}, matrix::CDDMatrix{N, T}) = Base.convert(Representation{N, T}, matrix)
