mutable struct Cdd_PolyhedraData{T<:MyType}
    representation::Cdd_RepresentationType
    # given representation
    homogeneous::Cdd_boolean
    d::Cdd_colrange
    m::Cdd_rowrange
    A::Cdd_Amatrix{T}
    # Inequality System:  m times d matrix
    numbtype::Cdd_NumberType
    child::Ptr{Nothing} # dd_ConePtr
    # pointing to the homogenized cone data
    m_alloc::Cdd_rowrange
    # allocated row size of matrix A
    d_alloc::Cdd_colrange
    # allocated col size of matrix A
    c::Cdd_Arow{T}
    # cost vector

    EqualityIndex::Cdd_rowflag
    # ith component is 1 if it is equality, -1 if it is strict inequality, 0 otherwise.

    IsEmpty::Cdd_boolean
    # This is to tell whether the set is empty or not

    NondegAssumed::Cdd_boolean
    InitBasisAtBottom::Cdd_boolean
    RestrictedEnumeration::Cdd_boolean
    RelaxedEnumeration::Cdd_boolean

    m1::Cdd_rowrange
    #    = m or m+1 (when representation=Inequality && !homogeneous)
    #    This data is written after dd_ConeDataLoad is called.  This
    #    determines the size of Ainc.
    AincGenerated::Cdd_boolean
    #    Indicates whether Ainc, Ared, Adom are all computed.
    #    All the variables below are valid only when this is TRUE
    ldim::Cdd_colrange
    # linearity dimension
    n::Cdd_bigrange
    #    the size of output = total number of rays
    #    in the computed cone + linearity dimension
    Ainc::Cdd_Aincidence
    #    incidence of input and output
    Ared::Cdd_rowset
    #    redundant set of rows whose removal results in a minimal system
    Adom::Cdd_rowset
    #    dominant set of rows (those containing all rays).
end

function dd_matrix2poly(matrix::Ptr{Cdd_MatrixData{Cdouble}})
    return @ddf_ccall_pointer_error(
        DDMatrix2Poly,
        Ptr{Cdd_PolyhedraData{Cdouble}},
        (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}),
        matrix,
    )
end
function dd_matrix2poly(matrix::Ptr{Cdd_MatrixData{GMPRational}})
    return @dd_ccall_pointer_error(
        DDMatrix2Poly,
        Ptr{Cdd_PolyhedraData{GMPRational}},
        (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}),
        matrix,
    )
end

mutable struct CDDPolyhedra{T<:PolyType, S}
    poly::Ptr{Cdd_PolyhedraData{S}}
    inequality::Bool # The input type is inequality

    function CDDPolyhedra{T, S}(matrix::CDDMatrix{T}) where {T <: PolyType, S}
        polyptr = dd_matrix2poly(matrix.matrix)
        poly = new{T, S}(polyptr, isaninequalityrepresentation(matrix))
        finalizer(myfree, poly)
        poly
    end

end

function myfree(poly::CDDPolyhedra{Cdouble})
    @ddf_ccall FreePolyhedra Nothing (Ptr{Cdd_PolyhedraData{Cdouble}},) poly.poly
end
function myfree(poly::CDDPolyhedra{Rational{BigInt}})
    @dd_ccall FreePolyhedra Nothing (Ptr{Cdd_PolyhedraData{GMPRational}},) poly.poly
end

CDDPolyhedra(matrix::CDDMatrix{T, S}) where {T, S} = CDDPolyhedra{T, S}(matrix)
CDDPolyhedra(rep::Representation) = CDDPolyhedra(CDDMatrix(rep))

function Base.convert(::Type{CDDPolyhedra{T, S}}, matrix::CDDMatrix{T, S}) where {T, S}
    CDDPolyhedra{T, S}(matrix)
end
Base.convert(::Type{CDDPolyhedra{T, S}}, repr::Representation{T}) where {T, S} = CDDPolyhedra(CDDMatrix(repr))

function dd_copyinequalities(poly::Ptr{Cdd_PolyhedraData{Cdouble}})
    @ddf_ccall CopyInequalities Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_PolyhedraData{Cdouble}},) poly
end
function dd_copyinequalities(poly::Ptr{Cdd_PolyhedraData{GMPRational}})
    @dd_ccall CopyInequalities Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_PolyhedraData{GMPRational}},) poly
end
function copyinequalities(poly::CDDPolyhedra)
    CDDInequalityMatrix(dd_copyinequalities(poly.poly))
end

function dd_copygenerators(poly::Ptr{Cdd_PolyhedraData{Cdouble}})
    @ddf_ccall CopyGenerators Ptr{Cdd_MatrixData{Cdouble}} (Ptr{Cdd_PolyhedraData{Cdouble}},) poly
end
function dd_copygenerators(poly::Ptr{Cdd_PolyhedraData{GMPRational}})
    @dd_ccall CopyGenerators Ptr{Cdd_MatrixData{GMPRational}} (Ptr{Cdd_PolyhedraData{GMPRational}},) poly
end

function copygenerators(poly::CDDPolyhedra)
    CDDGeneratorMatrix(dd_copygenerators(poly.poly))
end

