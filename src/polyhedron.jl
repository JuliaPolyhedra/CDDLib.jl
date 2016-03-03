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

type CDDPolyhedron{T<:MyType} <: Polyhedron
  ine::Nullable{CDDInequalityMatrix{T}}
  ext::Nullable{CDDGeneratorMatrix{T}}
  poly::Nullable{CDDPolyhedra{T}}
  linearitydetected::Bool
  noredundantinequality::Bool
  noredundantgenerator::Bool

  function CDDPolyhedron(ine::CDDInequalityMatrix{T})
    new(ine, nothing, nothing, false, false, false)
  end
  function CDDPolyhedron(ext::CDDGeneratorMatrix{T})
    new(nothing, ext, nothing, false, false, false)
  end
# function CDDPolyhedron(poly::CDDPolyhedra{T})
#   new(nothing, nothing, poly)
# end
end

CDDPolyhedron{T<:MyType}(matrix::CDDMatrix{T}) = CDDPolyhedron{T}(matrix)
call{T<:MyType}(::Type{CDDPolyhedron{T}}, desc::Description) = CDDPolyhedron{T}(CDDMatrix{T}(desc))

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
function updateine!{T<:MyType}(p::CDDPolyhedron{T}, ine::CDDInequalityMatrix{T})
  clearfield!(p)
  p.ine = ine
end
function updateext!{T<:MyType}(p::CDDPolyhedron{T}, ext::CDDGeneratorMatrix{T})
  clearfield!(p)
  p.ext = ext
end
function updatepoly!{T<:MyType}(p::CDDPolyhedron{T}, poly::CDDPolyhedra{T})
  clearfield!(p)
  p.poly = poly
end

# Implementation of Polyhedron's mandatory interface
function polyhedron(desc::Description, lib::CDDLibrary)
  CDDPolyhedron(desc, lib.precision)
end

getlibrary(p::CDDPolyhedron{Cdouble}) = CDDLibrary(:float)
getlibrary(p::CDDPolyhedron{GMPRational}) = CDDLibrary(:exact)

exacttype{T<:Real}(::Type{T}) = GMPRational
exacttype{T<:AbstractFloat}(::Type{T}) = Cdouble

function CDDPolyhedron{T<:Real}(desc::Description{T}, precision=:float)
  if !(precision in (:float, :exact))
    error("precision should be :float or :exact, you gave $precision")
  end
  if precision == :float
    CDDPolyhedron{Cdouble}(CDDMatrix{Cdouble}(desc))
  else
    S = exacttype(T)
    CDDPolyhedron{S}(CDDMatrix{S}(desc))
  end
end

function inequalitiesarecomputed(p::CDDPolyhedron)
  !isnull(p.ine)
end
function getinequalities(p::CDDPolyhedron{Cdouble})
  InequalityDescription(getine(p))
end
function getinequalities(p::CDDPolyhedron{GMPRational})
  InequalityDescription{Rational{BigInt}}(InequalityDescription(getine(p)))
end

function generatorsarecomputed(p::CDDPolyhedron)
  !isnull(p.ine)
end
function getgenerators(p::CDDPolyhedron{Cdouble})
  GeneratorDescription(getext(p))
end
function getgenerators(p::CDDPolyhedron{GMPRational})
  GeneratorDescription{Rational{BigInt}}(GeneratorDescription(getext(p)))
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

function eliminate(p::CDDPolyhedron, delset::IntSet)
  CDDPolyhedron(eliminate(getine(p), delset))
end
function eliminate!(p::CDDPolyhedron, delset::IntSet)
  updateine!(p, (eliminate(getine(p), delset)))
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

function Base.push!(p::CDDPolyhedron, ine::InequalityDescription)
  push!(getpoly(p, true), ine)
  updatepoly!(p, getpoly(p)) # invalidate others
end
function Base.push!(p::CDDPolyhedron, ext::GeneratorDescription)
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
