function dd_set_addelem(st::Ptr{Culong}, el::Clong)
  @cdd0_ccall set_addelem Void (Ptr{Culong}, Clong) st convert(Clong, el)
end

function dd_set_initialize(maxel::Clong)
  x = Ref{Ptr{Culong}}(0)
  @cdd0_ccall set_initialize Void (Ref{Ptr{Culong}}, Clong) x maxel
  x[]
end

function dd_set_member(st::Ptr{Culong}, el::Clong)
  1 == (@cdd0_ccall set_member Cint (Clong, Ptr{Culong}) el st)
end

function dd_set_card(st::Ptr{Culong})
  @cdd0_ccall set_card Clong (Ptr{Culong},) st
end

function intsettosettype(st::Ptr{Culong}, s::IntSet, offset::Integer)
  offset = Clong(offset)
  for el in s
    dd_set_addelem(st, convert(Clong, offset+el))
  end
end

intsettosettype(st::Ptr{Culong}, s::IntSet) = intsettosettype(st, s, 0)

# CDDSet

type CDDSet
  s::Ptr{Culong}
  maxel::Clong
end

function CDDSet(s::IntSet, len::Integer)
  if len < 1
    error("The length of a CDDSet should be positive")
  end
  maxel = convert(Clong, len)
  st = dd_set_initialize(convert(Clong, maxel))
  intsettosettype(st, s)
  CDDSet(st, maxel)
end

function Base.convert(::Type{IntSet}, st::CDDSet)
  s = IntSet()
  for i = 1:st.maxel
    if dd_set_member(st.s, convert(Clong, i))
      push!(s, i)
    end
  end
  s
end

# I don't want it to overwrite Base.convert behaviour
function myconvert{T<:MyType}(::Type{IntSet}, a::Array{T, 1})
  b = Array{Bool}(a)
  s = IntSet()
  for i = 1:length(a)
    if b[i]
      push!(s, i)
    end
  end
  s
end

export CDDSet
