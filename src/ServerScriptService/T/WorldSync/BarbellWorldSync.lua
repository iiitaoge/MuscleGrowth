local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BarbellTheta"))

local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)

local BarbellWorldSync = {}

local DISPLAY_MODEL_NAME = "DisplayModel"
local EQUIPPED_MODEL_NAME = "EquippedBarbell"
local PROMPT_BOUND_ATTRIBUTE = "MuscleGrowthBarbellPromptBound"

local function getEquipHand(character)
	return character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("HumanoidRootPart")
end

local function pivotInstanceTo(instance, targetCFrame)
	if not instance or not targetCFrame then
		return false
	end

	if instance:IsA("Model") then
		instance:PivotTo(targetCFrame)
		return true
	end

	if instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
		return true
	end

	local currentPivot = BarbellObservation.GetInstancePivot(instance)
	if not currentPivot then
		return false
	end

	local delta = targetCFrame * currentPivot:Inverse()
	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.CFrame = delta * part.CFrame
	end

	return true
end

local function disableScripts(instance)
	if instance:IsA("BaseScript") then
		instance.Disabled = true
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant.Disabled = true
		end
	end
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

local function findTextLabel(root, labelName)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("TextLabel") then
		return label
	end

	return nil
end

local function prepareDisplayModel(instance)
	disableScripts(instance)

	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
	end
end

local function cloneDisplayChildren(oldDisplay, nextDisplay)
	if not oldDisplay or not nextDisplay then
		return
	end

	for _, child in ipairs(oldDisplay:GetChildren()) do
		local childCopy = child:Clone()
		childCopy.Parent = nextDisplay
	end
end

local function renderDisplayBillboard(displayNode, barbellId)
	local barbellConfig = BarbellTheta[barbellId]
	if not barbellConfig or not displayNode then
		return
	end

	local powerText = findTextLabel(displayNode, "power")
	local trophiesText = findTextLabel(displayNode, "num")

	if powerText then
		powerText.Text = formatMultiplier(barbellConfig.Multiplier) .. " Gain"
	end

	if trophiesText then
		trophiesText.Text = formatNumber(barbellConfig.RequiredTrophies)
	end
end

local function configurePrompt(displayHolder, barbellId, onPromptTriggered)
	local prompt = displayHolder and displayHolder:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		return
	end

	local barbellConfig = BarbellTheta[barbellId]
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.ActionText = "Equip"
	prompt.ObjectText = barbellConfig and barbellConfig.DisplayName or barbellId

	if prompt:GetAttribute(PROMPT_BOUND_ATTRIBUTE) then
		return
	end

	prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
	prompt.Triggered:Connect(function(player)
		if onPromptTriggered then
			onPromptTriggered(player, barbellId)
		end
	end)
end

local function prepareEquippedModel(instance)
	disableScripts(instance)

	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
	end
end

local function clearEquippedModel(character)
	local existingModel = character:FindFirstChild(EQUIPPED_MODEL_NAME)
	if existingModel then
		existingModel:Destroy()
	end
end

local function weldToHand(instance, hand)
	local parts = BarbellObservation.GetBaseParts(instance)
	if #parts == 0 then
		return false
	end

	for _, part in ipairs(parts) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
	end

	return true
end

-- 复杂函数，难以理解
function BarbellWorldSync.EquipVisual(player, barbellId)
	local character = player.Character
	if not character then
		return false, "Character does not exist"
	end

	local hand = getEquipHand(character)
	if not hand then
		return false, "Equip hand does not exist"
	end

	local source = BarbellObservation.GetTrainSource(barbellId)
	if not source then
		return false, "Barbell model does not exist"
	end

	clearEquippedModel(character)

	local equippedModel = source:Clone()
	equippedModel.Name = EQUIPPED_MODEL_NAME
	equippedModel.Parent = character

	prepareEquippedModel(equippedModel)
	pivotInstanceTo(equippedModel, hand.CFrame * CFrame.new(0, -0.8, -0.7) * CFrame.Angles(0, math.rad(90), 0))

	if not weldToHand(equippedModel, hand) then
		equippedModel:Destroy()
		return false, "Barbell model has no BasePart"
	end

	return true, "Barbell equipped"
end

function BarbellWorldSync.RefreshDisplays(onPromptTriggered)
	local dumbbellRoot, displayRoot = BarbellObservation.WaitForWorldRoots()

	if not dumbbellRoot or not displayRoot then
		warn("ToUseScene.TrainEquipment or UseScene.SceneEquipment was not found. Display replacement skipped.")
		return false
	end

	for barbellId in pairs(BarbellTheta) do
		local source = BarbellObservation.GetTrainSource(barbellId)
		local displayHolder = BarbellObservation.GetDisplayHolder(barbellId)
		local oldDisplay = displayHolder and displayHolder:FindFirstChild(DISPLAY_MODEL_NAME)

		if source and displayHolder then
			local displayPivot = BarbellObservation.GetInstancePivot(oldDisplay)
				or BarbellObservation.GetInstancePivot(displayHolder)

			local nextDisplay = source:Clone()
			nextDisplay.Name = DISPLAY_MODEL_NAME
			nextDisplay.Parent = displayHolder
			cloneDisplayChildren(oldDisplay, nextDisplay)

			if oldDisplay then
				oldDisplay:Destroy()
			end

			prepareDisplayModel(nextDisplay)
			pivotInstanceTo(nextDisplay, displayPivot)
			renderDisplayBillboard(nextDisplay, barbellId)
			configurePrompt(displayHolder, barbellId, onPromptTriggered)
		elseif displayHolder then
			renderDisplayBillboard(displayHolder:FindFirstChild(DISPLAY_MODEL_NAME), barbellId)
			configurePrompt(displayHolder, barbellId, onPromptTriggered)
		end
	end

	return true
end

function BarbellWorldSync.InitWorld(onPromptTriggered)
	task.spawn(function()
		BarbellWorldSync.RefreshDisplays(onPromptTriggered)
	end)
end

return BarbellWorldSync
