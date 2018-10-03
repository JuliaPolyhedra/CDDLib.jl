import Base.+, Base.-, Base.*, Base.promote_rule, Base.==, Base.zero

# It is immutable so that it is stored by value in the structures
# GMPRational and GMPRationalMut and not by reference
struct GMPInteger
    alloc::Cint
    size::Cint
    data::Ptr{UInt32}
end

mutable struct GMPRationalMut
    num::GMPInteger
    den::GMPInteger

    function GMPRationalMut()
        m = new()
        ccall((:__gmpq_init, :libgmp), Nothing, (Ptr{GMPRationalMut},), Ref(m))
        # No need to clear anything since the num and den are used by
        # the GMPRational that is created
        #finalizer(_mpq_clear_fn, m)
        m
    end
end

function Base.convert(::Type{GMPRationalMut}, a::Rational{BigInt})
    m = GMPRationalMut()
    ccall((:__gmpq_set_num, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Ptr{BigInt}), Ref(m), Ref(a.num))
    ccall((:__gmpq_set_den, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Ptr{BigInt}), Ref(m), Ref(a.den))
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
    ccall((:__gmpq_set_si, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Clong, Culong), Ref(m), a, b)
    m
end
Base.convert(::Type{GMPRationalMut}, a::Int) = GMPRationalMut(a, 1)
Base.convert(::Type{GMPRationalMut}, a::Rational{Int}) = GMPRationalMut(a.num, a.den)

Base.zero(::Type{GMPRationalMut}) = GMPRationalMut(0)

# I cannot have a finalizer for an immutable so you are responsibe to free it
# if you use it using e.g. myfree define below
struct GMPRational <: Real
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
        ccall((:__gmpq_clear, :libgmp), Nothing, (Ptr{GMPRational},), Ref(el))
    end
end

Base.convert(::Type{GMPRational}, x::GMPRationalMut) = GMPRational(x)

GMPRational() = GMPRational(GMPRationalMut())

GMPRational(a::S, b::T) where {T<:Integer,S<:Integer} = GMPRational(GMPRationalMut(a, b))
Base.convert(::Type{GMPRational}, a::T) where {T<:Real} = convert(GMPRational, convert(GMPRationalMut, a))
Base.convert(::Type{GMPRational}, a::GMPRational) = a

Base.zero(::Type{GMPRational}) = convert(GMPRational, 0)

# The default zeros uses the same rational for each element
# so each element has the same data1 and data2 pointers...
# This is why I need to redefine it
function Base.zeros(::Type{GMPRational}, dims::Union{Integer, AbstractUnitRange}...)
    ret = Array{GMPRational}(undef, dims...)
    for i in eachindex(ret)
        ret[i] = Base.zero(GMPRational)
    end
    ret
end

function -(a::GMPRational)
    m = GMPRationalMut()
    ccall((:__gmpq_neg, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Ptr{GMPRational}), Ref(m), Ref(a))
    GMPRational(m)
end
function *(a::GMPRational, b::GMPRational)
    m = GMPRationalMut()
    ccall((:__gmpq_mul, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Ptr{GMPRational}, Ptr{GMPRational}), Ref(m), Ref(a), Ref(b))
    GMPRational(m)
end
function +(a::GMPRational, b::GMPRational)
    m = GMPRationalMut()
    ccall((:__gmpq_add, :libgmp), Nothing,
          (Ptr{GMPRationalMut}, Ptr{GMPRational}, Ptr{GMPRational}), Ref(m), Ref(a), Ref(b))
    GMPRational(m)
end

# Debug
function Base.show(io::IO, x::GMPInteger)
    show(io, (x.alloc, x.size, unsafe_load(x.data)))
end

function Base.show(io::IO, x::GMPRational)
    show(io, convert(Rational, x))
end

function Base.convert(::Type{Rational{BigInt}}, r::GMPRational)
    a = BigInt()
    ccall((:__gmpq_get_num, :libgmp), Nothing,
          (Ptr{BigInt}, Ptr{GMPRational}), Ref(a), Ref(r))
    b = BigInt()
    ccall((:__gmpq_get_den, :libgmp), Nothing,
          (Ptr{BigInt}, Ptr{GMPRational}), Ref(b), Ref(r))
    a // b
end
Base.convert(::Type{Rational}, r::GMPRational) = Base.convert(Rational{BigInt}, r)
# I need to define the following conversion because of ambuity with Real -> Bool
Base.convert(::Type{Rational{T}}, a::GMPRational) where {T<:Integer} = Base.convert(Rational{T}, convert(Rational, a))
Base.convert(::Type{Bool}, a::GMPRational) = Base.convert(Bool, convert(Rational, a))
Base.convert(::Type{T}, a::GMPRational) where {T<:Integer} = Base.convert(T, convert(Rational, a))

promote_rule(::Type{GMPRational}, ::Type{T}) where {T<:Integer} = GMPRational

==(x::GMPRational, y::GMPRational) = Rational(x) == Rational(y)

const PolyType = Union{Rational{BigInt}, Cdouble}
const MyType = Union{GMPRational, Cdouble}

mytype(::Type{Cdouble}) = Cdouble
mytype(::Type{Rational{BigInt}}) = GMPRational
polytype(::Type{Cdouble}) = Cdouble
polytype(::Type{GMPRational}) = Rational{BigInt}

mytypefor(::Type{T}) where {T <: Real}          = GMPRational
mytypefor(::Type{T}) where {T <: AbstractFloat} = Cdouble
mytypefor(::Type{T}) where {T <: MyType}        = T
polytypefor(::Type{T}) where {T <: Real}          = Rational{BigInt}
polytypefor(::Type{T}) where {T <: AbstractFloat} = Cdouble
polytypefor(::Type{T}) where {T <: PolyType}        = T

# Used by mathprogbase.jl
function myconvert(::Type{Array}, x::Ptr{T}, n) where T<:Union{Cdouble, Clong}
    copy(unsafe_wrap(Array, x, n))
end
function myconvert(::Type{Array}, x::Ptr{GMPRational}, n)
    y = Vector{GMPRationalMut}(undef, n)
    for i = 1:n
        y[i] = GMPRationalMut()
        ccall((:__gmpq_set, :libgmp), Nothing, (Ptr{GMPRationalMut}, Ptr{GMPRational}), pointer_from_objref(y[i]), x+((i-1)*sizeof(GMPRational)))
    end
    Vector{GMPRational}(y)
end

export MyType, GMPRational
