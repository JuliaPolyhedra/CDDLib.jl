export CDDLibrary, CDDPolyhedron

struct CDDLibrary <: PolyhedraLibrary
    precision::Symbol

    function CDDLibrary(precision::Symbol=:float)
        if !(precision in [:float, :exact])
            error("Invalid precision, it should be :float or :exact")
        end
        new(precision)
    end
end
Polyhedra.similar_library(::CDDLibrary, ::Polyhedra.FullDim, ::Type{T}) where T<:Union{Integer,Rational} = CDDLibrary(:exact)
Polyhedra.similar_library(::CDDLibrary, ::Polyhedra.FullDim, ::Type{T}) where T<:AbstractFloat = CDDLibrary(:float)

mutable struct CDDPolyhedron{T<:PolyType} <: Polyhedron{T}
    ine::Union{Nothing, CDDInequalityMatrix{T}}
    ext::Union{Nothing, CDDGeneratorMatrix{T}}
    poly::Union{Nothing, CDDPolyhedra{T}}
    hlinearitydetected::Bool
    vlinearitydetected::Bool
    noredundantinequality::Bool
    noredundantgenerator::Bool

    function CDDPolyhedron{T}(ine::CDDInequalityMatrix) where {T <: PolyType}
        new{T}(ine, nothing, nothing, false, false, false, false)
    end
    function CDDPolyhedron{T}(ext::CDDGeneratorMatrix) where {T <: PolyType}
        new{T}(nothing, ext, nothing, false, false, false, false)
    end
    # function CDDPolyhedron(poly::CDDPolyhedra{T})
    #   new(nothing, nothing, poly)
    # end
end
Polyhedra.FullDim(p::CDDPolyhedron{T}) where {T} = Polyhedra.FullDim_rep(p.ine, p.ext)
Polyhedra.library(p::CDDPolyhedron{T}) where {T} = Polyhedra.similar_library(CDDLibrary(), Polyhedra.FullDim(p), T)
Polyhedra.hvectortype(::Union{CDDPolyhedron{T}, Type{<:CDDPolyhedron{T}}}) where {T} = Polyhedra.hvectortype(CDDInequalityMatrix{T})
Polyhedra.vvectortype(::Union{CDDPolyhedron{T}, Type{<:CDDPolyhedron{T}}}) where {T} = Polyhedra.vvectortype(CDDGenerator{T})
Polyhedra.similar_type(::Type{<:CDDPolyhedron}, ::Polyhedra.FullDim, ::Type{T}) where {T} = CDDPolyhedron{T}

CDDPolyhedron(matrix::CDDMatrix{T}) where {T} = CDDPolyhedron{T}(matrix)
Base.convert(::Type{CDDPolyhedron{T}}, rep::Representation{T}) where {T} = CDDPolyhedron{T}(cddmatrix(T, rep))

# Helpers
function getine(p::CDDPolyhedron)
    if p.ine === nothing
        p.ine = copyinequalities(getpoly(p))
    end
    p.ine
end
function getext(p::CDDPolyhedron)
    if p.ext === nothing
        p.ext = copygenerators(getpoly(p))
    end
    p.ext
end
function getpoly(p::CDDPolyhedron, inepriority=true)
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

function clearfield!(p::CDDPolyhedron)
    p.ine = nothing
    p.ext = nothing
    p.poly = nothing
    p.hlinearitydetected = false
    p.vlinearitydetected = false
    p.noredundantinequality = false
    p.noredundantgenerator = false
end
function updateine!(p::CDDPolyhedron, ine::CDDInequalityMatrix)
    clearfield!(p)
    p.ine = ine
end
function updateext!(p::CDDPolyhedron, ext::CDDGeneratorMatrix)
    clearfield!(p)
    p.ext = ext
end
function updatepoly!(p::CDDPolyhedron, poly::CDDPolyhedra)
    clearfield!(p)
    p.poly = poly
end

function Base.copy(p::CDDPolyhedron{T}) where {T}
    pcopy = nothing
    if p.ine !== nothing
        pcopy = CDDPolyhedron{T}(copy(p.ine))
    end
    if p.ext !== nothing
        if pcopy === nothing
            pcopy = CDDPolyhedron{T}(copy(p.ext))
        else
            pcopy.ext = copy(p.ext)
        end
    end
    if pcopy === nothing
        # copy of ine and ext may be not necessary here
        # but I do it to be sure
        pcopy = CDDPolyhedron{T}(copy(getine(p)))
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

function Polyhedra.polyhedron(rep::Representation, lib::CDDLibrary)
    T = polytypeforprecision(lib.precision)
    convert(CDDPolyhedron{T}, rep)
end
function Polyhedra.polyhedron(hyperplanes::Polyhedra.HyperPlaneIt, halfspaces::Polyhedra.HalfSpaceIt, lib::CDDLibrary)
    T = polytypeforprecision(lib.precision)
    CDDPolyhedron{T}(hyperplanes, halfspaces)
