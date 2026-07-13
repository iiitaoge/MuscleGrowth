-- AutoAreaDisplay/DataAdapter
-- 把自动区配置和玩家快照转换成场景展示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local AutoAreaTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("AutoAreaTheta"))
local AutoAreaSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("AutoAreaSceneTheta"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))

local DataAdapter = {}

local function formatNumber(value)
	assert(type(value) == "number", "Auto area display value must be a number.")
	return NumberFormatter.Format(value)
end

local function formatRebirthRequirement(requiredRebirth)
	local suffix = requiredRebirth == 1 and "Rebirth" or "Rebirths"
	return "Requires " .. formatNumber(requiredRebirth) .. " " .. suffix
end

-- 根据玩家快照生成所有自动区场景实例的展示模型。
function DataAdapter.BuildModels(data)
	assert(type(data) == "table", "Auto area display data must be a table.")
	assert(type(data.RebirthCount) == "number", "Auto area display RebirthCount must be a number.")

	local models = {}

	for instanceId, instanceConfig in pairs(AutoAreaSceneTheta.Instances or {}) do
		assert(type(instanceId) == "string" and instanceId ~= "", "Auto area display instanceId must be a string.")
		assert(type(instanceConfig) == "table", "Auto area scene config must be a table: " .. instanceId)

		local areaId = instanceConfig.AreaId
		local areaConfig = AutoAreaTheta[areaId]
		assert(type(areaConfig) == "table", "Missing auto area gameplay config for instanceId: " .. instanceId)

		local multiplier = areaConfig.Multiplier
		local requiredRebirth = areaConfig.RequiredRebirth
		assert(type(multiplier) == "number", "Auto area Multiplier must be a number: " .. tostring(areaId))
		assert(
			type(requiredRebirth) == "number" and requiredRebirth >= 0 and requiredRebirth % 1 == 0,
			"Auto area RequiredRebirth must be a non-negative integer: " .. tostring(areaId)
		)

		models[instanceId] = {
			InstanceId = instanceId,
			AreaId = areaId,
			PowerText = "x" .. formatNumber(multiplier) .. " Power",
			RebirthText = formatRebirthRequirement(requiredRebirth),
			IsUnlocked = data.RebirthCount >= requiredRebirth,
		}
	end

	return models
end

return DataAdapter
