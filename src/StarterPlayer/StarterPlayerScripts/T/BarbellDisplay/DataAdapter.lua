-- BarbellDisplay/DataAdapter
-- 把杠铃配置和玩家快照转换成场景展示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))

local DataAdapter = {}

-- 将倍率格式化成展示文本。
local function formatMultiplier(value)
	return "x" .. NumberFormatter.Format(value, 1)
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
			CostText = NumberFormatter.Format(requiredTrophies),
			IsUnlocked = isUnlocked,
			IsEquipped = isEquipped,
		})
	end

	return models
end

return DataAdapter
