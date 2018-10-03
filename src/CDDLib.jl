__precompile__()

module CDDLib

using LinearAlgebra
using BinDeps
using Polyhedra

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("CDDLib not properly installed. Please run Pkg.build(\"CDDLib\")")
end

macro dd_ccall(f, args...)
    quote
        ret = ccall(($"dd_$f", libcdd), $(map(esc,args)...))
        ret
    end
end

macro ddf_ccall(f, args...)
    quote
        ret = ccall(($"ddf_$f", libcdd), $(map(esc,args)...))
        ret
    end
end


macro cdd_ccall(f, args...)
    quote
        ret = ccall(($"$f", libcdd), $(map(esc,args)...))
        ret
    end
end

function __init__()
    @dd_ccall set_global_constants Nothing ()
end

import Base.convert, Base.push!, Base.eltype, Base.copy

include("cddtypes.jl")

include("error.jl")

include("mytype.jl")

include("settype.jl")

include("matrix.jl")

include("polyhedra.jl")

include("operations.jl")

include("lp.jl")

include("mathprogbase.jl")

include("polyhedron.jl")

end # module
