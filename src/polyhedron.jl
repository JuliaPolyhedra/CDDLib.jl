export CDDLibrary, CDDPolyhedron
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

type CDDPolyhedron{N, T<:PolyType} <: Polyhedron{N, T}
  ine::Nullable{CDDInequalityMatrix{N,T}}
  ext::Nullable{CDDGeneratorMatrix{N,T}}
  poly::Nullable{CDDPolyhedra{N,T}}
  hlinearitydetected::Bool
  vlinearitydetected::Bool
  noredundantinequality::Bool
  noredundantgenerator::Bool

  function (::Type{CDDPolyhedron{N, T}}){N, T <: PolyType}(ine::CDDInequalityMatrix)
    new{N, T}(ine, nothing, nothing, false, false, false, false)
  end
  function (::Type{CDDPolyhedron{N, T}}){N, T <: PolyType}(ext::CDDGeneratorMatrix) 
    new{N, T}(nothing, ext, nothing, false, false, false, false)
  end
# function CDDPolyhedron(poly::CDDPolyhedra{T})
#   new(nothing, nothing, poly)
# end
end
changeeltype{N, T, NewT}(::Type{CDDPolyhedron{N, T}}, ::Type{NewT}) = CDDPolyhedron{N, NewT}
changefulldim{N, T}(::Type{CDDPolyhedron{N, T}}, NewN) = CDDPolyhedron{NewN, T}
changeboth{N, T, NewT}(::Type{CDDPolyhedron{N, T}}, NewN, ::Type{NewT}) = CDDPolyhedron{NewN, NewT}

decomposedhfast(p::CDDPolyhedron) = false
decomposedvfast(p::CDDPolyhedron) = false

CDDPolyhedron{N, T}(matrix::CDDMatrix{N, T}) = CDDPolyhedron{N, T}(matrix)
Base.convert{N, T}(::Type{CDDPolyhedron{N, T}}, rep::Representation{N, T}) = CDDPolyhedron{N, T}(cddmatrix(T, rep))

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
  p.hlinearitydetected = false
  p.vlinearitydetected = false
  p.noredundantinequality = false
  p.noredundantgenerator = false
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

function polyhedron{N}(repit::Union{Representation{N},HRepIterator{N},VRepIterator{N}}, lib::CDDLibrary)
  T = polytypeforprecision(lib.precision)
  CDDPolyhedron{N, T}(repit)
end
function polyhedron(lib::CDDLibrary; eqs=nothing, ineqs=nothing, points=nothing, rays=nothing)
  its = [eqs, ineqs, points, rays]
  i = findfirst(x -> !(x === nothing), its)
  if i == 0
    error("polyhedron should be given at least one iterator")
  end
  N = fulldim(its[i])
  T = polytypeforprecision(lib.precision)
  CDDPolyhedron{N, T}(eqs=eqs, ineqs=ineqs, points=points, rays=rays)
end

getlibraryfor{T<:Real}(::CDDPolyhedron, n::Int, ::Type{T}) = CDDLibrary(:exact)
getlibraryfor{T<:AbstractFloat}(::CDDPolyhedron, n::Int, ::Type{T}) = CDDLibrary(:float)

# need to specify to avoid ambiguïty
Base.convert{N, T}(::Type{CDDPolyhedron{N, T}}, rep::HRepresentation{N}) = CDDPolyhedron{N, T}(cddmatrix(T, rep))
Base.convert{N, T}(::Type{CDDPolyhedron{N, T}}, rep::VRepresentation{N}) = CDDPolyhedron{N, T}(cddmatrix(T, rep))

(::Type{CDDPolyhedron{N, T}}){N, T}(it::HRepIterator{N,T}) = CDDPolyhedron{N, T}(CDDInequalityMatrix{N,T,mytype(T)}(it))
(::Type{CDDPolyhedron{N, T}}){N, T}(it::VRepIterator{N,T}) = CDDPolyhedron{N, T}(CDDGeneratorMatrix{N,T,mytype(T)}(it))

function (::Type{CDDPolyhedron{N, T}}){N, T}(; eqs=nothing, ineqs=nothing, points=nothing, rays=nothing)
  noth = eqs === nothing && ineqs === nothing
  notv = points === nothing && rays === nothing
  if noth && notv
    error("CDDPolyhedron should have at least one iterator to be built")
  end
  if !noth && !notv
    error("CDDPolyhedron constructed with a combination of eqs/ineqs with points/rays")
  end
  if notv
    CDDPolyhedron{N, T}(CDDInequalityMatrix{N,T,mytype(T)}(eqs=eqs, ineqs=ineqs))
  else
    CDDPolyhedron{N, T}(CDDGeneratorMatrix{N,T,mytype(T)}(points=points, rays=rays))
  end
end

function hrepiscomputed(p::CDDPolyhedron)
  !isnull(p.ine)
end
function hrep{N, T}(p::CDDPolyhedron{N, T})
  getine(p)
end

for f in [:hashreps, :nhreps, :starthrep, :hasineqs, :nineqs, :startineq, :haseqs, :neqs, :starteq]
    @eval $f(p::CDDPolyhedron) = $f(getine(p))
end
for f in [:donehrep, :nexthrep, :doneineq, :nextineq, :doneeq, :nexteq]
    @eval $f(p::CDDPolyhedron, state) = $f(getine(p), state)
