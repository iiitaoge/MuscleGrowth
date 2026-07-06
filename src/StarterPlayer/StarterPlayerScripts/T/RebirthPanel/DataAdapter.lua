-- RebirthPanel/DataAdapter
-- 把重生快照转换成重生面板显示模型。

local DataAdapter = {}

-- 将数字格式化成面板文本。
local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

-- 将倍率格式化成面板文本。
local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

-- 计算进度条比例。
local function getProgressRatio(value, maxValue)
	local numberValue = tonumber(value) or 0
	local numberMaxValue = tonumber(maxValue) or 0
	if numberMaxValue <= 0 then
		return 0
	end

	return math.clamp(numberValue / numberMaxValue, 0, 1)
end

-- 生成无数据时的重生面板显示模型。
local function buildEmptyModel()
	return {
		TitleText = "Rebirth",
		TipText = "",
		RebirthTexts = {},
		PowerTexts = {},
		MaxLevelTexts = {},
		LevelProgressRatio = 0,
		LevelProgressText = "Lv.0/0",
		RequestText = "",
	}
end

-- 根据玩家快照生成重生面板显示模型。
function DataAdapter.BuildModel(data)
	if not data then
		return buildEmptyModel()
	end

	local currentRebirthCount = tonumber(data.RebirthCount) or 0
	local nextRebirthCount = tonumber(data.NextRebirthCount) or currentRebirthCount + 1
	local currentLevel = tonumber(data.Level) or 0
	local currentMaxLevel = tonumber(data.MaxLevel) or 1
	local nextMaxLevel = tonumber(data.NextMaxLevel) or currentMaxLevel
	local currentMultiplier = tonumber(data.RebirthMultiplier) or 1
	local nextMultiplier = tonumber(data.NextRebirthMultiplier) or currentMultiplier
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
			"{" .. formatNumber(currentRebirthCount) .. "}",
			"{" .. formatNumber(nextRebirthCount) .. "}",
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
		RequestText = "Rebirth " .. formatMultiplier(nextMultiplier),
	}
end

return DataAdapter
