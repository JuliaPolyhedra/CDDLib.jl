type CDDPolyhedraData{T<:MyType}
  representation::Cdd_RepresentationType
  # given representation
  homogeneous::Cdd_boolean
  d::Cdd_colrange
  m::Cdd_rowrange
  A::Cdd_Amatrix{T}
  # Inequality System:  m times d matrix
  numbtype::Cdd_NumberType
  child::Ptr{Void} # dd_ConePtr
  # pointing to the homogenized cone data
  m_alloc::Cdd_rowrange
  # allocated row size of matrix A
  d_alloc::Cdd_colrange
  # allocated col size of matrix A
  c::Cdd_Arow{T}
  # cost vector

  EqualityIndex::Cdd_rowflag
  # ith component is 1 if it is equality, -1 if it is strict inequality, 0 otherwise.

  IsEmpty::Cdd_boolean
  # This is to tell whether the set is empty or not

  NondegAssumed::Cdd_boolean
  InitBasisAtBottom::Cdd_boolean
  RestrictedEnumeration::Cdd_boolean
  RelaxedEnumeration::Cdd_boolean

  m1::Cdd_rowrange
  #    = m or m+1 (when representation=Inequality && !homogeneous)
  #    This data is written after dd_ConeDataLoad is called.  This
  #    determines the size of Ainc.
  AincGenerated::Cdd_boolean
  #    Indicates whether Ainc, Ared, Adom are all computed.
  #    All the variables below are valid only when this is TRUE
  ldim::Cdd_colrange
  # linearity dimension
  n::Cdd_bigrange
  #    the size of output = total number of rays
  #    in the computed cone + linearity dimension
  Ainc::Cdd_Aincidence
  #    incidence of input and output
  Ared::Cdd_rowset
  #    redundant set of rows whose removal results in a minimal system
  Adom::Cdd_rowset
  #    dominant set of rows (those containing all rays).
end

function dd_matrix2poly(matrix::Ptr{CDDMatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  poly = @cddf_ccall DDMatrix2Poly Ptr{CDDPolyhedraData{Cdouble}} (Ptr{CDDMatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix err
  myerror(err[])
  poly
end
function dd_matrix2poly(matrix::Ptr{CDDMatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  poly = @cdd_ccall DDMatrix2Poly Ptr{CDDPolyhedraData{GMPRational}} (Ptr{CDDMatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix err
  myerror(err[])
  poly
end

type CDDPolyhedra{T<:MyType}
  poly::Ptr{CDDPolyhedraData{T}}
  inequality::Bool # The input type is inequality

  function CDDPolyhedra(matrix::CDDMatrix{T})
    polyptr = dd_matrix2poly(matrix.matrix)
    poly = new(polyptr, isaninequalityrepresentation(matrix))
    finalizer(poly, myfree)
    poly
  end

end

function myfree(poly::CDDPolyhedra{Cdouble})
  @cddf_ccall FreePolyhedra Void (Ptr{CDDPolyhedra{Cdouble}},) poly.poly
end
function myfree(poly::CDDPolyhedra{GMPRational})
  @cdd_ccall FreePolyhedra Void (Ptr{CDDPolyhedra{GMPRational}},) poly.poly
end

CDDPolyhedra{T <: Real, S <: Real}(A::Array{T, 2}, c::Array{S, 1}, inequality::Bool, linset::IntSet) = CDDPolyhedra(CDDMatrixData(A, c, inequality, linset)) # TODO change this
CDDPolyhedra{T <: Real, S <: Real}(A::Array{T, 2}, c::Array{S, 1}, inequality::Bool) = CDDPolyhedra(A, c, inequality, IntSet([]))

function Base.convert{T<:MyType}(::Type{CDDPolyhedra}, matrix::CDDMatrix{T})
  CDDPolyhedra{T}(matrix)
end
Base.convert{T <: Real}(::Type{CDDPolyhedra}, desc::Description{T}) = CDDPolyhedra(CDDMatrix(desc))

function dd_copyinequalities(poly::Ptr{CDDPolyhedraData{Cdouble}})
  @cddf_ccall CopyInequalities Ptr{CDDMatrixData{Cdouble}} (Ptr{CDDPolyhedraData{Cdouble}},) poly
end
function dd_copyinequalities(poly::Ptr{CDDPolyhedraData{GMPRational}})
  @cdd_ccall CopyInequalities Ptr{CDDMatrixData{GMPRational}} (Ptr{CDDPolyhedraData{GMPRational}},) poly
end
function copyinequalities{T<:MyType}(poly::CDDPolyhedra{T})
  CDDInequalityMatrix(dd_copyinequalities(poly.poly))
end

function dd_copygenerators(poly::Ptr{CDDPolyhedraData{Cdouble}})
  @cddf_ccall CopyGenerators Ptr{CDDMatrixData{Cdouble}} (Ptr{CDDPolyhedraData{Cdouble}},) poly
end
function dd_copygenerators(poly::Ptr{CDDPolyhedraData{GMPRational}})
  @cdd_ccall CopyGenerators Ptr{CDDMatrixData{GMPRational}} (Ptr{CDDPolyhedraData{GMPRational}},) poly
end

function copygenerators{T<:MyType}(poly::CDDPolyhedra{T})
  CDDGeneratorMatrix(dd_copygenerators(poly.poly))
end

function switchinputtype!(poly::CDDPolyhedra)
  if poly.inequality
    poly.poly = convert(Ptr{CDDPolyhedraData}, copygeneratorsptr(poly))
  else
    poly.poly = convert(Ptr{CDDPolyhedraData}, copyinequalitiesptr(poly))
  end
  poly.inequality = ~poly.inequality
end

export CDDPolyhedraData, CDDPolyhedra, copyinequalities, copygenerators, switchinputtype!
