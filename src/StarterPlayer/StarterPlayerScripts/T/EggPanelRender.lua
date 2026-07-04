local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local theta = ReplicatedStorage:WaitForChild("theta")
local EggTheta = require(theta:WaitForChild("EggTheta"))
local PetTheta = require(theta:WaitForChild("PetTheta"))

local EggPanelRender = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local GENERATED_ATTRIBUTE = "MuscleGrowthGeneratedEggResult"
local GENERATED_REWARD_ATTRIBUTE = "MuscleGrowthGeneratedEggReward"

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

local function setImageObject(imageObject, image)
	if imageObject and (imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton")) then
		imageObject.Image = image or ""
		imageObject.Visible = type(image) == "string" and image ~= ""
	end
end

local function hideExistingRewardRows(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and not child:GetAttribute(GENERATED_REWARD_ATTRIBUTE) then
			child.Visible = false
		end
	end
end

local function clearGeneratedRewardRows(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:GetAttribute(GENERATED_REWARD_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function createRewardCard(parent, index, totalCount)
	local card = Instance.new("Frame")
	card.Name = "Reward_" .. tostring(index)
	card:SetAttribute(GENERATED_REWARD_ATTRIBUTE, true)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	card.BorderColor3 = Color3.fromRGB(25, 25, 25)
	card.BorderSizePixel = 2
	card.Size = UDim2.new(0, 88, 0, 88)
	card.ZIndex = 20
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 245)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 210, 210)),
	})
	gradient.Rotation = 90
	gradient.Parent = card

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.52, 0)
	icon.Size = UDim2.new(0.62, 0, 0.62, 0)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 22
	icon.Parent = card

	local chanceText = Instance.new("TextLabel")
	chanceText.Name = "Chance"
	chanceText.BackgroundTransparency = 1
	chanceText.AnchorPoint = Vector2.new(0.5, 0)
	chanceText.Position = UDim2.new(0.5, 0, 0.02, 0)
	chanceText.Size = UDim2.new(0.92, 0, 0.24, 0)
	chanceText.Font = Enum.Font.FredokaOne
	chanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	chanceText.TextScaled = true
	chanceText.TextStrokeTransparency = 0
	chanceText.ZIndex = 23
	chanceText.Parent = card

	local multiplierText = Instance.new("TextLabel")
	multiplierText.Name = "Multiplier"
	multiplierText.BackgroundTransparency = 1
	multiplierText.AnchorPoint = Vector2.new(0.5, 1)
	multiplierText.Position = UDim2.new(0.5, 0, 0.98, 0)
	multiplierText.Size = UDim2.new(0.92, 0, 0.24, 0)
	multiplierText.Font = Enum.Font.FredokaOne
	multiplierText.TextColor3 = Color3.fromRGB(255, 255, 255)
	multiplierText.TextScaled = true
	multiplierText.TextStrokeTransparency = 0
	multiplierText.ZIndex = 23
	multiplierText.Parent = card

	local columns = math.min(totalCount, 5)
	local columnIndex = index
	local rowIndex = 1
	if totalCount > 3 then
		columns = 3
		rowIndex = index <= 3 and 1 or 2
		columnIndex = index <= 3 and index or index - 3
	elseif totalCount == 4 then
		columns = 2
		rowIndex = index <= 2 and 1 or 2
		columnIndex = index <= 2 and index or index - 2
	end

	local xSpacing = 0.22
	local y = rowIndex == 1 and 0.28 or 0.62
	local xStart = 0.5 - ((columns - 1) * xSpacing / 2)
	if rowIndex == 2 and totalCount == 5 then
		xStart = 0.5 - (xSpacing / 2)
	end

	card.Position = UDim2.new(xStart + (columnIndex - 1) * xSpacing, 0, y, 0)

	return card
end

local function renderGeneratedRewards(container, rewards)
	hideExistingRewardRows(container)
	clearGeneratedRewardRows(container)

	if type(rewards) ~= "table" then
		return
	end

	for index, reward in ipairs(rewards) do
		local petConfig = reward and PetTheta[reward.PetTypeId]
		local card = createRewardCard(container, index, #rewards)
		local icon = card:FindFirstChild("Icon")
		local chanceText = card:FindFirstChild("Chance")
		local multiplierText = card:FindFirstChild("Multiplier")

		setImageObject(icon, petConfig and petConfig.Image)
		if chanceText and chanceText:IsA("TextLabel") then
			chanceText.Text = formatChance(reward)
		end
		if multiplierText and multiplierText:IsA("TextLabel") then
			multiplierText.Text = petConfig and ("x" .. formatNumber(petConfig.Multiplier)) or ""
		end
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

local function clearGeneratedResults(root)
	for _, child in ipairs(root:GetChildren()) do
		if child:GetAttribute(GENERATED_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function createResultLabel(root)
	clearGeneratedResults(root)

	local label = Instance.new("TextLabel")
	label.Name = "RollResult"
	label:SetAttribute(GENERATED_ATTRIBUTE, true)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Size = UDim2.new(0.6, 0, 0.08, 0)
	label.Position = UDim2.new(0.2, 0, 0.9, 0)
	label.ZIndex = 50
	label.Parent = root

	return label
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
	local mainGui = playerGui:WaitForChild("Main", GUI_WAIT_SECONDS)
	if not mainGui then
		return createNoopView()
	end

	local eggScreen = waitForPath(mainGui, { "Egg" })
	if not eggScreen then
		return createNoopView()
	end

	local titleRoot = eggScreen:FindFirstChild("Title", true)
	local closeButton = titleRoot and titleRoot:FindFirstChild("Close", true)
	local rewardsContainer = waitForPath(eggScreen, { "Main" })
	local buttonRoot = waitForPath(eggScreen, { "Button" })
	local singleButton = buttonRoot and buttonRoot:FindFirstChild("E")
	local tripleButton = buttonRoot and buttonRoot:FindFirstChild("R")
	local autoButton = buttonRoot and buttonRoot:FindFirstChild("T")

	local currentEggId = nil
	local latestData = nil
	local rollHandler = nil
	local isAutoRolling = false

	eggScreen.Visible = false

	local view = {}

	local function renderEgg()
		local eggConfig = currentEggId and EggTheta[currentEggId]
		if not eggConfig then
			return
		end

		setFirstText(titleRoot, eggConfig.DisplayName or currentEggId)

		local costAmount = tonumber(eggConfig.CostAmount) or 0
		setButton(singleButton, "E", formatNumber(costAmount))
		setButton(tripleButton, "H", formatNumber(costAmount * 3))
		setButton(autoButton, isAutoRolling and "STOP" or "A", formatNumber(costAmount))
		renderGeneratedRewards(rewardsContainer, eggConfig.Rewards)
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
		renderEgg()
	end

	function view.Close()
		eggScreen.Visible = false
		isAutoRolling = false
		renderEgg()
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

		local names = {}
		if type(rollResults) == "table" then
			for _, rollResult in ipairs(rollResults) do
				if rollResult and rollResult.IsMiss then
					table.insert(names, "No pet")
				else
					local petConfig = rollResult and PetTheta[rollResult.PetTypeId]
					table.insert(names, petConfig and petConfig.DisplayName or tostring(rollResult and rollResult.PetTypeId or "?"))
				end
			end
		end

		local label = createResultLabel(eggScreen)
		label.Text = #names > 0 and table.concat(names, " / ") or tostring(message or "")
	end

	function view.ShowAutoSummary(rollCount)
		if not eggScreen.Visible then
			return
		end

		local label = createResultLabel(eggScreen)
		label.Text = "Auto ended: " .. formatNumber(rollCount) .. " roll"
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
