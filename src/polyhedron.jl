export CDDLibrary, CDDPolyhedron, getinequalities, getgenerators, removeredundantinequalities!, removeredundantgenerators!, isredundantinequality, isredundantgenerator, isstronglyredundantinequality, isstronglyredundantgenerator
import Base.isempty, Base.push!

type CDDLibrary <: PolyhedraLibrary
  precision::Symbol

  function CDDLibrary(precision::Symbol=:float)
    if !(precision in [:float, :exact])
      error("Invalid precision, it should be :float or :exact")
    end
    new(precision)
  end
end

type CDDPolyhedron{N, T} <: Polyhedron{N, T}
  # The type of the CDDMatrix and CDDPolyhedra is not especially T !
  ine::Nullable{CDDInequalityMatrix{N}}
  ext::Nullable{CDDGeneratorMatrix{N}}
  poly::Nullable{CDDPolyhedra{N}}
  linearitydetected::Bool
  noredundantinequality::Bool
  noredundantgenerator::Bool

  function CDDPolyhedron(ine::CDDInequalityMatrix)
    new(ine, nothing, nothing, false, false, false)
  end
  function CDDPolyhedron(ext::CDDGeneratorMatrix)
    new(nothing, ext, nothing, false, false, false)
  end
# function CDDPolyhedron(poly::CDDPolyhedra{T})
#   new(nothing, nothing, poly)
# end
end

CDDPolyhedron{N, T<:MyType}(matrix::CDDMatrix{N, T}) = CDDPolyhedron{N, T}(matrix)
call{N, T<:MyType}(::Type{CDDPolyhedron{N, T}}, desc::Representation) = CDDPolyhedron{N, T}(CDDMatrix{N, T}(desc))

# Helpers
function getine(p::CDDPolyhedron)
  if isnull(p.ine)
    p.ine = copyinequalities(getpoly(p))
  end
  get(p.ine)
end
function getext(p::CDDPolyhedron)
  if isnull(p.ext)
    p.ext = copygenerators(getpoly(p))
  end
  get(p.ext)
end
function getpoly(p::CDDPolyhedron, inepriority=true)
  if isnull(p.poly)
    if !inepriority && !isnull(p.ext)
      p.poly = CDDPolyhedra(get(p.ext))
    elseif !isnull(p.ine)
      p.poly = CDDPolyhedra(get(p.ine))
    elseif !isnull(p.ext)
      p.poly = CDDPolyhedra(get(p.ext))
    else
      error("Please report this bug")
    end
  end
  get(p.poly)
end

function clearfield!(p::CDDPolyhedron)
  p.ine = nothing
  p.ext = nothing
  p.poly = nothing
  linearitydetected = false
  noredundantinequality = false
  noredundantgenerator = false
end
function updateine!{N}(p::CDDPolyhedron{N}, ine::CDDInequalityMatrix{N})
  clearfield!(p)
  p.ine = ine
end
function updateext!{N}(p::CDDPolyhedron{N}, ext::CDDGeneratorMatrix{N})
  clearfield!(p)
  p.ext = ext
end
function updatepoly!{N}(p::CDDPolyhedron{N}, poly::CDDPolyhedra{N})
  clearfield!(p)
  p.poly = poly
end

function Base.copy{N, T}(p::CDDPolyhedron{N, T})
  pcopy = nothing
  if !isnull(p.ine)
    pcopy = CDDPolyhedron{N, T}(copy(get(p.ine)))
  end
  if !isnull(p.ext)
    if pcopy == nothing
      pcopy = CDDPolyhedron{N, T}(copy(get(p.ext)))
    else
      pcopy.ext = copy(get(p.ext))
    end
  end
  if pcopy == nothing
    # copy of ine and ext may be not necessary here
    # but I do it to be sure
    pcopy = CDDPolyhedron{N, T}(copy(getine(p)))
    pcopy.ext = copy(getext(p))
  end
  pcopy.linearitydetected     = p.linearitydetected
  pcopy.noredundantinequality = p.noredundantinequality
  pcopy.noredundantgenerator  = p.noredundantgenerator
  pcopy
end

# Implementation of Polyhedron's mandatory interface
function polyhedron(desc::Representation, lib::CDDLibrary)
  CDDPolyhedron(desc, lib.precision)
end

