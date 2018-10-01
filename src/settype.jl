function dd_set_initialize(maxel::Clong)
    x = Ref{Cset_type}(0)
    @cdd_ccall set_initialize Nothing (Ref{Ptr{Culong}}, Clong) x maxel
    x[]
end

function dd_set_addelem(st::Cset_type, el::Clong)
    @cdd_ccall set_addelem Nothing (Cset_type, Clong) st convert(Clong, el)
end

function dd_set_member(st::Cset_type, el::Clong)
    1 == (@cdd_ccall set_member Cint (Clong, Cset_type) el st)
end
dd_set_member(st::Cset_type, el) = dd_set_member(st, Clong(el))

function dd_set_card(st::Cset_type)
    @cdd_ccall set_card Clong (Cset_type,) st
end

function dd_settype(st::Cset_type, s, offset::Integer=0)
    for el in s
        dd_set_addelem(st, Clong(offset+el))
    end
end

# CDDSet

mutable struct CDDSet
    s::Cset_type
    maxel::Clong
end

function CDDSet(s, maxel::Clong, offset::Integer)
    st = dd_set_initialize(maxel)
    dd_settype(st, s, offset)
    CDDSet(st, maxel)
end
CDDSet(s, maxel, offset::Integer) = CDDSet(s, Clong(maxel), offset)

function Base.convert(::Type{BitSet}, st::CDDSet)
    s = BitSet()
    for i = 1:st.maxel
        if dd_set_member(st.s, convert(Clong, i))
            push!(s, i)
        end
    end
    s
end

# I don't want it to overwrite Base.convert behaviour
function myconvert(::Type{BitSet}, a::Matrix)
    b = Array{Bool}(a)
    s = BitSet()
    for i = 1:length(a)
        if b[i]
            push!(s, i)
        end
    end
    s
end

export CDDSet
