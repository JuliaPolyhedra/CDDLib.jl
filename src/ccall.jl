macro dd_ccall_pointer_error(f, args...)
    quote
        # RedundantRowsViaShooting don't modify the error code so
        # we need to set it with an initial value that means no error
        err = Ref{Cdd_ErrorType}(length(error_message))
        ptr = ccall(($"dd_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"dd_$f", ptr, err[])
        ptr
    end
end

macro dd_ccall_error(f, args...)
    quote
        # RedundantRowsViaShooting don't modify the error code so
        # we need to set it with an initial value that means no error
        err = Ref{Cdd_ErrorType}(length(error_message))
        ret = ccall(($"dd_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"dd_$f", err[])
        ret
    end
end

macro dd_ccall(f, args...)
    quote
        ret = ccall(($"dd_$f", libcddgmp), $(map(esc,args)...))
        ret
    end
end

macro ddf_ccall_pointer_error(f, args...)
    quote
        # RedundantRowsViaShooting don't modify the error code so
        # we need to set it with an initial value that means no error
        err = Ref{Cdd_ErrorType}(length(error_message))
        ptr = ccall(($"ddf_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"ddf_$f", ptr, err[])
        ptr
    end
end

macro ddf_ccall_error(f, args...)
    quote
        # RedundantRowsViaShooting don't modify the error code so
        # we need to set it with an initial value that means no error
        err = Ref{Cdd_ErrorType}(length(error_message))
        ret = ccall(($"ddf_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"ddf_$f", err[])
        ret
    end
end

macro ddf_ccall(f, args...)
    quote
        ret = ccall(($"ddf_$f", libcddgmp), $(map(esc,args)...))
        ret
    end
end


macro cdd_ccall(f, args...)
    quote
        ret = ccall(($"$f", libcddgmp), $(map(esc,args)...))
        ret
    end
end
