macro dd_ccall_pointer_error(f, args...)
    quote
        err = Ref{Cdd_ErrorType}(0)
        ptr = ccall(($"dd_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"dd_$f", ptr, err[])
        ptr
    end
end

macro dd_ccall_error(f, args...)
    quote
        err = Ref{Cdd_ErrorType}(0)
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
        err = Ref{Cdd_ErrorType}(0)
        ptr = ccall(($"ddf_$f", libcddgmp), $(map(esc,args)...), err)
        myerror($"ddf_$f", ptr, err[])
        ptr
    end
end

macro ddf_ccall_error(f, args...)
    quote
        err = Ref{Cdd_ErrorType}(0)
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
