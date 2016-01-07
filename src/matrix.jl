type CDDMatrixData{T <: MyType}
  rowsize::Clong # dd[f]_rowrange
  linset::Ptr{Culong} #dd[f]_rowset
  colsize::Clong # dd[f]_colrange
  representation::Cint # dd[f]_RepresentationType: enum dd_Unspecified, dd_Inequality, dd_Generator
  numbtype::Cint # dd[f]_NumberType: enum dd_Unknown, dd_Real, dd_Rational, dd_Integer
  matrix::Ptr{Ptr{T}} # dd[f]_Amatrix
  objective::Cint # dd[f]_LPObjectiveType: enum dd_LPnone, dd_LPmax, dd_LPmin
  rowvec::Ptr{T} # dd[f]_Arow
end

function dd_creatematrix(::Type{Cdouble}, m::Clong, n::Clong)
  @cddf_ccall CreateMatrix Ptr{CDDMatrixData{Cdouble}} (Clong, Clong) m n
end
function dd_creatematrix(::Type{GMPRational}, m::Clong, n::Clong)
  @cdd_ccall CreateMatrix Ptr{CDDMatrixData{GMPRational}} (Clong, Clong) m n
end

function copyAmatrixvectorizedbycolumn(mat::Ptr{Ptr{Cdouble}}, M::Array{Cdouble, 2}, m::Clong, n::Clong)
  @cddf_ccall CopyAmatrixVectorizedByColumn Void (Ptr{Ptr{Cdouble}}, Ptr{Cdouble}, Clong, Clong) mat M m n
end
function copyAmatrixvectorizedbycolumn(mat::Ptr{Ptr{GMPRational}}, M::Array{GMPRational, 2}, m::Clong, n::Clong)
  @cdd_ccall CopyAmatrixVectorizedByColumn Void (Ptr{Ptr{GMPRational}}, Ptr{GMPRational}, Clong, Clong) mat M m n
end

function setmatrixnumbertype(matrix::Ptr{CDDMatrixData{Cdouble}})
  @cddf_ccall SetMatrixNumberType Void (Ptr{CDDMatrixData{Cdouble}}, Cint) matrix 1
end
function setmatrixnumbertype(matrix::Ptr{CDDMatrixData{GMPRational}})
  @cdd_ccall SetMatrixNumberType Void (Ptr{CDDMatrixData{GMPRational}}, Cint) matrix 2
end

function setmatrixrepresentationtype(matrix::Ptr{CDDMatrixData{Cdouble}}, inequality::Bool)
  @cddf_ccall SetMatrixRepresentationType Void (Ptr{CDDMatrixData{Cdouble}}, Cint) matrix (inequality ? 1 : 2)
end
function setmatrixrepresentationtype(matrix::Ptr{CDDMatrixData{GMPRational}}, inequality::Bool)
  @cdd_ccall SetMatrixRepresentationType Void (Ptr{CDDMatrixData{GMPRational}}, Cint) matrix (inequality ? 1 : 2)
end


function initmatrix{T<:MyType}(M::Array{T, 2}, linset, inequality::Bool)
  m = Clong(size(M, 1))
  n = Clong(size(M, 2))
  matrix = dd_creatematrix(T, m, n)
  mat = unsafe_load(matrix)
  copyAmatrixvectorizedbycolumn(mat.matrix, M, m, n)
  intsettosettype(mat.linset, linset)
  setmatrixnumbertype(matrix)
  setmatrixrepresentationtype(matrix, inequality)
  matrix
end


isaninequalityrepresentation(matrix::CDDMatrixData) = matrix.representation == 1

abstract CDDMatrix{T <: MyType}

function Base.size{T<:MyType}(matrix::CDDMatrix{T})
  mat = unsafe_load(matrix.matrix)
  (Int64(mat.rowsize), Int64(mat.colsize))
end

Base.size{T<:MyType}(matrix::CDDMatrix{T}, i::Integer) = Base.size(matrix)[i]

function dd_freematrix(matrix::Ptr{CDDMatrixData{Cdouble}})
  @cddf_ccall FreeMatrix Void (Ptr{CDDMatrixData{Cdouble}},) matrix
end
function dd_freematrix(matrix::Ptr{CDDMatrixData{GMPRational}})
  @cdd_ccall FreeMatrix Void (Ptr{CDDMatrixData{GMPRational}},) matrix
end
function myfree{T<:MyType}(matrix::CDDMatrix{T})
  dd_freematrix(matrix.matrix)
end

type CDDInequalityMatrix{T <: MyType} <: CDDMatrix{T}
  matrix::Ptr{CDDMatrixData{T}}

  function CDDInequalityMatrix(matrix::Ptr{CDDMatrixData{T}})
    m = new(matrix)
    finalizer(m, myfree)
    m
  end

end

CDDInequalityMatrix{T<:MyType}(matrix::Ptr{CDDMatrixData{T}}) = CDDInequalityMatrix{T}(matrix)

function isaninequalityrepresentation(matrix::CDDInequalityMatrix)
  true
end

type CDDGeneratorMatrix{T <: MyType} <: CDDMatrix{T}
  matrix::Ptr{CDDMatrixData{T}}

  function CDDGeneratorMatrix(matrix::Ptr{CDDMatrixData{T}})
    m = new(matrix)
    finalizer(m, myfree)
    m
  end

end

CDDGeneratorMatrix{T<:MyType}(matrix::Ptr{CDDMatrixData{T}}) = CDDGeneratorMatrix{T}(matrix)

function isaninequalityrepresentation(matrix::CDDGeneratorMatrix)
  false
end

function Base.show{T <: MyType}(io::IO, matrix::CDDMatrixData{T})
  if matrix.representation == 1
    println(io, "H-representation")
  else
    println(io, "V-representation")
  end

  linsize = dd_set_card(matrix.linset)
  if linsize > 0
    print(io, "linearity $linsize ");
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

export CDDMatrixData, CDDMatrix, CDDInequalityMatrix, CDDGeneratorMatrix, isaninequalityrepresentation
