error_message = [
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
  "Numerically inconsistent"]
function myerror(err::Cdd_ErrorType)
    if err < 0 || err > 17
        error("This should not happen, please report this bug")
    elseif err < 17 # 17 means no error
        error(error_message[err+1])
    end
end
