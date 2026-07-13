-- FloatingGain/DataAdapter
-- 把训练增长和奖杯差值转换成飘字文本。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))

local DataAdapter = {}

local function requireNumber(value, context)
	assert(type(value) == "number", context .. " must be a number.")
	return value
end

function DataAdapter.BuildGainText(amount)
	local numberAmount = requireNumber(amount, "Floating gain amount")
	assert(numberAmount > 0, "Floating gain amount must be greater than 0.")

	return "+" .. NumberFormatter.Format(numberAmount)
end

function DataAdapter.BuildSplitGainTexts(amount, partCount)
	local numberAmount = requireNumber(amount, "Floating gain amount")
	assert(numberAmount > 0, "Floating gain amount must be greater than 0.")
	assert(
		type(partCount) == "number" and partCount >= 1 and partCount == math.floor(partCount),
		"Floating gain part count must be a positive integer."
	)

	local splitAmount = numberAmount / partCount
	local texts = {}
	for index = 1, partCount do
		texts[index] = DataAdapter.BuildGainText(splitAmount)
	end

	return texts
end

function DataAdapter.ReadTrophies(data)
	assert(type(data) == "table", "Floating gain snapshot data must be a table.")
	return requireNumber(data.Trophies, "Snapshot Trophies")
end

function DataAdapter.CalculateTrophyGain(previousTrophies, nextTrophies)
	requireNumber(previousTrophies, "Previous trophies")
	requireNumber(nextTrophies, "Next trophies")

	return math.max(0, nextTrophies - previousTrophies)
end

return DataAdapter
