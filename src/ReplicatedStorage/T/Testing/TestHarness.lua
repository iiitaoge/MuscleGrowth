local TestHarness = {}
TestHarness.__index = TestHarness

local function describe(value)
	if type(value) == "string" then
		return value
	end
	return tostring(value)
end

function TestHarness.New(suiteName)
	return setmetatable({
		SuiteName = suiteName or "TestSuite",
		Passed = 0,
		Failed = 0,
		Skipped = 0,
		Cleanups = {},
	}, TestHarness)
end

function TestHarness:Pass(name, detail)
	self.Passed += 1
	print(("[MorphTest][PASS] %s%s"):format(name, detail and (" - " .. describe(detail)) or ""))
	return true
end

function TestHarness:Fail(name, detail)
	self.Failed += 1
	warn(("[MorphTest][FAIL] %s%s"):format(name, detail and (" - " .. describe(detail)) or ""))
	return false
end

function TestHarness:Skip(name, detail)
	self.Skipped += 1
	print(("[MorphTest][SKIP] %s%s"):format(name, detail and (" - " .. describe(detail)) or ""))
	return false
end

function TestHarness:Check(name, condition, detail)
	if condition then
		return self:Pass(name, detail)
	end
	return self:Fail(name, detail or "condition was false")
end

function TestHarness:Equal(name, actual, expected)
	return self:Check(name, actual == expected, ("expected=%s actual=%s"):format(describe(expected), describe(actual)))
end

function TestHarness:Near(name, actual, expected, epsilon)
	actual = tonumber(actual)
	expected = tonumber(expected)
	epsilon = math.abs(tonumber(epsilon) or 0.0001)
	return self:Check(
		name,
		actual ~= nil and expected ~= nil and math.abs(actual - expected) <= epsilon,
		("expected=%s actual=%s epsilon=%s"):format(describe(expected), describe(actual), epsilon)
	)
end

function TestHarness:Eventually(name, predicate, timeoutSeconds, intervalSeconds)
	local deadline = os.clock() + math.max(0, tonumber(timeoutSeconds) or 5)
	local lastDetail = "timed out"
	repeat
		local ok, result, detail = pcall(predicate)
		if ok and result then
			return self:Pass(name, detail)
		end
		lastDetail = ok and (detail or result or lastDetail) or result
		task.wait(math.max(0.01, tonumber(intervalSeconds) or 0.05))
	until os.clock() >= deadline
	return self:Fail(name, lastDetail)
end

function TestHarness:AddCleanup(callback)
	table.insert(self.Cleanups, callback)
end

function TestHarness:RunCleanups()
	for index = #self.Cleanups, 1, -1 do
		local ok, err = pcall(self.Cleanups[index])
		if not ok then
			self:Fail("cleanup #" .. tostring(index), err)
		end
	end
	table.clear(self.Cleanups)
end

function TestHarness:Summary()
	local total = self.Passed + self.Failed + self.Skipped
	print(("[MorphTest][SUMMARY] suite=%s total=%d pass=%d fail=%d skip=%d"):format(
		self.SuiteName,
		total,
		self.Passed,
		self.Failed,
		self.Skipped
	))
	return self.Failed == 0
end

return TestHarness
