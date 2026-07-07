-- EggPanel/DataAdapter
-- 把蛋配置、宠物配置和抽奖结果转换成蛋面板渲染模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local eggTheta = theta:WaitForChild("EggTheta")
local EggCostTheta = require(eggTheta:WaitForChild("EggCostTheta"))
local EggDisplayTheta = require(eggTheta:WaitForChild("EggDisplayTheta"))
local EggRewardTheta = require(eggTheta:WaitForChild("EggRewardTheta"))
local PetTheta = require(theta:WaitForChild("PetTheta"))
local UIContract = require(script.Parent.Parent.UIContract)

local DataAdapter = {}

-- 将数字格式化成 UI 文本。
local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

-- 将奖池权重转换成概率文本。
local function formatChance(reward)
	local rollWeight = math.max(0, tonumber(reward and reward.RollWeight) or 0)
	local chance = rollWeight / 100
	if chance == math.floor(chance) then
		return string.format("%.0f%%", chance)
	end

	return string.format("%.1f%%", chance)
end

-- 根据单个奖池项生成奖池槽显示模型。
local function buildRewardModel(reward)
	local petConfig = reward and PetTheta[reward.PetTypeId]
	if not petConfig then
		return nil
	end

	return {
		Icon = petConfig.Image,
		ChanceText = formatChance(reward),
		MultiplierText = "x" .. formatNumber(petConfig.Multiplier),
		PetTypeId = reward.PetTypeId,
	}
end

-- 根据按键文案和消耗数值生成按钮显示模型。
local function buildButtonModel(keyText, costAmount)
	return {
		KeyText = keyText,
		CostText = formatNumber(costAmount),
	}
end

-- 生成当前蛋面板的完整显示模型。
function DataAdapter.BuildEggModel(eggId, isAutoRolling)
	local eggDisplayConfig = eggId and EggDisplayTheta[eggId]
	local eggCostConfig = eggId and EggCostTheta.Costs and EggCostTheta.Costs[eggId]
	local eggRewardConfig = eggId and EggRewardTheta[eggId]
	if not eggDisplayConfig or not eggCostConfig or not eggRewardConfig then
		return nil
	end

	local rewards = {}
	for _, reward in ipairs(eggRewardConfig.Rewards or {}) do
		table.insert(rewards, buildRewardModel(reward))
	end

	local costAmount = tonumber(eggCostConfig.CostAmount) or 0
	local rollButtonText = UIContract.GetConfig("EggPanel").RollButtonText

	return {
		Title = eggDisplayConfig.DisplayName or eggId,
		Rewards = rewards,
		Buttons = {
			Single = buildButtonModel(rollButtonText.Single, costAmount),
			Triple = buildButtonModel(rollButtonText.Triple, costAmount * 3),
			Auto = buildButtonModel(
				isAutoRolling and rollButtonText.AutoStop or rollButtonText.Auto,
				costAmount
			),
		},
	}
end

-- 生成抽奖结果模板的显示模型。
function DataAdapter.BuildRollResultModel(rollResults, message)
	local rollResult = type(rollResults) == "table" and rollResults[1] or nil
	if type(rollResult) ~= "table" then
		return {
			NameText = tostring(message or ""),
			RarityText = "",
			Icon = "",
		}
	end

	if rollResult.IsMiss then
		return {
			NameText = "No pet",
			RarityText = "",
			Icon = "",
		}
	end

	local petConfig = PetTheta[rollResult.PetTypeId]
	if not petConfig then
		return {
			NameText = tostring(rollResult.PetTypeId or message or "?"),
			RarityText = "",
			Icon = "",
		}
	end

	return {
		NameText = petConfig.DisplayName or tostring(rollResult.PetTypeId),
		RarityText = petConfig.Rarity or "",
		Icon = petConfig.Image,
	}
end

-- 生成自动抽停止时的总结显示模型。
function DataAdapter.BuildAutoSummaryModel(rollCount)
	return {
		NameText = "Auto ended: " .. formatNumber(rollCount) .. " roll",
		RarityText = "",
		Icon = "",
	}
end

return DataAdapter
