-- BarbellDisplay/DataAdapter
-- 把杠铃配置和玩家快照转换成场景展示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))

local DataAdapter = {}

-- 将数字格式化成展示文本。
local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

-- 将倍率格式化成展示文本。
local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

-- 根据玩家快照生成所有杠铃展示模型。
function DataAdapter.BuildModels(data)
	local models = {}
	local trophies = data and tonumber(data.Trophies) or 0
	local currentBarbellId = data and data.CurrentBarbellId

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		if type(barbellId) == "string" and type(barbellConfig) == "table" then
			local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
			local isEquipped = currentBarbellId == barbellId
			local isUnlocked = trophies >= requiredTrophies

			table.insert(models, {
				BarbellId = barbellId,
				PowerText = formatMultiplier(barbellConfig.Multiplier) .. " Gain",
				CostText = formatNumber(requiredTrophies),
				IsUnlocked = isUnlocked,
				IsEquipped = isEquipped,
			})
		end
	end

	return models
end

return DataAdapter