# Incidence information
for c_fun in (:CopyIncidence, :CopyInputIncidence)
    jl_fun = Symbol(lowercase(String(c_fun)))
    dd_fun = Symbol(:dd_, jl_fun)

    @eval begin
        function $(dd_fun)(poly::Ptr{Cdd_PolyhedraData{Cdouble}})
            @ddf_ccall $c_fun Ptr{SetFamily} (Ptr{Cdd_PolyhedraData{Cdouble}},) poly
        end
        function $(dd_fun)(poly::Ptr{Cdd_PolyhedraData{GMPRational}})
            @dd_ccall $c_fun Ptr{SetFamily} (Ptr{Cdd_PolyhedraData{GMPRational}},) poly
        end

        function $(jl_fun)(poly::CDDPolyhedra)
            return convert_free(Vector{BitSet}, $(dd_fun)(poly.poly))
        end
    end
end

"""
    copyincidence(poly)

Return the incidence representation of the computed representation in `poly`.

# Arguments

- `poly::CDDPolyhedra`

# Returns

- `::Vector{BitSet}`

#Examples

```julia
julia> using CDDLib, Polyhedra

julia> A = [1 1; 1 -1; -1 0]; b = [1, 0, 0];

julia> p = polyhedron(hrep(A, b), CDDLib.Library(:exact))
Polyhedron CDDLib.Polyhedron{Rational{BigInt}}:
3-element iterator of HalfSpace{Rational{BigInt}, Vector{Rational{BigInt}}}:
 HalfSpace(Rational{BigInt}[1, 1], 1//1)
 HalfSpace(Rational{BigInt}[1, -1], 0//1)
 HalfSpace(Rational{BigInt}[-1, 0], 0//1)

julia> vrep(p)
V-representation CDDGeneratorMatrix{Rational{BigInt}, GMPRational}:
3-element iterator of Vector{Rational{BigInt}}:
 Rational{BigInt}[1//2, 1//2]
 Rational{BigInt}[0, 1]
 Rational{BigInt}[0, 0]

julia> copyincidence(p.poly)
3-element Vector{BitSet}:
 BitSet([1, 2])
 BitSet([1, 3])
 BitSet([2, 3])
```

Degenerate case:

```julia
julia> A = [1 1; 1 -1; -1 0; 1 0]; b = [1, 0, 0, 1//2];

julia> p = polyhedron(hrep(A, b), CDDLib.Library(:exact))
Polyhedron CDDLib.Polyhedron{Rational{BigInt}}:
4-element iterator of HalfSpace{Rational{BigInt}, Vector{Rational{BigInt}}}:
 HalfSpace(Rational{BigInt}[1, 1], 1//1)
 HalfSpace(Rational{BigInt}[1, -1], 0//1)
 HalfSpace(Rational{BigInt}[-1, 0], 0//1)
 HalfSpace(Rational{BigInt}[1, 0], 1//2)

julia> vrep(p)
V-representation CDDGeneratorMatrix{Rational{BigInt}, GMPRational}:
3-element iterator of Vector{Rational{BigInt}}:
 Rational{BigInt}[0, 0]
 Rational{BigInt}[0, 1]
 Rational{BigInt}[1//2, 1//2]

julia> copyincidence(p.poly)
3-element Vector{BitSet}:
 BitSet([2, 3])
 BitSet([1, 3])
 BitSet([1, 2, 4])
```
"""
copyincidence

"""
    copyinputincidence(poly)

Return the incidence representation of the input representation in `poly`.

# Arguments

- `poly::CDDPolyhedra`

# Returns

- `::Vector{BitSet}`

#Examples

```julia
julia> using CDDLib, Polyhedra

julia> V = [[1//2, 1//2], [0, 1], [0, 0]];

julia> p = polyhedron(vrep(V), CDDLib.Library(:exact))
Polyhedron CDDLib.Polyhedron{Rational{BigInt}}:
3-element iterator of Vector{Rational{BigInt}}:
 Rational{BigInt}[1//2, 1//2]
 Rational{BigInt}[0, 1]
 Rational{BigInt}[0, 0]

julia> hrep(p)
H-representation CDDInequalityMatrix{Rational{BigInt}, GMPRational}:
3-element iterator of HalfSpace{Rational{BigInt}, Vector{Rational{BigInt}}}:
 HalfSpace(Rational{BigInt}[1, 1], 1//1)
 HalfSpace(Rational{BigInt}[-1, 0], 0//1)
 HalfSpace(Rational{BigInt}[1, -1], 0//1)

julia> copyinputincidence(p.poly)
3-element Vector{BitSet}:
 BitSet([1, 3])
 BitSet([1, 2])
 BitSet([2, 3])
```
"""
copyinputincidence

function switchinputtype!(poly::CDDPolyhedra)
    if poly.inequality
        ext = copygenerators(poly)
        myfree(poly)
        poly.poly = dd_matrix2poly(ext.matrix)
    else
        ine = copyinequalities(poly)
        myfree(poly)
        poly.poly = dd_matrix2poly(ine.matrix)
    end
    poly.inequality = ~poly.inequality
end

export CDDPolyhedra, copyinequalities, copygenerators, copyincidence, copyinputincidence, switchinputtype!
