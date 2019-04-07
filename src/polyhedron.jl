struct Library <: Polyhedra.Library
    precision::Symbol

    function Library(precision::Symbol=:float)
        if !(precision in [:float, :exact])
            error("Invalid precision, it should be :float or :exact")
        end
        new(precision)
    end
end
Polyhedra.similar_library(::Library, ::Polyhedra.FullDim, ::Type{T}) where T<:Union{Integer,Rational} = Library(:exact)
Polyhedra.similar_library(::Library, ::Polyhedra.FullDim, ::Type{T}) where T<:AbstractFloat = Library(:float)

mutable struct Polyhedron{T<:PolyType} <: Polyhedra.Polyhedron{T}
    ine::Union{Nothing, CDDInequalityMatrix{T}}
    ext::Union{Nothing, CDDGeneratorMatrix{T}}
    poly::Union{Nothing, CDDPolyhedra{T}}
    hlinearitydetected::Bool
    vlinearitydetected::Bool
    noredundantinequality::Bool
    noredundantgenerator::Bool

    function Polyhedron{T}(ine::CDDInequalityMatrix) where {T <: PolyType}
        new{T}(ine, nothing, nothing, false, false, false, false)
    end
    function Polyhedron{T}(ext::CDDGeneratorMatrix) where {T <: PolyType}
        new{T}(nothing, ext, nothing, false, false, false, false)
    end
    # function Polyhedron(poly::CDDPolyhedra{T})
    #   new(nothing, nothing, poly)
    # end
end
Polyhedra.FullDim(p::Polyhedron{T}) where {T} = Polyhedra.FullDim_rep(p.ine, p.ext)
Polyhedra.library(p::Polyhedron{T}) where {T} = Polyhedra.similar_library(Library(), Polyhedra.FullDim(p), T)
Polyhedra.hvectortype(::Union{Polyhedron{T}, Type{<:Polyhedron{T}}}) where {T} = Polyhedra.hvectortype(CDDInequalityMatrix{T})
Polyhedra.vvectortype(::Union{Polyhedron{T}, Type{<:Polyhedron{T}}}) where {T} = Polyhedra.vvectortype(CDDGenerator{T})
Polyhedra.similar_type(::Type{<:Polyhedron}, ::Polyhedra.FullDim, ::Type{T}) where {T} = Polyhedron{T}

Polyhedron(matrix::CDDMatrix{T}) where {T} = Polyhedron{T}(matrix)
Base.convert(::Type{Polyhedron{T}}, rep::Representation{T}) where {T} = Polyhedron{T}(cddmatrix(T, rep))

# Helpers
function getine(p::Polyhedron)
    if p.ine === nothing
        p.ine = copyinequalities(getpoly(p))
    end
    p.ine
end
function getext(p::Polyhedron)
    if p.ext === nothing
        p.ext = copygenerators(getpoly(p))
    end
    p.ext
end
function getpoly(p::Polyhedron, inepriority=true)
    if p.poly === nothing
        if !inepriority && p.ext !== nothing
            p.poly = CDDPolyhedra(p.ext)
        elseif p.ine !== nothing
            p.poly = CDDPolyhedra(p.ine)
        elseif p.ext !== nothing
            p.poly = CDDPolyhedra(p.ext)
        else
            error("Please report this bug")
        end
    end
    p.poly
end

function clearfield!(p::Polyhedron)
    p.ine = nothing
    p.ext = nothing
    p.poly = nothing
    p.hlinearitydetected = false
    p.vlinearitydetected = false
    p.noredundantinequality = false
    p.noredundantgenerator = false
end
function updateine!(p::Polyhedron, ine::CDDInequalityMatrix)
    clearfield!(p)
    p.ine = ine
end
function updateext!(p::Polyhedron, ext::CDDGeneratorMatrix)
    clearfield!(p)
    p.ext = ext
end
function updatepoly!(p::Polyhedron, poly::CDDPolyhedra)
    clearfield!(p)
    p.poly = poly
end

function Base.copy(p::Polyhedron{T}) where {T}
    pcopy = nothing
    if p.ine !== nothing
        pcopy = Polyhedron{T}(copy(p.ine))
    end
    if p.ext !== nothing
        if pcopy === nothing
            pcopy = Polyhedron{T}(copy(p.ext))
        else
            pcopy.ext = copy(p.ext)
        end
    end
    if pcopy === nothing
        # copy of ine and ext may be not necessary here
        # but I do it to be sure
        pcopy = Polyhedron{T}(copy(getine(p)))
        pcopy.ext = copy(getext(p))
    end
    pcopy.hlinearitydetected     = p.hlinearitydetected
    pcopy.vlinearitydetected     = p.vlinearitydetected
    pcopy.noredundantinequality = p.noredundantinequality
    pcopy.noredundantgenerator  = p.noredundantgenerator
    pcopy
