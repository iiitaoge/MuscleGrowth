-- HUD/DataAdapter
-- 把玩家快照转换成 HUD 长期数值显示模型。

local DataAdapter = {}

-- 将普通数字格式化成 HUD 文本。
local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

-- 将倍率数字格式化成 HUD 倍率文本。
local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

-- 计算经验条填充比例。
local function getProgressRatio(value, maxValue)
	local numberValue = tonumber(value) or 0
	local numberMaxValue = tonumber(maxValue) or 0

	if numberMaxValue <= 0 then
		return 0
	end

	return math.clamp(numberValue / numberMaxValue, 0, 1)
end

-- 根据玩家快照生成 HUD 显示模型。
function DataAdapter.BuildModel(data)
	if not data then
		return {
			StrengthText = "0",
			TrophiesText = "0",
			RebirthMultiplierText = "x1.0",
			BarbellMultiplierText = "x1.0",
			PetMultiplierText = "x1.0",
			ExpRatio = 0,
			LevelText = "Level 1",
			ExpText = "0/0",
		}
	end

	return {
		StrengthText = formatNumber(data.Strength),
		TrophiesText = formatNumber(data.Trophies),
		RebirthMultiplierText = formatMultiplier(data.RebirthMultiplier),
		BarbellMultiplierText = formatMultiplier(data.BarbellMultiplier),
		PetMultiplierText = formatMultiplier(data.PetMultiplier),
		ExpRatio = getProgressRatio(data.Exp, data.MaxExp),
		LevelText = "Level " .. formatNumber(data.Level),
		ExpText = formatNumber(data.Exp) .. "/" .. formatNumber(data.MaxExp),
	}
end

return DataAdapter
