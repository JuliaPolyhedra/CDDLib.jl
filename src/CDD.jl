module CDD

using BinDeps
import Base.show, Base.convert, Base.push!
using Polyhedra

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
  include("../deps/deps.jl")
else
  error("CDD not properly installed. Please run Pkg.build(\"CDD\")")
end

macro cdd_ccall(f, args...)
  quote
    ret = ccall(($"dd_$f", libcdd), $(map(esc,args)...))
    ret
  end
end

macro cddf_ccall(f, args...)
  quote
    ret = ccall(($"ddf_$f", libcdd), $(map(esc,args)...))
    ret
  end
end


macro cdd0_ccall(f, args...)
  quote
    ret = ccall(($"$f", libcdd), $(map(esc,args)...))
    ret
  end
end

@cdd_ccall set_global_constants Void ()

include("cddtypes.jl")

include("error.jl")

include("mytype.jl")

include("settype.jl")

include("matrix.jl")

include("description.jl")

include("polyhedra.jl")

include("operations.jl")

include("lp.jl")

include("mathprogbase.jl")

end # module