end

# Implementation of Polyhedron's mandatory interface
function polytypeforprecision(precision::Symbol)
    if !(precision in (:float, :exact))
        error("precision should be :float or :exact, you gave $precision")
    end
    precision == :float ? Cdouble : Rational{BigInt}
end

function Polyhedra.polyhedron(rep::Representation, lib::Library)
    T = polytypeforprecision(lib.precision)
    convert(Polyhedron{T}, rep)
end
function Polyhedra.polyhedron(hyperplanes::Polyhedra.HyperPlaneIt, halfspaces::Polyhedra.HalfSpaceIt, lib::Library)
    T = polytypeforprecision(lib.precision)
    Polyhedron{T}(hyperplanes, halfspaces)
end
function Polyhedra.polyhedron(points::Polyhedra.PointIt, lines::Polyhedra.LineIt, rays::Polyhedra.RayIt, lib::Library)
    T = polytypeforprecision(lib.precision)
    Polyhedron{T}(points, lines, rays)
end

# need to specify to avoid ambiguïty
Base.convert(::Type{Polyhedron{T}}, rep::HRepresentation) where {T} = Polyhedron{T}(cddmatrix(T, rep))
Base.convert(::Type{Polyhedron{T}}, rep::VRepresentation) where {T} = Polyhedron{T}(cddmatrix(T, rep))

Polyhedron{T}(d::Polyhedra.FullDim, hits::Polyhedra.HIt{T}...) where {T} = Polyhedron{T}(CDDInequalityMatrix{T, mytype(T)}(d, hits...))
Polyhedron{T}(d::Polyhedra.FullDim, vits::Polyhedra.VIt{T}...) where {T} = Polyhedron{T}(CDDGeneratorMatrix{T, mytype(T)}(d, vits...))

function Polyhedra.hrepiscomputed(p::Polyhedron)
    p.ine !== nothing
end
function Polyhedra.hrep(p::Polyhedron{T}) where {T}
    getine(p)
end

function Polyhedra.vrepiscomputed(p::Polyhedron)
    p.ext !== nothing
end
function Polyhedra.vrep(p::Polyhedron{T}) where {T}
    getext(p)
end


Polyhedra.supportselimination(p::Polyhedron, ::FourierMotzkin) = true
function Polyhedra.eliminate(p::Polyhedron{T}, delset, ::FourierMotzkin) where {T}
    if iszero(length(delset))
        p
    else
        ine = getine(p)
        ds = collect(delset)
        for i in length(ds):-1:1
            if ds[i] != fulldim(ine)
                error("The CDD implementation of Fourier-Motzkin only support removing the last dimensions")
            end
            ine = fourierelimination(ine)
        end
        Polyhedron{T}(ine)
    end
end
Polyhedra.supportselimination(p::Polyhedron, ::BlockElimination) = true
function Polyhedra.eliminate(p::Polyhedron{T}, delset, ::BlockElimination) where {T}
    if iszero(length(delset))
        p
    else
        Polyhedron{T}(blockelimination(getine(p), delset))
    end
end

function Polyhedra.eliminate(p::Polyhedron, delset, method::DefaultElimination)
    if iszero(length(delset))
        eliminate(p, delset, FourierMotzkin())
    else
        fourier = false
        if length(delset) == 1 && fulldim(p) in delset
            # CDD's implementation of Fourier-Motzkin does not support linearity
            canonicalizelinearity!(getine(p))
            if iszero(nhyperplanes(p))
                fourier = true
            end
        end
        eliminate(p, delset, fourier ? FourierMotzkin() : BlockElimination())
    end
end

function Polyhedra.detecthlinearity!(p::Polyhedron)
    if !p.hlinearitydetected
        canonicalizelinearity!(getine(p))
        p.hlinearitydetected = true
        # getine(p.poly) would return bad inequalities.
        # If someone use the poly then ine will be invalidated
        # and if he asks the inequalities he will be surprised that the
        # linearity are not detected properly
        # However, the generators can be kept
        p.poly = nothing
    end
end
function Polyhedra.detectvlinearity!(p::Polyhedron)
    if !p.vlinearitydetected
        canonicalizelinearity!(getext(p))
        p.vlinearitydetected = true
        # getext(p.poly) would return bad inequalities.
        # If someone use the poly then ext will be invalidated
        # and if he asks the generators he will be surprised that the
        # linearity are not detected properly
        # However, the inequalities can be kept
        p.poly = nothing
    end
