import Base.+

type MyRat
  data1::Ptr{Void}
  alloc1::Int32
  size1::Int32
  data2::Ptr{Void}
  alloc2::Int32
  size2::Int32

  function MyRat()
    r = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{MyRat},), &r)
    finalizer(r, _mpq_clear_fn)
    return r
  end

  function MyRat(a::Int, b::Int)
    r = new()
    ccall((:__gmpq_init, :libgmp), Void, (Ptr{MyRat},), &r)
    ccall((:__gmpq_set_ui, :libgmp), Void, 
    (Ptr{MyRat}, Int, Int), &r, a, b)
    finalizer(r, _mpq_clear_fn)
    return r
  end
end

function +(a::MyRat, b::MyRat)
  r = MyRat()
  ccall((:__gmpq_add, :libgmp), Void,
  (Ptr{MyRat}, Ptr{MyRat}, Ptr{MyRat}), &r, &a, &b)
  return r
end

function doit()
  a = MyRat(1, 12345678912347)
  for i in 0:999999
    b = MyRat(i, 12345678912347)
    a += b
  end
  return a
end

function _mpq_clear_fn(a::MyRat)
  ccall((:__gmpq_clear, :libgmp), Void, (Ptr{MyRat},), &a)
end

export doit, MyRat
