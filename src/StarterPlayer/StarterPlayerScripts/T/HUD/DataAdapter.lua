-- HUD/DataAdapter
-- 把玩家快照转换成 HUD 长期数值显示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))

local DataAdapter = {}

-- 将倍率数字格式化成 HUD 倍率文本。
local function formatMultiplier(value)
	return "x" .. NumberFormatter.Format(value, 1)
end

-- 计算经验条填充比例。
local function getProgressRatio(value, maxValue)
	return math.clamp(value / maxValue, 0, 1)
end

-- 重生按钮显示整数百分比；向下取整避免尚未满级时提前显示 100%。
local function formatRebirthProgress(currentLevel, maxLevel)
	local ratio = getProgressRatio(currentLevel, maxLevel)
	return tostring(math.floor(ratio * 100)) .. "%"
end

-- 根据玩家快照生成 HUD 显示模型。
function DataAdapter.BuildModel(data)
	return {
		StrengthText = NumberFormatter.Format(data.Strength),
		TrophiesText = NumberFormatter.Format(data.Trophies),
		RebirthMultiplierText = formatMultiplier(data.RebirthMultiplier),
		BarbellMultiplierText = formatMultiplier(data.BarbellMultiplier),
		PetMultiplierText = formatMultiplier(data.PetMultiplier),
		ExpRatio = getProgressRatio(data.Exp, data.MaxExp),
		LevelText = "Level " .. NumberFormatter.Format(data.Level),
		ExpText = NumberFormatter.Format(data.Exp) .. "/" .. NumberFormatter.Format(data.MaxExp),
		RebirthProgressText = formatRebirthProgress(data.Level, data.MaxLevel),
	}
end

return DataAdapter
