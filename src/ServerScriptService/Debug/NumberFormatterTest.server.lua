local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() then
	return
end

local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))
local TestHarness = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("Testing"):WaitForChild("TestHarness"))

local test = TestHarness.New("NumberFormatter")

local cases = {
	{ Name = "zero", Value = 0, Expected = "0" },
	{ Name = "plain integer", Value = 999, Expected = "999" },
	{ Name = "plain decimal trims zero", Value = 12.5, Expected = "12.5" },
	{ Name = "thousand", Value = 1000, Expected = "1K" },
	{ Name = "thousand decimal", Value = 1250, Expected = "1.25K" },
	{ Name = "rounds into next suffix", Value = 999999, Expected = "1M" },
	{ Name = "million", Value = 1000000, Expected = "1M" },
	{ Name = "trillion", Value = 10 ^ 12, Expected = "1T" },
	{ Name = "first generated suffix", Value = 10 ^ 15, Expected = "1Aa" },
	{ Name = "end of A suffixes", Value = 10 ^ 90, Expected = "1Az" },
	{ Name = "start of B suffixes", Value = 10 ^ 93, Expected = "1Ba" },
	{ Name = "negative value", Value = -1500, Expected = "-1.5K" },
}

for _, case in ipairs(cases) do
	test:Equal(case.Name, NumberFormatter.Format(case.Value), case.Expected)
end

test:Equal("custom decimal places", NumberFormatter.Format(1550, 1), "1.6K")
test:Equal("custom decimals trim zero", NumberFormatter.Format(1200, 1), "1.2K")

local function checkRejected(name, callback)
	local succeeded = pcall(callback)
	test:Check(name, not succeeded, "expected formatter call to fail")
end

checkRejected("rejects non-number", function()
	NumberFormatter.Format("1000" :: any)
end)
checkRejected("rejects NaN", function()
	NumberFormatter.Format(0 / 0)
end)
checkRejected("rejects infinity", function()
	NumberFormatter.Format(math.huge)
end)
checkRejected("rejects negative decimals", function()
	NumberFormatter.Format(1000, -1)
end)
checkRejected("rejects fractional decimals", function()
	NumberFormatter.Format(1000, 1.5)
end)
checkRejected("rejects excessive decimals", function()
	NumberFormatter.Format(1000, 16)
end)

assert(test:Summary(), "NumberFormatter tests failed.")
