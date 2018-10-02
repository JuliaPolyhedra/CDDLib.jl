@test_throws ErrorException CDDSolver(;solver_type=:Simplex)

import MathProgBase
const mathprogbase_test = joinpath(dirname(dirname(pathof(MathProgBase))), "test")

include(joinpath(mathprogbase_test, "linproginterface.jl"))
linprogsolvertest(CDDSolver())
linprogsolvertest(CDDSolver(; solver_type=:DualSimplex, exact=true))

# CrissCross is failing for the following problem of linprog.jl
#
#  # test unbounded problem:
#  # min -x-y
#  # s.t. -x+2y <= 0
#  # x,y >= 0
#  sol = linprog([-1,-1],[-1 2],'<',[0],solver)
#  @test sol.status == :Unbounded
#
# CrossCross says dd_Inconsistent while it should say dd_DualInconsistent or dd_Unbounded (Unbounded)

linprogsolvertest(CDDSolver(; solver_type=:CrissCross))
linprogsolvertest(CDDSolver(; solver_type=:CrissCross, exact=true))
