local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local theta = ReplicatedStorage:WaitForChild("theta")
local eggTheta = theta:WaitForChild("EggTheta")
local EggCostTheta = require(eggTheta:WaitForChild("EggCostTheta"))
local EggDisplayTheta = require(eggTheta:WaitForChild("EggDisplayTheta"))
local EggPanelTheta = require(eggTheta:WaitForChild("EggPanelTheta"))
local EggRewardTheta = require(eggTheta:WaitForChild("EggRewardTheta"))
local PetTheta = require(theta:WaitForChild("PetTheta"))

local EggPanelRender = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local DEFAULT_REWARD_SLOT_PATHS = {
	{ "Egg", "Main", "RewardTopRow", "RewardSlot1" },
	{ "Egg", "Main", "RewardTopRow", "RewardSlot2" },
	{ "Egg", "Main", "RewardTopRow", "RewardSlot3" },
	{ "Egg", "Main", "RewardLowRow", "RewardSlot4" },
	{ "Egg", "Main", "RewardLowRow", "RewardSlot5" },
}

local DEFAULT_RESULT_TEMPLATE_PATH = { "Egg", "EggPetElement" }

local DEFAULT_REWARD_SLOT_FIELDS = {
	Icon = "Icon",
	ChanceText = "ChanceText",
	MultiplierText = "MultiplierText",
}

local DEFAULT_RESULT_TEMPLATE_FIELDS = {
	Icon = "Icon",
	NameText = "NameText",
	RarityText = "RarityText",
}

local function waitForPath(root, path)
	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
	end

	return current
end

local function formatPath(path)
	if type(path) ~= "table" then
		return tostring(path)
	end

	return table.concat(path, "/")
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

local function formatChance(reward)
	local rollWeight = math.max(0, tonumber(reward and reward.RollWeight) or 0)
	local chance = rollWeight / 100
	if chance == math.floor(chance) then
		return string.format("%.0f%%", chance)
	end

	return string.format("%.1f%%", chance)
end

local function setFirstText(root, value)
	if not root then
		return
	end

	if root:IsA("TextLabel") or root:IsA("TextButton") then
		root.Text = value
		return
	end

	local label = root:FindFirstChildWhichIsA("TextLabel", true)
		or root:FindFirstChildWhichIsA("TextButton", true)
	if label then
		label.Text = value
	end
end

local function setTextObject(textObject, value)
	if not textObject then
		return
	end

	if textObject:IsA("TextLabel") or textObject:IsA("TextButton") then
		textObject.Text = value or ""
		return
	end

	setFirstText(textObject, value or "")
end

