-- BarbellDisplay/DataAdapter
-- 把杠铃配置和玩家快照转换成场景展示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))

local DataAdapter = {}

-- 将数字格式化成展示文本。
local function formatNumber(value)
	if value == math.floor(value) then
		return string.format("%.0f", value)
	end

	return string.format("%.2f", value)
end

-- 将倍率格式化成展示文本。
local function formatMultiplier(value)
	return "x" .. string.format("%.1f", value)
end

-- 根据玩家快照生成所有杠铃展示模型。
function DataAdapter.BuildModels(data)
	local models = {}
	local trophies = data.Trophies
	local currentBarbellId = data.CurrentBarbellId

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		local requiredTrophies = barbellConfig.RequiredTrophies
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

	return models
end

return DataAdapter
