_getrepfor(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:HRepElement{T}}) where {T} = getine(p)
_getrepfor(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:VRepElement{T}}) where {T} = getext(p)
_getincidence(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:HRepElement{T}}) where {T} = gethincidence(p)
_getincidence(p::Polyhedron{T}, ::Polyhedra.Incident{T, <:VRepElement{T}}) where {T} = getvincidence(p)
_incel(p::Polyhedron{T}, inc::Polyhedra.IncidentElements{T}, idx) where {T} = get(p, idx)
_incel(p::Polyhedron{T}, inc::Polyhedra.IncidentIndices{T}, idx) where {T} = idx

function Base.get(p::Polyhedron{T}, inc::Polyhedra.Incident{T, ElemT}) where {T, ElemT}
    rep = _getrepfor(p, inc)
    incidence = _getincidence(p, inc)
    incT = Polyhedra._inctype(inc)
    incs = incT[]
    for i in incidence[inc.idx.value]
        idx = Polyhedra.Index{T, ElemT}(i)
        isvalid(rep, idx) && push!(incs, _incel(p, inc, idx))
    end
    return incs
end


for loop_singular in (:point, :line, :ray, :hyperplane, :halfspace)
    singularstr = string(loop_singular)
    elemtype = Symbol(singularstr * "type")
    pluralstr = singularstr * "s"
    inc = Symbol("incident" * pluralstr)
    incidx = Symbol("incident" * singularstr * "indices")

    @eval begin
        # incidentpoints, incidentlines, incidentrays,
        # incidenthyperplanes, incidenthalfspaces
        Polyhedra.$inc(p::Polyhedron{T}, idx) where {T} =
            get(p, Polyhedra.IncidentElements{T, $elemtype(p)}(p, idx))

        # incidentpointindices, incidentlineindices, incidentrayindices,
        # incidenthyperplaneindices, incidenthalfspaceindices
        Polyhedra.$incidx(p::Polyhedron{T}, idx) where {T} =
            get(p, Polyhedra.IncidentIndices{T, $elemtype(p)}(p, idx))
    end
end
