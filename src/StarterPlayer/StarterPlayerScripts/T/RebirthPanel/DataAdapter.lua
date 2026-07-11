-- RebirthPanel/DataAdapter
-- 把重生快照转换成重生面板显示模型。

local DataAdapter = {}

-- 将数字格式化成面板文本。
local function formatNumber(value)
	if value == math.floor(value) then
		return string.format("%.0f", value)
	end

	return string.format("%.2f", value)
end

-- 将倍率格式化成面板文本。
local function formatMultiplier(value)
	return "x" .. string.format("%.1f", value)
end

-- 计算进度条比例。
local function getProgressRatio(value, maxValue)
	return math.clamp(value / maxValue, 0, 1)
end

-- 根据玩家快照生成重生面板显示模型。
function DataAdapter.BuildModel(data)
	local currentRebirthCount = data.RebirthCount
	local nextRebirthCount = data.NextRebirthCount
	local currentLevel = data.Level
	local currentMaxLevel = data.MaxLevel
	local nextMaxLevel = data.NextMaxLevel
	local currentMultiplier = data.RebirthMultiplier
	local nextMultiplier = data.NextRebirthMultiplier
	local tipText = ""

	if data.CanRebirth then
		tipText = "Ready at Level " .. formatNumber(currentLevel)
	else
		tipText = "Level " .. formatNumber(currentLevel)
			.. "/" .. formatNumber(data.MaxLevel)
			.. "  Exp "
			.. formatNumber(data.Exp)
			.. "/"
			.. formatNumber(data.MaxExp)
	end

	return {
		TitleText = "Rebirth " .. formatMultiplier(currentMultiplier),
		TipText = tipText,
		RebirthTexts = {
			formatNumber(currentRebirthCount),
			formatNumber(nextRebirthCount),
		},
		PowerTexts = {
			formatMultiplier(currentMultiplier) .. " Power",
			formatMultiplier(nextMultiplier) .. " Power",
		},
		MaxLevelTexts = {
			"Max Level " .. formatNumber(currentMaxLevel),
			"Max Level " .. formatNumber(nextMaxLevel),
		},
		LevelProgressRatio = getProgressRatio(currentLevel, currentMaxLevel),
		LevelProgressText = "Lv." .. formatNumber(currentLevel) .. "/" .. formatNumber(currentMaxLevel),
		RequestText = "Rebirth ",
	}
end

return DataAdapter
