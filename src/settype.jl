function dd_set_initialize(maxel::Clong)
  x = Ref{Cset_type}(0)
  @cdd_ccall set_initialize Void (Ref{Ptr{Culong}}, Clong) x maxel
  x[]
end

function dd_set_addelem(st::Cset_type, el::Clong)
  @cdd_ccall set_addelem Void (Cset_type, Clong) st convert(Clong, el)
end

function dd_set_member(st::Cset_type, el::Clong)
  1 == (@cdd_ccall set_member Cint (Clong, Cset_type) el st)
end

function dd_set_card(st::Cset_type)
  @cdd_ccall set_card Clong (Cset_type,) st
end

function dd_settype(st::Cset_type, s::IntSet, offset::Integer)
  offset = Clong(offset)
  for el in s
    dd_set_addelem(st, convert(Clong, offset+el))
  end
end

dd_settype(st::Cset_type, s::IntSet) = dd_settype(st, s, 0)

# CDDSet

type CDDSet
  s::Cset_type
  maxel::Clong
end

function CDDSet(s::IntSet, maxel::Clong)
  st = dd_set_initialize(maxel)
  dd_settype(st, s)
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
