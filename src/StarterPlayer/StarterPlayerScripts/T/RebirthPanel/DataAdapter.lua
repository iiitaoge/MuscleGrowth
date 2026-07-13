-- RebirthPanel/DataAdapter
-- 把重生快照转换成重生面板显示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))

local DataAdapter = {}

-- 将倍率格式化成面板文本。
local function formatMultiplier(value)
	return "x" .. NumberFormatter.Format(value, 1)
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
		tipText = "Ready at Level " .. NumberFormatter.Format(currentLevel)
	else
		tipText = "Level " .. NumberFormatter.Format(currentLevel)
			.. "/" .. NumberFormatter.Format(data.MaxLevel)
			.. "  Exp "
			.. NumberFormatter.Format(data.Exp)
			.. "/"
			.. NumberFormatter.Format(data.MaxExp)
	end

	return {
		TitleText = "Rebirth " .. formatMultiplier(currentMultiplier),
		TipText = tipText,
		RebirthTexts = {
			NumberFormatter.Format(currentRebirthCount),
			NumberFormatter.Format(nextRebirthCount),
		},
		PowerTexts = {
			formatMultiplier(currentMultiplier) .. " Power",
			formatMultiplier(nextMultiplier) .. " Power",
		},
		MaxLevelTexts = {
			"Max Level " .. NumberFormatter.Format(currentMaxLevel),
			"Max Level " .. NumberFormatter.Format(nextMaxLevel),
		},
		LevelProgressRatio = getProgressRatio(currentLevel, currentMaxLevel),
		LevelProgressText = "Lv."
			.. NumberFormatter.Format(currentLevel)
			.. "/"
			.. NumberFormatter.Format(currentMaxLevel),
		RequestText = "Rebirth ",
	}
end

return DataAdapter