end


function Polyhedra.removehredundancy!(p::Polyhedron)
    if !p.noredundantinequality
        if !p.hlinearitydetected
            canonicalize!(getine(p))
            p.hlinearitydetected = true
        else
            redundancyremove!(getine(p))
        end
        p.noredundantinequality = true
        # See detectlinearity! for a discussion about the following line
        p.poly = nothing
    end
end

function Polyhedra.removevredundancy!(p::Polyhedron)
    if !p.noredundantgenerator
        canonicalize!(getext(p))
        p.noredundantgenerator = true
        # See detecthlinearity! for a discussion about the following line
        p.poly = nothing
    end
end

Base.intersect!(p::Polyhedron, h::HRepElement) = intersect!(p, intersect(h))
function Base.intersect!(p::Polyhedron, ine::HRepresentation)
    updateine!(p, matrixappend(getine(p), ine))
    #push!(getpoly(p, true), ine) # too slow because it computes double description
    #updatepoly!(p, getpoly(p)) # invalidate others
end
Polyhedra.convexhull!(p::Polyhedron, v::VRepElement) = convexhull!(p, convexhull(v))
function Polyhedra.convexhull!(p::Polyhedron, ext::VRepresentation)
    updateext!(p, matrixappend(getext(p), ext))
    #push!(getpoly(p, false), ext) # too slow because it computes double description
    #updatepoly!(p, getpoly(p)) # invalidate others
end

function Polyhedra.default_solver(p::Polyhedron{S}; T=S) where {S}
    return with_optimizer(Optimizer{T})
end
_getrepfor(p::Polyhedron, ::Polyhedra.HIndex) = getine(p)
_getrepfor(p::Polyhedron, ::Polyhedra.VIndex) = getext(p)
function Polyhedra.isredundant(p::Polyhedron, idx::Polyhedra.HIndex; strongly=false, cert=false, solver=nothing)
    f = strongly ? sredundant : redundant
    ans = f(_getrepfor(p, idx), idx.value)
    if cert
        ans
    else
        ans[1]
    end
end

# Implementation of Polyhedron's optional interface
# TODO use the following once OptimizerFactory is typed
#function Base.isempty(p::Polyhedron{T}, solver::JuMP.OptimizerFactory{typeof(Optimizer{T})}) where T
function Base.isempty(p::Polyhedron)
    lp = matrix2feasibility(getine(p))
    lpsolve(lp)
    # It is impossible to be unbounded since there is no objective
    # Note that `status` would also work
    return MOI.get(copylpsolution(lp), MOI.TerminationStatus()) != MOI.OPTIMAL
end

function gethredundantindices(p::Polyhedron)
    redundantrows(getine(p))
end
function getvredundantindices(p::Polyhedron)
    redundantrows(getext(p))
end

# type CDDLPPolyhedron{T} <: LPPolyhedron{T}
#   ine::CDDInequalityMatrix
#   has_objective::Bool
#
#   objval
#   solution
#   status
# end
#
# function LinearQuadraticModel{T}(p::Polyhedron{T})
#   CDDLPPolyhedron{T}(getine(p), false, nothing, nothing, nothing)
# end
# function loadproblem!(lpm::CDDLPPolyhedron, obj, sense)
#   if sum(abs(obj)) != 0
#     setobjective(lpm.ine, obj, sense)
#     lpm.has_objective = true
#   end
# end
# function optimize!(lpm::CDDLPPolyhedron)
#   if lpm.has_objective
#     lp = matrix2lp(lpm.ine)
#   else
#     lp = matrix2feasibility(lpm.ine)
#   end
#   lpsolve(lp)
#   sol = copylpsolution(lp)
#   lpm.status = simplestatus(sol)
#   # We have just called lpsolve so it shouldn't be Undecided
#   # if no error occured
#   lpm.status == :Undecided && (lpm.status = :Error)
#   lpm.objval = getobjval(sol)
#   lpm.solution = getsolution(sol)
# end
#
# function status(lpm::CDDLPPolyhedron)
#   lpm.status
# end
# function getobjval(lpm::CDDLPPolyhedron)
#   lpm.objval
# end
# function getsolution(lpm::CDDLPPolyhedron)
#   copy(lpm.solution)
# end
# function getunboundedray(lpm::CDDLPPolyhedron)
#   copy(lpm.solution)
# end
