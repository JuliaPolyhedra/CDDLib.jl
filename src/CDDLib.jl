module CDDLib

using LinearAlgebra
import cddlib_jll: libcddgmp
using Polyhedra

include("ccall.jl")

function __init__()
    @dd_ccall set_global_constants Nothing ()
end

import Base.convert, Base.push!, Base.eltype, Base.copy

include("debug_log.jl")
include("cddtypes.jl")
include("error.jl")
include("mytype.jl")
include("settype.jl")

include("matrix.jl")
include("polyhedra.jl")
include("operations.jl")
include("lp.jl")

include("MOI_wrapper.jl")
include("polyhedron.jl")

end # module
