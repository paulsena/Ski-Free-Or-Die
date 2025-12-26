-- test/suite.lua
-- Entry point for running tests

-- Add project root to package path if not in Love (which sets it up differently)
if not love then
    package.path = package.path .. ";./?.lua;./src/?.lua"
end

local Runner = require("test.runner")

print("Running Tests for SkiFreeOrDie...")

-- Load test modules
require("test.test_seeded_random")
require("test.test_collision")

-- Run other test files here as you add them

Runner.report()
