const error_message = [
  "Dimension too large",
  "Improper input format",
  "Negative matrix size",
  "Empty V representation",
  "Empty H representation",
  "Empty Representation",
  "Input file not found",
  "Output file not open",
  "No LP objective",
  "No real number support",
  "Not available for H",
  "Not available for V",
  "Cannot handle linearity",
  "Row index out of range",
  "Col index out of range",
  "LP cycling",
  "Numerically inconsistent",
]

function myerror(func_name::String, err::Cdd_ErrorType)
    idx = err + 1
    if idx in eachindex(error_message)
        error(func_name, " : ", error_message[err+1])
    elseif err != length(error_message) # 17 means no error
        error("$func_name gave an error code of $err which is out of the range of known error code. Pleasre report this by opening an issue at https://github.com/JuliaPolyhedra/CDDLib.jl.")
    end
end
function myerror(func_name::String, ptr::Ptr, err::Cdd_ErrorType)
    myerror(func_name, err)
    if ptr == C_NULL
        error("$func_name returned a NULL pointer but did not provide any error. Please report this by opening an issue at https://github.com/JuliaPolyhedra/CDDLib.jl.")
    end
end