end
function Polyhedra.polyhedron(points::Polyhedra.PointIt, lines::Polyhedra.LineIt, rays::Polyhedra.RayIt, lib::CDDLibrary)
    T = polytypeforprecision(lib.precision)
    CDDPolyhedron{T}(points, lines, rays)
end

# need to specify to avoid ambiguïty
Base.convert(::Type{CDDPolyhedron{T}}, rep::HRepresentation) where {T} = CDDPolyhedron{T}(cddmatrix(T, rep))
Base.convert(::Type{CDDPolyhedron{T}}, rep::VRepresentation) where {T} = CDDPolyhedron{T}(cddmatrix(T, rep))

CDDPolyhedron{T}(d::Polyhedra.FullDim, hits::Polyhedra.HIt{T}...) where {T} = CDDPolyhedron{T}(CDDInequalityMatrix{T, mytype(T)}(d, hits...))
CDDPolyhedron{T}(d::Polyhedra.FullDim, vits::Polyhedra.VIt{T}...) where {T} = CDDPolyhedron{T}(CDDGeneratorMatrix{T, mytype(T)}(d, vits...))

function Polyhedra.hrepiscomputed(p::CDDPolyhedron)
    p.ine !== nothing
end
function Polyhedra.hrep(p::CDDPolyhedron{T}) where {T}
    getine(p)
end

function Polyhedra.vrepiscomputed(p::CDDPolyhedron)
    p.ext !== nothing
end
function Polyhedra.vrep(p::CDDPolyhedron{T}) where {T}
    getext(p)
end


Polyhedra.supportselimination(p::CDDPolyhedron, ::FourierMotzkin) = true
function Polyhedra.eliminate(p::CDDPolyhedron{T}, delset, ::FourierMotzkin) where {T}
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
        CDDPolyhedron{T}(ine)
    end
end
Polyhedra.supportselimination(p::CDDPolyhedron, ::BlockElimination) = true
function Polyhedra.eliminate(p::CDDPolyhedron{T}, delset, ::BlockElimination) where {T}
    if iszero(length(delset))
        p
    else
        CDDPolyhedron{T}(blockelimination(getine(p), delset))
    end
end

function Polyhedra.eliminate(p::CDDPolyhedron, delset, method::DefaultElimination)
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

function Polyhedra.detecthlinearity!(p::CDDPolyhedron)
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
function Polyhedra.detectvlinearity!(p::CDDPolyhedron)
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


function Polyhedra.removehredundancy!(p::CDDPolyhedron)
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

function Polyhedra.removevredundancy!(p::CDDPolyhedron)
    if !p.noredundantgenerator
        canonicalize!(getext(p))
        p.noredundantgenerator = true
        # See detecthlinearity! for a discussion about the following line
        p.poly = nothing
    end
end

Base.intersect!(p::CDDPolyhedron, h::HRepElement) = intersect!(p, intersect(h))
function Base.intersect!(p::CDDPolyhedron, ine::HRepresentation)
    updateine!(p, matrixappend(getine(p), ine))
    #push!(getpoly(p, true), ine) # too slow because it computes double description
    #updatepoly!(p, getpoly(p)) # invalidate others
end
Polyhedra.convexhull!(p::CDDPolyhedron, v::VRepElement) = convexhull!(p, convexhull(v))
function Polyhedra.convexhull!(p::CDDPolyhedron, ext::VRepresentation)
    updateext!(p, matrixappend(getext(p), ext))
    #push!(getpoly(p, false), ext) # too slow because it computes double description
    #updatepoly!(p, getpoly(p)) # invalidate others
end

function Polyhedra.default_solver(p::CDDPolyhedron{T}) where {T}
    CDDSolver(exact = T == Rational{BigInt})
end
_getrepfor(p::CDDPolyhedron, ::Polyhedra.HIndex) = getine(p)
_getrepfor(p::CDDPolyhedron, ::Polyhedra.VIndex) = getext(p)
function Polyhedra.isredundant(p::CDDPolyhedron, idx::Polyhedra.HIndex; strongly=false, cert=false, solver=Polyhedra.solver(p))
    f = strongly ? sredundant : redundant
    ans = f(_getrepfor(p, idx), idx.value)
    if cert
        ans
    else
        ans[1]
    end
end

# Implementation of Polyhedron's optional interface
function Base.isempty(p::CDDPolyhedron, solver::CDDSolver)
    lp = matrix2feasibility(getine(p))
    lpsolve(lp)
    # It is impossible to be unbounded since there is no objective
    # Note that `status` would also work
    simplestatus(copylpsolution(lp)) != :Optimal
end

function gethredundantindices(p::CDDPolyhedron)
    redundantrows(getine(p))
end
function getvredundantindices(p::CDDPolyhedron)
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
# function LinearQuadraticModel{T}(p::CDDPolyhedron{T})
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