end

for f in [:hasvreps, :nvreps, :startvrep, :haspoints, :npoints, :startpoint, :hasrays, :nrays, :startray]
    @eval $f(p::CDDPolyhedron) = $f(getext(p))
end
for f in [:donevrep, :nextvrep, :donepoint, :nextpoint, :doneray, :nextray]
    @eval $f(p::CDDPolyhedron, state) = $f(getext(p), state)
end

function vrepiscomputed(p::CDDPolyhedron)
  !isnull(p.ext)
end
function vrep{N, T}(p::CDDPolyhedron{N, T})
  getext(p)
end


implementseliminationmethod(p::CDDPolyhedron, ::Type{Val{:FourierMotzkin}}) = true
function eliminate(p::CDDPolyhedron, delset, ::Type{Val{:FourierMotzkin}})
    eliminate(p, delset, :FourierMotzkin)
end
implementseliminationmethod(p::CDDPolyhedron, ::Type{Val{:BlockElimination}}) = true
function eliminate(p::CDDPolyhedron, delset, ::Type{Val{:BlockElimination}})
    eliminate(p, delset, :BlockElimination)
end

function eliminate(ine::CDDInequalityMatrix, delset, method=:Auto)
  if length(delset) > 0
    if method == :Auto
        fourier = false
        if length(delset) == 1 && fulldim(ine) in delset
            # CDD's implementation of Fourier-Motzkin does not support linearity
            canonicalizelinearity!(ine)
            if neqs(ine) == 0
                fourier = true
            end
        end
    else
        fourier = method == :FourierMotzkin
    end
    if fourier
      ds = collect(delset)
      for i in length(ds):-1:1
          if ds[i] != fulldim(ine)
              error("The CDD implementation of Fourier-Motzkin only support removing the last dimensions")
          end
          ine = fourierelimination(ine)
      end
      ine
    else
      blockelimination(ine, delset)
    end
  end
end

function eliminate{N, T}(p::CDDPolyhedron{N, T}, delset, method::Symbol=:Auto)
  CDDPolyhedron{N-length(delset), T}(eliminate(getine(p), delset, method))
end

function detecthlinearities!(p::CDDPolyhedron)
  if !p.vlinearitydetected
    canonicalizelinearity!(getext(p))
    p.vlinearitydetected = true
    # getine(p.poly) would return bad inequalities.
    # If someone use the poly then ine will be invalidated
    # and if he asks the inequalities he will be surprised that the
    # linearities are not detected properly
    # However, the generators can be kept
    p.poly = nothing
  end
end
function detectvlinearities!(p::CDDPolyhedron)
  if !p.hlinearitydetected
    canonicalizelinearity!(getine(p))
    p.hlinearitydetected = true
    # getext(p.poly) would return bad inequalities.
    # If someone use the poly then ext will be invalidated
    # and if he asks the generators he will be surprised that the
    # linearities are not detected properly
    # However, the inequalities can be kept
    p.poly = nothing
  end
end


function removehredundancy!(p::CDDPolyhedron)
  if !p.noredundantinequality
    if !p.hlinearitydetected
      canonicalize!(getine(p))
      p.hlinearitydetected = true
    else
      redundancyremove!(getine(p))
    end
    p.noredundantinequality = true
    # See detectlinearities! for a discussion about the following line
    p.poly = nothing
  end
end

function removevredundancy!(p::CDDPolyhedron)
  if !p.noredundantgenerator
    canonicalize!(getext(p))
    p.noredundantgenerator = true
    # See detecthlinearities! for a discussion about the following line
    p.poly = nothing
  end
end

function Base.push!{N}(p::CDDPolyhedron{N}, ine::HRepresentation{N})
  updateine!(p, matrixappend(getine(p), ine))
  #push!(getpoly(p, true), ine) # too slow because it computes double description
  #updatepoly!(p, getpoly(p)) # invalidate others
end
function Base.push!{N}(p::CDDPolyhedron{N}, ext::VRepresentation{N})
  updateext!(p, matrixappend(getext(p), ext))
  #push!(getpoly(p, false), ext) # too slow because it computes double description
  #updatepoly!(p, getpoly(p)) # invalidate others
end

# TODO other solvers
function defaultLPsolverfor{N,T}(p::CDDPolyhedron{N,T}, solver=nothing)
    if vrepiscomputed(p)
        SimpleVRepSolver()
    else
        CDDSolver(exact=T == Rational{BigInt})
    end
end
function ishredundant(p::CDDPolyhedron, i::Integer; strongly=false, cert=false, solver=defaultLPsolverfor(p))
  f = strongly ? sredundant : redundant
  ans = redundant(getine(p), i)
  if cert
    ans
  else
    ans[1]
  end
end
function isvredundant(p::CDDPolyhedron, i::Integer; strongly=false, cert=false, solver=defaultLPsolverfor(p))
  f = strongly ? sredundant : redundant
  ans = redundant(getine(p), i)
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

# type CDDLPPolyhedron{N, T} <: LPPolyhedron{N, T}
#   ine::CDDInequalityMatrix{N}
#   has_objective::Bool
#
#   objval
#   solution
#   status
# end
#
# function LinearQuadraticModel{N, T}(p::CDDPolyhedron{N, T})
#   CDDLPPolyhedron{N, T}(getine(p), false, nothing, nothing, nothing)
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
