-- test/runner.lua
-- A minimal test runner for Lua

local Runner = {
    passes = 0,
    failures = 0,
    current_context = ""
}

function Runner.describe(desc, func)
    print("\n" .. desc)
    Runner.current_context = desc
    func()
end

function Runner.it(desc, func)
    local status, err = pcall(func)
    if status then
        Runner.passes = Runner.passes + 1
        print("  ✓ " .. desc)
    else
        Runner.failures = Runner.failures + 1
        print("  ✗ " .. desc)
        print("    " .. tostring(err))
    end
end

function Runner.assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%sExpected '%s', got '%s'", message and (message .. ": ") or "", tostring(expected), tostring(actual)))
    end
end

function Runner.assert_true(value, message)
    if not value then
        error(message or "Expected true, got " .. tostring(value))
    end
end

function Runner.assert_close(expected, actual, tolerance, message)
    tolerance = tolerance or 0.000001
    if math.abs(expected - actual) > tolerance then
        error(string.format("%sExpected %f, got %f (tolerance %f)", message and (message .. ": ") or "", expected, actual, tolerance))
    end
end

function Runner.report()
    print("\n------------------------------------------------")
    print(string.format("Tests: %d | Passed: %d | Failed: %d", Runner.passes + Runner.failures, Runner.passes, Runner.failures))
    
    local exit_code = Runner.failures > 0 and 1 or 0
    
    if love and love.event then
        love.event.quit(exit_code)
    else
        os.exit(exit_code)
    end
end

return Runner
