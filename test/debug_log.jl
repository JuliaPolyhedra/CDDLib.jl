function debug_log_test(getter, setter)
    @test getter() == 0
    setter(true)
    @test getter() == 1
    setter(false)
    @test getter() == 0
end
@testset "debug and log" begin
    debug_log_test(get_debug, set_debug)
    debug_log_test(get_log, set_log)
end
