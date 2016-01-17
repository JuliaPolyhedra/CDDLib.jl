const mathprogbase_test = joinpath(Pkg.dir("MathProgBase"), "test")

include(joinpath(mathprogbase_test, "linprog.jl"))
linprogtest(CDDSolver())
