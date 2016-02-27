using CDoubleDescription

# returns extreme points of polyhedron Ax <= b
function extremepoints(A,b)
    m = InequalityDescription(A, b)
    p = CDDPolyhedra(m)
    EPs = Description{Rational{BigInt}}(copygenerators(p))
    splitvertexrays!(EPs)
    return EPs.V, EPs.R
end

A = [-1 0; 0 -1; 1 1]
b = [0, 0, 1]
println(extremepoints(A,b))
