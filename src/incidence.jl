_getrepfor(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:HRepElement{T}}) where {T} = getine(p)
_getrepfor(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:VRepElement{T}}) where {T} = getext(p)
_getincidence(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:HRepElement{T}}) where {T} = gethincidence(p)
_getincidence(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:VRepElement{T}}) where {T} = getvincidence(p)
_incel(p::Polyhedron{T}, inc::Polyhedra.IncidentElements{T}, idx) where {T} = get(p, idx)
_incel(p::Polyhedron{T}, inc::Polyhedra.IncidentIndices{T}, idx) where {T} = idx

function Base.get(p::Polyhedron{T}, inc::Polyhedra.Incident{T, ElemT}) where {T, ElemT}
    rep = _getrepfor(p, inc)
    incidence = _getincidence(p, inc)
    row = incidence[inc.idx.value]

    incT = Polyhedra._inctype(inc)
    incs = incT[]
    sizehint!(incs, length(row))

    for i in incidence[inc.idx.value]
        idx = Polyhedra.Index{T, ElemT}(i)
        isvalid(rep, idx) && push!(incs, _incel(p, inc, idx))
    end
    return incs
end
