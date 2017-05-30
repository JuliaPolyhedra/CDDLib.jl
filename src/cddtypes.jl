const Cdd_boolean = Cint

const Cdd_rowrange = Clong
const Cdd_colrange = Clong
const Cdd_bigrange = Clong

const Cset_type = Ptr{Culong}
const Cdd_rowset = Cset_type
const Cdd_colset = Cset_type

const Cdd_rowindex = Ptr{Clong}
const Cdd_rowflag = Ptr{Cint}
const Cdd_colindex = Ptr{Clong}

const Cdd_Amatrix{T} = Ptr{Ptr{T}}
const Cdd_Arow{T} = Ptr{T}

const Cdd_SetVector = Ptr{Cset_type}
const Cdd_Bmatrix{T} = Ptr{Ptr{T}}
const Cdd_Aincidence = Ptr{Cset_type}

primitive type Cdd_DataFileType 2040 end # char[255]

const Cdd_NumberType = Cint
# dd_Unknown=0, dd_Real, dd_Rational, dd_Integer
const dd_Unknown  = 0
const dd_Real     = 1
const dd_Rational = 2
const dd_Integer  = 3

const Cdd_RepresentationType = Cint
# dd_Unspecified=0, dd_Inequality, dd_Generator
const dd_Unspecified = 0
const dd_Inequality  = 1
const dd_Generator   = 2

const Cdd_ConversionType = Cint
# dd_IneToGen, dd_GenToIne, dd_LPMax, dd_LPMin, dd_InteriorFind

const Cdd_IncidenceOutputType = Cint
# dd_IncOff=0, dd_IncCardinality, dd_IncSet

const Cdd_AdjacencyOutputType = Cint
# dd_AdjOff=0, dd_AdjacencyList,  dd_AdjacencyDegree

const Cdd_FileInputModeType = Cint
# dd_Auto, dd_SemiAuto, dd_Manual
# Auto if a input filename is specified by command arguments

const Cdd_ErrorType = Cint
# dd_DimensionTooLarge, dd_ImproperInputFormat,
# dd_NegativeMatrixSize, dd_EmptyVrepresentation, dd_EmptyHrepresentation, dd_EmptyRepresentation,
# dd_IFileNotFound, dd_OFileNotOpen, dd_NoLPObjective, dd_NoRealNumberSupport,
# dd_NotAvailForH, dd_NotAvailForV, dd_CannotHandleLinearity,
# dd_RowIndexOutOfRange, dd_ColIndexOutOfRange,
# dd_LPCycling, dd_NumericallyInconsistent,
# dd_NoError

const Cdd_CompStatusType = Cint
# dd_InProgress, dd_AllFound, dd_RegionEmpty

# LP types

const Cdd_LPObjectiveType = Cint
# dd_LPnone=0, dd_LPmax, dd_LPmin
const dd_LPnone = Cint(0)
const dd_LPmax  = Cint(1)
const dd_LPmin  = Cint(2)

const Cdd_LPSolverType = Cint
# dd_CrissCross, dd_DualSimplex
const dd_CrissCross  = Cint(0)
const dd_DualSimplex = Cint(1)

const Cdd_LPStatusType = Cint
# dd_LPSundecided, dd_Optimal, dd_Inconsistent, dd_DualInconsistent,
# dd_StrucInconsistent, dd_StrucDualInconsistent,
# dd_Unbounded, dd_DualUnbounded
const dd_LPSundecided          = Cint(0)
const dd_Optimal               = Cint(1)
const dd_Inconsistent          = Cint(2)
const dd_DualInconsistent      = Cint(3)
const dd_StrucInconsistent     = Cint(4)
const dd_StrucDualInconsistent = Cint(5)
const dd_Unbounded             = Cint(6)
const dd_DualUnbounded         = Cint(7)

const Ctime_t = Clong # FIXME Cint in some systems ?
