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

# Issue #31
@testset "CDDSolver: exact solution" begin
    A = [7//3 1//3]
    sense = '<'
    b = 1//2
    c = [-1//1, 0]

    val = -3//14
    x = [3//14, 0//1]

    for solver_type in [:DualSimplex, :CrissCross]
        lp_solver = CDDSolver(solver_type=solver_type, exact=true)
        sol = MathProgBase.linprog(c, A, '<', b, lp_solver)
        @test sol.objval == val
        @test sol.sol == x
    end
end
