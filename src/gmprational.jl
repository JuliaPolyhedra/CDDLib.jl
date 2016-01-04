type GMPRational
  data1::Ptr{Void}
  alloc1::Int32
  size1::Int32
  data2::Ptr{Void}
  alloc2::Int32
  size2::Int32

  function GMPRational()
    r = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{GMPRational},), &r)
    finalizer(r, _mpq_clear_fn)
    return r
  end

  function GMPRational(a::Int, b::Int)
    r = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{GMPRational},), &r)
    ccall((:__gmpq_set_ui, :libgmp), Void,
    (Ptr{GMPRational}, Int, Int), &r, a, b)
    finalizer(r, _mpq_clear_fn)
    return r
  end

  function GMPRational(a::Rational{BigInt})
    r = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{GMPRational},), &r)
    ccall((:__gmpq_set_num, :libgmp), Void,
    (Ptr{GMPRational}, Ptr{BigInt}), &r, &a.num)
    ccall((:__gmpq_set_den, :libgmp), Void,
    (Ptr{GMPRational}, Ptr{BigInt}), &r, &a.den)
    finalizer(r, _mpq_clear_fn)
    return r
  end

end

Base.convert(::Type{GMPRational}, a::Rational) = GMPRational(Rational{BigInt}(a))
Base.convert(::Type{GMPRational}, a::BigInt) = GMPRational(a//1)
function Base.convert(::Type{Rational}, r::GMPRational)
  a = BigInt()
  ccall((:__gmpq_get_num, :libgmp), Void,
  (Ptr{BigInt}, Ptr{GMPRational}), &a, &r)
  if a == 0
    a // 1
  else
    b = BigInt()
    ccall((:__gmpq_get_den, :libgmp), Void,
    (Ptr{BigInt}, Ptr{GMPRational}), &b, &r)
    a // b
  end
end

function _mpq_clear_fn(a::GMPRational)
  ccall((:__gmpq_clear, :libgmp), Void, (Ptr{GMPRational},), &a)
end
