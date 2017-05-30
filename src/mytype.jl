import Base.+, Base.-, Base.*, Base.promote_rule, Base.==, Base.zero, Base.zeros

# It is immutable so that it is stored by value in the structures
# GMPRational and GMPRationalMut and not by reference
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
    # No need to clear anything since the num and den are used by
    # the GMPRational that is created
    #finalizer(m, _mpq_clear_fn)
    m
  end
end

function Base.convert(::Type{GMPRationalMut}, a::Rational{BigInt})
  m = GMPRationalMut()
  ccall((:__gmpq_set_num, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{BigInt}), &m, &a.num)
  ccall((:__gmpq_set_den, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{BigInt}), &m, &a.den)
  m
end
Base.convert(::Type{GMPRationalMut}, a::Rational) = GMPRationalMut(Rational{BigInt}(a))
Base.convert(::Type{GMPRationalMut}, a::AbstractFloat) = GMPRationalMut(Rational(a))

# Can do it faster for Int
function GMPRationalMut(a::Int, b::Int)
  if b < 0
    a = -a
    b = -b
  end
  m = GMPRationalMut()
  ccall((:__gmpq_set_si, :libgmp), Void,
  (Ptr{GMPRationalMut}, Clong, Culong), &m, a, b)
  m
end
Base.convert(::Type{GMPRationalMut}, a::Int) = GMPRationalMut(a, 1)
Base.convert(::Type{GMPRationalMut}, a::Rational{Int}) = GMPRationalMut(a.num, a.den)

Base.zero(::Type{GMPRationalMut}) = GMPRationalMut(0)

# I cannot have a finalizer for an immutable so you are responsibe to free it
# if you use it using e.g. myfree define below
immutable GMPRational <: Real
  num::GMPInteger
  den::GMPInteger
  function GMPRational(m::GMPRationalMut)
    r = new(m.num, m.den)
    r
  end
end

function myfree(a::Array{Cdouble})
  # nothing to free
end
function myfree(a::Array{GMPRational})
  for el in a
    ccall((:__gmpq_clear, :libgmp), Void, (Ptr{GMPRational},), &el)
  end
end

Base.convert(::Type{GMPRational}, x::GMPRationalMut) = GMPRational(x)

GMPRational() = GMPRational(GMPRationalMut())

GMPRational{T<:Integer,S<:Integer}(a::S, b::T) = GMPRational(GMPRationalMut(a, b))
Base.convert{T<:Real}(::Type{GMPRational}, a::T) = GMPRational(GMPRationalMut(a))
Base.convert(::Type{GMPRational}, a::GMPRational) = a

Base.zero(::Type{GMPRational}) = GMPRational(0)

# The default zeros uses the same rational for each element
# so each element has the same data1 and data2 pointers...
# This is why I need to redefine it
function Base.zeros(::Type{GMPRational}, dims...)
  ret = Array(GMPRational, dims...)
  for i in eachindex(ret)
    ret[i] = Base.zero(GMPRational)
  end
  ret
end

function -(a::GMPRational)
  m = GMPRationalMut()
  ccall((:__gmpq_neg, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{GMPRational}), &m, &a)
  GMPRational(m)
end
function *(a::GMPRational, b::GMPRational)
  m = GMPRationalMut()
  ccall((:__gmpq_mul, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{GMPRational}, Ptr{GMPRational}), &m, &a, &b)
  GMPRational(m)
end
function +(a::GMPRational, b::GMPRational)
  m = GMPRationalMut()
  ccall((:__gmpq_add, :libgmp), Void,
  (Ptr{GMPRationalMut}, Ptr{GMPRational}, Ptr{GMPRational}), &m, &a, &b)
  GMPRational(m)
end

# Debug
function Base.show(io::IO, x::GMPInteger)
  Base.show(io, (x.alloc, x.size, unsafe_load(x.data)))
end

function Base.show(io::IO, x::GMPRational)
  Base.show(io, Rational(x))
end

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

==(x::GMPRational, y::GMPRational) = Rational(x) == Rational(y)

const PolyType = Union{Rational{BigInt}, Cdouble}
const MyType = Union{GMPRational, Cdouble}

mytype(::Type{Cdouble}) = Cdouble
mytype(::Type{Rational{BigInt}}) = GMPRational
polytype(::Type{Cdouble}) = Cdouble
polytype(::Type{GMPRational}) = Rational{BigInt}

mytypefor{T <: Real}(::Type{T})          = GMPRational
mytypefor{T <: AbstractFloat}(::Type{T}) = Cdouble
mytypefor{T <: MyType}(::Type{T})        = T
polytypefor{T <: Real}(::Type{T})          = Rational{BigInt}
polytypefor{T <: AbstractFloat}(::Type{T}) = Cdouble
polytypefor{T <: PolyType}(::Type{T})        = T

# Used by mathprogbase.jl
function myconvert{T<:Union{Cdouble, Clong}}(::Type{Array}, x::Ptr{T}, n)
  copy(unsafe_wrap(Array, x, n))
end
function myconvert(::Type{Array}, x::Ptr{GMPRational}, n)
  y = Array{GMPRationalMut, 1}(n)
  for i = 1:n
    y[i] = GMPRationalMut()
    ccall((:__gmpq_set, :libgmp), Void, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(y[i]), x+((i-1)*sizeof(GMPRational)))
  end
  Array{GMPRational}(y)
end

export MyType, GMPRational
