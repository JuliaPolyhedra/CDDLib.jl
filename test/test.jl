using CDDLib

# returns extreme points of polyhedron Ax <= b
function extremepoints(A,b)
    m = HRepresentation(A, b)
    p = CDDPolyhedra(m)
    EPs = Representation{Rational{BigInt}}(copygenerators(p))
    splitvertexrays!(EPs)
    return EPs.V, EPs.R
end

A = [-1 0; 0 -1; 1 1]
b = [0, 0, 1]
println(extremepoints(A,b))
