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

function dd_copyAmatrixvectorizedbycolumn(mat::Cdd_Amatrix{Cdouble}, M::Array{Cdouble, 2}, m::Cdd_rowrange, n::Cdd_colrange)
  @ddf_ccall CopyAmatrixVectorizedByColumn Void (Cdd_Amatrix{Cdouble}, Ptr{Cdouble}, Cdd_rowrange, Cdd_colrange) mat M m n
end
function dd_copyAmatrixvectorizedbycolumn(mat::Cdd_Amatrix{GMPRational}, M::Array{GMPRational, 2}, m::Cdd_rowrange, n::Cdd_colrange)
  @dd_ccall CopyAmatrixVectorizedByColumn Void (Cdd_Amatrix{GMPRational}, Ptr{GMPRational}, Cdd_rowrange, Cdd_colrange) mat M m n
end

function dd_copyArow(acopy::Cdd_Arow{Cdouble}, a::Array{Cdouble, 1}, d::Cdd_colrange)
  @ddf_ccall CopyArow Void (Cdd_Arow{Cdouble}, Cdd_Arow{Cdouble}, Cdd_colrange) acopy a d
end
function dd_copyArow(acopy::Cdd_Arow{GMPRational}, a::Array{GMPRational, 1}, d::Cdd_colrange)
  @dd_ccall CopyArow Void (Cdd_Arow{GMPRational}, Cdd_Arow{GMPRational}, Cdd_colrange) acopy a d
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


function initmatrix{T<:MyType}(M::Array{T, 2}, linset, inequality::Bool)
  m = Cdd_rowrange(size(M, 1))
  n = Cdd_colrange(size(M, 2))
  matrix = dd_creatematrix(T, m, n)
  mat = unsafe_load(matrix)
  dd_copyAmatrixvectorizedbycolumn(mat.matrix, M, m, n)
  dd_settype(mat.linset, linset)
  dd_setmatrixnumbertype(matrix)
  dd_setmatrixrepresentationtype(matrix, inequality)
  matrix
end

abstract CDDMatrix{T <: MyType}

function Base.size{T<:MyType}(matrix::CDDMatrix{T})
  mat = unsafe_load(matrix.matrix)
  (Int64(mat.rowsize), Int64(mat.colsize))
end

Base.size{T<:MyType}(matrix::CDDMatrix{T}, i::Integer) = Base.size(matrix)[i]

function dd_freematrix(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  @ddf_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{Cdouble}},) matrix
end
function dd_freematrix(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  @dd_ccall FreeMatrix Void (Ptr{Cdd_MatrixData{GMPRational}},) matrix
end
function myfree{T<:MyType}(matrix::CDDMatrix{T})
  dd_freematrix(matrix.matrix)
end

type CDDInequalityMatrix{T <: MyType} <: CDDMatrix{T}
  matrix::Ptr{Cdd_MatrixData{T}}

  function CDDInequalityMatrix(matrix::Ptr{Cdd_MatrixData{T}})
    m = new(matrix)
    finalizer(m, myfree)
    m
  end
end

CDDInequalityMatrix{T<:MyType}(matrix::Ptr{Cdd_MatrixData{T}}) = CDDInequalityMatrix{T}(matrix)

function isaninequalityrepresentation(matrix::CDDInequalityMatrix)
  true
end

type CDDGeneratorMatrix{T <: MyType} <: CDDMatrix{T}
  matrix::Ptr{Cdd_MatrixData{T}}

  function CDDGeneratorMatrix(matrix::Ptr{Cdd_MatrixData{T}})
    m = new(matrix)
    finalizer(m, myfree)
    m
  end
end

CDDGeneratorMatrix{T<:MyType}(matrix::Ptr{Cdd_MatrixData{T}}) = CDDGeneratorMatrix{T}(matrix)

function isaninequalityrepresentation(matrix::CDDGeneratorMatrix)
  false
end

function Base.show{T <: MyType}(io::IO, matrix::Cdd_MatrixData{T})
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
  (b, A) = extractAb(matrix)
  for i = 1:size(A, 1)
    print(io, " $(b[i])")
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
