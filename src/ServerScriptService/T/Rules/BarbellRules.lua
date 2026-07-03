local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BarbellTheta"))

local BarbellRules = {}

-- 规范化杠铃的增益倍数
local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

-- 获取指定杠铃的增益倍数，如果杠铃不存在则返回默认值1
function BarbellRules.GetBarbellMultiplier(currentBarbellId)
	local barbell = BarbellTheta[currentBarbellId]
	return normalizeMultiplier(barbell and barbell.Multiplier or 1)
end

-- 获取指定杠铃的解锁所需奖杯数，如果杠铃不存在则返回默认值0
function BarbellRules.GetBarbellRequiredTrophies(currentBarbellId)
	local barbell = BarbellTheta[currentBarbellId]
	return math.max(0, tonumber(barbell and barbell.RequiredTrophies) or 0)
end

return BarbellRules