# Be the default library
getlibraryfor{T<:Real}(::Type{T}) = CDDLibrary(:exact)
getlibraryfor{T<:Real}(p::CDDPolyhedron, ::Type{T}) = CDDLibrary(:exact)
getlibraryfor{T<:AbstractFloat}(::Type{T}) = CDDLibrary(:float)
getlibraryfor{T<:AbstractFloat}(p::CDDPolyhedron, ::Type{T}) = CDDLibrary(:float)

function call{N, T, DT}(::Type{CDDPolyhedron{N, T}}, desc::Representation{DT})
  CDDPolyhedron{N, T}(CDDMatrix{N, mytypefor(T)}(desc))
end

function CDDPolyhedron{DT}(desc::Representation{DT}, precision=:float)
  if !(precision in (:float, :exact))
    error("precision should be :float or :exact, you gave $precision")
  end
  N = fulldim(desc)
  (T, PT) = precision == :float ? (Cdouble, Cdouble) : (GMPRational, Rational{BigInt})
  CDDPolyhedron{N, PT}(CDDMatrix{N, T}(desc))
end

function inequalitiesarecomputed(p::CDDPolyhedron)
  !isnull(p.ine)
end
function getinequalities{N, T}(p::CDDPolyhedron{N, T})
  HRepresentation{T}(getine(p))
end

function generatorsarecomputed(p::CDDPolyhedron)
  !isnull(p.ine)
end
function getgenerators{N, T}(p::CDDPolyhedron{N, T})
  VRepresentation{T}(getext(p))
end

function eliminate(ine::CDDInequalityMatrix, delset::IntSet)
  if length(delset) > 0
    if length(delset) == 1 && (size(ine, 2)-1) in delset
      fourierelimination(ine)
    else
      blockelimination(ine, delset)
    end
  end
end

function eliminate{N, T}(p::CDDPolyhedron{N, T}, delset::IntSet)
  CDDPolyhedron{N-length(delset), T}(eliminate(getine(p), delset))
end

# FIXME Would detect linearities for generators make sense/be usefull ?
function detectlinearities!(p::CDDPolyhedron)
  if !p.linearitydetected
    canonicalizelinearity!(p.ine)
    p.linearitydetected = true
    # getine(p.poly) would return bad inequalities.
    # If someone use the poly then ine will be invalidated
    # and if he asks the inequalities he will be surprised that the
    # linearities are not detected properly
    # However, the generators can be kept
    p.poly = nothing
  end
end

function removeredundantinequalities!(p::CDDPolyhedron)
  if !p.noredundantinequality
    if !p.linearitydetected
      canonicalize!(getine(p))
      p.linearitydetected = true
    else
      redundancyremove!(getine(p))
    end
    p.noredundantinequality = true
    # See detectlinearities! for a discussion about the following line
    p.poly = nothing
  end
end

function removeredundantgenerators!(p::CDDPolyhedron)
  if !p.noredundantgenerator
    canonicalize!(getext(p))
    p.noredundantgenerator = true
    # See detectlinearities! for a discussion about the following line
    p.poly = nothing
  end
end

function Base.push!(p::CDDPolyhedron, ine::HRepresentation)
  push!(getpoly(p, true), ine)
  updatepoly!(p, getpoly(p)) # invalidate others
end
function Base.push!(p::CDDPolyhedron, ext::VRepresentation)
  push!(getpoly(p, false), ext)
  updatepoly!(p, getpoly(p)) # invalidate others
end

function isredundantinequality(p::CDDPolyhedron, i::Integer)
  redundant(getine(p), i)
end
function isredundantgenerator(p::CDDPolyhedron, i::Integer)
  redundant(getext(p), i)
end

function isstronglyredundantinequality(p::CDDPolyhedron, i::Integer)
  sredundant(getine(p), i)
end
function isstronglyredundantgenerator(p::CDDPolyhedron, i::Integer)
  sredundant(getext(p), i)
end

# Implementation of Polyhedron's optional interface
function Base.isempty(p::CDDPolyhedron)
  lp = matrix2feasibility(getine(p))
  lpsolve(lp)
  # It is impossible to be unbounded since there is no objective
  # Note that `status` would also work
  simplestatus(copylpsolution(lp)) != :Optimal
end

function getredundantinequalities(p::CDDPolyhedron)
  redundantrows(getine(p))
end
function getredundantgenerators(p::CDDPolyhedron)
  redundantrows(getext(p))
end
