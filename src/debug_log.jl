export get_debug, set_debug, get_log, set_log
_debug() = cglobal((:ddf_debug, CDDLib.libcddgmp), CDDLib.Cdd_boolean)
function get_debug()
    unsafe_load(_debug())
end
function set_debug(value)
    unsafe_store!(_debug(), value)
end
_log() = cglobal((:ddf_log, CDDLib.libcddgmp), CDDLib.Cdd_boolean)
function get_log()
    unsafe_load(_log())
end
function set_log(value)
    unsafe_store!(_log(), value)
end
