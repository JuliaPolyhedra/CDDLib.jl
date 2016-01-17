import Base.-, Base.promote_rule, Base.==, Base.zero, Base.zeros

immutable GMPInteger
  alloc::Cint
  size::Cint
  data::Ptr{UInt32}
end

type GMPRationalMut
  num::GMPInteger
  den::GMPInteger

  function GMPRationalMut()
    m = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{GMPRationalMut},), &m)
    #finalizer(m, _mpq_clear_fn) # Used in immutable
    m
  end

end

function GMPRationalMut(a::Int, b::Int)
  m = GMPRationalMut()
  ccall((:__gmpq_set_ui, :libgmp), Void,
  (Ptr{GMPRationalMut}, Int, Int), &m, a, b)
  m
end

Base.zero(::Type{GMPRationalMut}) = GMPRationalMut(0, 1)

# I cannot have a finalizer for an immutable so you are responsibe to free it if you use it
immutable GMPRational <: Real
  num::GMPInteger
  den::GMPInteger
  function GMPRational(m::GMPRationalMut)
    r = new(m.num, m.den)
    r
  end

end

function myfree(a::Array{GMPRational})
  for el in a
    ccall((:__gmpq_clear, :libgmp), Void, (Ptr{GMPRational},), &el)
  end
end

Base.convert(::Type{GMPRational}, x::GMPRationalMut) = GMPRational(x)

function GMPRational()
  GMPRational(GMPRationalMut())
end

function GMPRational(a::Int, b::Int)
  GMPRational(GMPRationalMut(a, b))
end
Base.zero(::Type{GMPRational}) = GMPRational(0, 1)
# The default zeros uses the same rational for each element
# so each element has the same data1 and data2 pointers...
function Base.zeros(::Type{GMPRational}, dims...)
  ret = Array(GMPRational, dims...)
  for i in eachindex(ret)
    #@inbounds ret[i] = Base.zero(GMPRational)
    ret[i] = Base.zero(GMPRational)
  end
  ret
end

function GMPRational(a::Rational{BigInt})
  m = GMPRationalMut()
  ccall((:__gmpq_set_num, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{BigInt}), &m, &a.num)
  ccall((:__gmpq_set_den, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{BigInt}), &m, &a.den)
  GMPRational(m)
end

function -(a::GMPRational)
  m = GMPRationalMut()
  ccall((:__gmpq_neg, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{GMPRational}), &m, &a)
  GMPRational(m)
end


function Base.show(io::IO, x::GMPInteger)
  Base.show(io, (x.alloc, x.size, unsafe_load(x.data)))
end

# function Base.show(io::IO, x::GMPRational)
#   Base.show(io, ((x.size1, x.alloc1, unsafe_load(x.data1)), (x.size2, x.alloc2, unsafe_load(x.data2, 1))))
#   #Base.show(io, (x.num, x.den))
# end
function Base.show(io::IO, x::GMPRational)
  Base.show(io, Rational(x))
end

Base.convert(::Type{GMPRational}, a::Rational) = GMPRational(Rational{BigInt}(a))
Base.convert{T<:Integer}(::Type{GMPRational}, a::T) = GMPRational(a//BigInt(1))
function Base.convert(::Type{Rational{BigInt}}, r::GMPRational)
  a = BigInt()
  ccall((:__gmpq_get_num, :libgmp), Void,
  (Ptr{BigInt}, Ptr{GMPRational}), &a, &r)
  b = BigInt()
  ccall((:__gmpq_get_den, :libgmp), Void,
  (Ptr{BigInt}, Ptr{GMPRational}), &b, &r)
  a // b
end
Base.convert(::Type{Rational}, r::GMPRational) = Base.convert(Rational{BigInt}, r)
# I need to define the following conversion because of ambuity with Real -> Bool
Base.convert{T<:Integer}(::Type{Rational{T}}, a::GMPRational) = Base.convert(Rational{T}, Rational(a))
Base.convert(::Type{Bool}, a::GMPRational) = Base.convert(Bool, Rational(a))
Base.convert{T<:Integer}(::Type{T}, a::GMPRational) = Base.convert(T, Rational(a))

promote_rule{T<:Integer}(::Type{GMPRational}, ::Type{T}) = GMPRational

function _mpq_clear_fn(a::GMPRational)
  ccall((:__gmpq_clear, :libgmp), Void, (Ptr{GMPRational},), &a)
end

==(x::GMPRational, y::GMPRational) = Rational(x) == Rational(y)

typealias MyType Union{GMPRational, Cdouble}

# Default type mapping
# Base.convert(::Type{MyType}, x::BigInt) = error("not implemented yet")
#
# Base.convert{T<:Integer}(::Type{GMPRational}, x::T) = GMPRational(Int(x), 1)
# Base.convert{T<:Integer}(::Type{MyType}, x::T) = GMPRational(x)
# Base.convert{T<:Integer,n}(::Type{Array{MyType,n}}, x::Array{T,n}) = Array{GMPRational}(x)
#
# Base.convert(::Type{MyType}, x::Rational{BigInt}) = error("not implemented yet")
# Base.convert{T<:Integer}(::Type{MyType}, x::Rational{T}) = GMPRational(Int(x.num), Int(x.den))
# Base.convert{T<:BigFloat}(::Type{MyType}, x::T) = error("not implemented yet")
# Base.convert(::Type{MyType}, x::Float32) = Cdouble(x)

#Base.convert(::Type{MyType}, x::BigInt) = error("not implemented yet")
#Base.convert(::Type{MyType}, x::Rational{BigInt}) = error("not implemented yet")
#Base.convert{T<:Integer}(::Type{MyType}, x::Rational{T}) = GMPRational(Int(x.num), Int(x.den))
#Base.convert{T<:BigFloat}(::Type{MyType}, x::T) = error("not implemented yet")
#Base.convert(::Type{MyType}, x::Float32) = Cdouble(x)

#mytypeid(::Type{Cdouble}) = 1
#mytypeid(::Type{GMPRational}) = 2

function myconvert(::Type{Array}, x::Ptr{Cdouble}, n)
  y = Array{Cdouble, 1}(n)
  for i = 1:n
    y[i] = unsafe_load(x, i)
  end
  y
end
function myconvert(::Type{Array}, x::Ptr{GMPRational}, n)
  y = Array{GMPRationalMut, 1}(n)
  for i = 1:n
    y[i] = GMPRationalMut()
    ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(y[i]), x+(i*sizeof(GMPRational)))
  end
  Array{GMPRational}(y)
end

export MyType, GMPRational
