-- EggRevealPanel/DataAdapter
-- 把服务端抽奖结果转换成开奖展示层的渲染模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local EggDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("EggDisplayTheta"))
local PetTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PetTheta"))
local UIContract = require(script.Parent.Parent.UIContract)

local DataAdapter = {}

local function buildCardModel(rollResult)
	if type(rollResult) ~= "table" then
		return nil
	end

	if rollResult.IsMiss then
		return {
			Icon = "",
			NameText = "No pet",
			RarityText = "",
		}
	end

	local petTypeId = rollResult.PetTypeId
	local petConfig = petTypeId and PetTheta[petTypeId]
	if not petConfig then
		return {
			Icon = "",
			NameText = tostring(petTypeId or "?"),
			RarityText = "",
		}
	end

	return {
		Icon = petConfig.Image or "",
		NameText = petConfig.DisplayName or tostring(petTypeId),
		RarityText = petConfig.Rarity or "",
	}
end

function DataAdapter.BuildRevealModel(eggId, rollResults)
	local eggDisplayConfig = eggId and EggDisplayTheta[eggId]
	local cards = {}

	for _, rollResult in ipairs(type(rollResults) == "table" and rollResults or {}) do
		local cardModel = buildCardModel(rollResult)
		if cardModel then
			table.insert(cards, cardModel)
		end
	end

	return {
		EggIcon = eggDisplayConfig and eggDisplayConfig.ModelIcon or "",
		Cards = cards,
		ContinueText = UIContract.GetConfig("EggRevealPanel").ContinuePromptText,
	}
end

return DataAdapter