local function setImageObject(imageObject, image)
	if imageObject and (imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton")) then
		imageObject.Image = image or ""
		imageObject.Visible = type(image) == "string" and image ~= ""
	end
end

local function setVisible(instance, isVisible)
	if not instance then
		return
	end

	if instance:IsA("GuiObject") then
		instance.Visible = isVisible == true
	elseif instance:IsA("ScreenGui") then
		instance.Enabled = isVisible == true
	end
end

local function findSlotField(slotRoot, fieldName, slotLabel)
	if not slotRoot or type(fieldName) ~= "string" or fieldName == "" then
		return nil
	end

	local field = slotRoot:FindFirstChild(fieldName, true)
	if not field then
		warn("Missing " .. slotLabel .. " field: " .. slotRoot:GetFullName() .. "/" .. fieldName)
	end

	return field
end

local function resolveRewardSlots(mainGui, slotPaths, slotFields)
	local slots = {}
	local slotCount = 0
	for index, path in ipairs(slotPaths or {}) do
		slotCount = index
		local slotRoot = waitForPath(mainGui, path)
		if not slotRoot then
			warn("Missing egg reward slot: " .. formatPath(path))
		else
			slots[index] = {
				Root = slotRoot,
				Icon = findSlotField(slotRoot, slotFields.Icon, "reward slot"),
				ChanceText = findSlotField(slotRoot, slotFields.ChanceText, "reward slot"),
				MultiplierText = findSlotField(slotRoot, slotFields.MultiplierText, "reward slot"),
			}
		end
	end

	return slots, slotCount
end

local function resolveResultTemplate(mainGui, templatePath, templateFields)
	local templateRoot = waitForPath(mainGui, templatePath)
	if not templateRoot then
		warn("Missing egg result template: " .. formatPath(templatePath))
		return nil
	end

	return {
		Root = templateRoot,
		Icon = findSlotField(templateRoot, templateFields.Icon, "result template"),
		NameText = findSlotField(templateRoot, templateFields.NameText, "result template"),
		RarityText = findSlotField(templateRoot, templateFields.RarityText, "result template"),
	}
end

local function renderRewardSlot(slot, reward)
	if not slot then
		return
	end

	local petConfig = reward and PetTheta[reward.PetTypeId]
	local hasReward = type(reward) == "table" and petConfig ~= nil

	setVisible(slot.Root, hasReward)
	if not hasReward then
		setImageObject(slot.Icon, "")
		setTextObject(slot.ChanceText, "")
		setTextObject(slot.MultiplierText, "")
		return
	end

	setImageObject(slot.Icon, petConfig.Image)
	setTextObject(slot.ChanceText, formatChance(reward))
	setTextObject(slot.MultiplierText, "x" .. formatNumber(petConfig.Multiplier))
end

local function renderFixedRewards(rewardSlots, rewardSlotCount, rewards)
	local rewardCount = type(rewards) == "table" and #rewards or 0
	for index = 1, rewardSlotCount do
		renderRewardSlot(rewardSlots[index], type(rewards) == "table" and rewards[index] or nil)
	end

	if rewardCount > rewardSlotCount then
		warn("Egg reward pool has " .. tostring(rewardCount) .. " rewards but only " .. tostring(rewardSlotCount) .. " UI slots.")
	end
end

local function setButton(button, keyText, costText)
	if not button then
		return
	end

	local labels = {}
	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			table.insert(labels, descendant)
		end
	end

	if labels[1] then
		labels[1].Text = keyText
	end
	if labels[2] then
		labels[2].Text = costText
	end
end

local function renderResultTemplate(resultTemplate, result)
	if not resultTemplate then
		return
	end

	local hasResult = type(result) == "table"
	setVisible(resultTemplate.Root, hasResult)
	setImageObject(resultTemplate.Icon, hasResult and result.Image or "")
	setTextObject(resultTemplate.NameText, hasResult and result.Name or "")
	setTextObject(resultTemplate.RarityText, hasResult and result.Rarity or "")
end

local function clearResultTemplate(resultTemplate)
	renderResultTemplate(resultTemplate, nil)
end

local function showResultMessage(resultTemplate, message)
	renderResultTemplate(resultTemplate, {
		Name = tostring(message or ""),
		Rarity = "",
		Image = "",
	})
end

local function getRollResultDisplay(rollResult, fallbackMessage)
	if type(rollResult) ~= "table" then
		return {
			Name = tostring(fallbackMessage or ""),
			Rarity = "",
			Image = "",
		}
	end

	if rollResult.IsMiss then
		return {
			Name = "No pet",
			Rarity = "",
			Image = "",
		}
	end

	local petConfig = PetTheta[rollResult.PetTypeId]
	if not petConfig then
		return {
			Name = tostring(rollResult.PetTypeId or fallbackMessage or "?"),
			Rarity = "",
			Image = "",
		}
	end

	return {
		Name = petConfig.DisplayName or tostring(rollResult.PetTypeId),
		Rarity = petConfig.Rarity or "",
		Image = petConfig.Image,
	}
end

local function createNoopView()
	return {
		Open = function() end,
		Close = function() end,
		Refresh = function() end,
		SetRollHandler = function() end,
		SetAutoRolling = function() end,
		ShowRollResults = function() end,
		ShowAutoSummary = function() end,
		IsOpen = function()
			return false
		end,
		GetCurrentEggId = function()
			return nil
		end,
	}
end

function EggPanelRender.Init(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild(EggPanelTheta.ScreenGuiName or "Main", GUI_WAIT_SECONDS)
	if not mainGui then
		return createNoopView()
	end

	local paths = EggPanelTheta.Paths or {}
	local eggScreen = waitForPath(mainGui, paths.PanelRoot or { "Egg" })
	if not eggScreen then
		return createNoopView()
	end

	local titleRoot = waitForPath(mainGui, paths.TitleRoot or { "Egg", "Title" })
	local closeButton = waitForPath(mainGui, paths.CloseButton or { "Egg", "Title", "Close" })
	local rewardSlotFields = EggPanelTheta.RewardSlotFields or DEFAULT_REWARD_SLOT_FIELDS
	local resultTemplateFields = EggPanelTheta.ResultTemplateFields or DEFAULT_RESULT_TEMPLATE_FIELDS
	local rewardSlots, rewardSlotCount = resolveRewardSlots(
		mainGui,
		paths.RewardSlots or DEFAULT_REWARD_SLOT_PATHS,
		rewardSlotFields
	)
	local resultTemplate = resolveResultTemplate(
		mainGui,
		paths.ResultTemplate or DEFAULT_RESULT_TEMPLATE_PATH,
		resultTemplateFields
	)
	local singleButton = waitForPath(mainGui, paths.SingleRollButton or { "Egg", "Button", "E" })
	local tripleButton = waitForPath(mainGui, paths.TripleRollButton or { "Egg", "Button", "R" })
	local autoButton = waitForPath(mainGui, paths.AutoRollButton or { "Egg", "Button", "T" })
	local rollButtonText = EggPanelTheta.RollButtonText or {}

	local currentEggId = nil
	local latestData = nil
	local rollHandler = nil
	local isAutoRolling = false

	eggScreen.Visible = false
	clearResultTemplate(resultTemplate)

	local view = {}

	local function renderEgg()
		local eggDisplayConfig = currentEggId and EggDisplayTheta[currentEggId]
		local eggCostConfig = currentEggId and EggCostTheta.Costs and EggCostTheta.Costs[currentEggId]
		local eggRewardConfig = currentEggId and EggRewardTheta[currentEggId]
		if not eggDisplayConfig or not eggCostConfig or not eggRewardConfig then
			return
		end

		setFirstText(titleRoot, eggDisplayConfig.DisplayName or currentEggId)

		local costAmount = tonumber(eggCostConfig.CostAmount) or 0
		setButton(singleButton, rollButtonText.Single or "E", formatNumber(costAmount))
		setButton(tripleButton, rollButtonText.Triple or "H", formatNumber(costAmount * 3))
		setButton(autoButton, isAutoRolling and (rollButtonText.AutoStop or "STOP") or (rollButtonText.Auto or "A"), formatNumber(costAmount))
		renderFixedRewards(rewardSlots, rewardSlotCount, eggRewardConfig.Rewards)
	end

	local function requestRoll(rollCount, isAuto)
		if rollHandler and currentEggId then
			rollHandler(currentEggId, rollCount, isAuto == true)
		end
	end

	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			view.Close()
		end)
	end

	if singleButton and singleButton:IsA("GuiButton") then
		singleButton.Activated:Connect(function()
			requestRoll(1, false)
		end)
	end

	if tripleButton and tripleButton:IsA("GuiButton") then
		tripleButton.Activated:Connect(function()
			requestRoll(3, false)
		end)
	end

	if autoButton and autoButton:IsA("GuiButton") then
		autoButton.Activated:Connect(function()
			requestRoll(1, true)
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not view.IsOpen() then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			requestRoll(1, false)
		elseif input.KeyCode == Enum.KeyCode.H then
			requestRoll(3, false)
		elseif input.KeyCode == Enum.KeyCode.A then
			requestRoll(1, true)
		end
	end)

	function view.Open(eggId, data)
		currentEggId = eggId
		latestData = data or latestData
		eggScreen.Visible = true
		clearResultTemplate(resultTemplate)
		renderEgg()
	end

	function view.Close()
		eggScreen.Visible = false
		isAutoRolling = false
		clearResultTemplate(resultTemplate)
	end

	function view.Refresh(data)
		latestData = data
		if eggScreen.Visible then
			renderEgg()
		end
	end

	function view.SetRollHandler(handler)
		rollHandler = handler
	end

	function view.SetAutoRolling(nextIsAutoRolling)
		isAutoRolling = nextIsAutoRolling == true
		renderEgg()
	end

	function view.ShowRollResults(rollResults, message)
		if not eggScreen.Visible then
			return
		end

		if type(rollResults) ~= "table" or #rollResults == 0 then
			showResultMessage(resultTemplate, message)
			return
		end

		renderResultTemplate(resultTemplate, getRollResultDisplay(rollResults[1], message))
	end

	function view.ShowAutoSummary(rollCount)
		if not eggScreen.Visible then
			return
		end

		showResultMessage(resultTemplate, "Auto ended: " .. formatNumber(rollCount) .. " roll")
	end

	function view.IsOpen()
		return eggScreen.Visible == true
	end

	function view.GetCurrentEggId()
		return currentEggId
	end

	return view
end

return EggPanelRender
