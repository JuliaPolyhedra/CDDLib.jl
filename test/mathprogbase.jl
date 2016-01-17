const mathprogbase_test = joinpath(Pkg.dir("MathProgBase"), "test")

include(joinpath(mathprogbase_test, "linprog.jl"))
linprogtest(CDDSolver())
linprogtest(CDDSolver(;solver_type=:DualSimplex,exact=true))
# Failing for
#
#  # test unbounded problem:
#  # min -x-y
#  # s.t. -x+2y <= 0
#  # x,y >= 0
#  sol = linprog([-1,-1],[-1 2],'<',[0],solver)
#  @test sol.status == :Unbounded
#
# CrossCross says dd_Inconsistent while it should say dd_DualInconsistent or dd_Unbounded (Unbounded)

#linprogtest(CDDSolver(;solver_type=:CrissCross))
#linprogtest(CDDSolver(;solver_type=:CrissCross,exact=true))
@test_throws ErrorException CDDSolver(;solver_type=:Simplex)
