local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BarbellTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local BarbellObservation = require(script.Parent.Parent.y.BarbellObservation)
local SnapshotTransition = require(script.Parent.SnapshotTransition)

local BarbellTransition = {}

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
		powerText.Text = formatMultiplier(barbellConfig.StrengthMultiplier) .. " Power"
	end

	if trophiesText then
		trophiesText.Text = formatNumber(barbellConfig.RequiredTrophies)
	end
end

local function configurePrompt(displayHolder, barbellId)
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
		BarbellTransition.TryEquip(player, barbellId)
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

local function equipBarbellVisual(player, barbellId)
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

function BarbellTransition.RefreshDisplays()
	local dumbbellRoot, displayRoot = BarbellObservation.WaitForWorldRoots()

	if not dumbbellRoot or not displayRoot then
		warn("Dumbbell or GameDumbbell was not found. Display replacement skipped.")
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
			configurePrompt(displayHolder, barbellId)
		elseif displayHolder then
			renderDisplayBillboard(displayHolder:FindFirstChild(DISPLAY_MODEL_NAME), barbellId)
			configurePrompt(displayHolder, barbellId)
		end
	end

	return true
end

function BarbellTransition.InitWorld()
	task.spawn(function()
		BarbellTransition.RefreshDisplays()
	end)
end

function BarbellTransition.TryEquip(player, barbellId)
	if not BarbellObservation.IsValidBarbellId(barbellId) then
		return false, "Invalid barbell id"
	end

	local barbellConfig = BarbellTheta[barbellId]
	if not barbellConfig then
		return false, "Barbell does not exist"
	end

	if not BarbellObservation.IsPlayerNearDisplay(player, barbellId) then
		return false, "Player is not near this barbell"
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	local trophies = tonumber(progressState.Trophies) or 0
	local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
	if trophies < requiredTrophies then
		return false, "Not enough trophies"
	end

	local visualEquipped, visualMessage = equipBarbellVisual(player, barbellId)
	if not visualEquipped then
		return false, visualMessage
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.CurrentBarbellId = barbellId
	PlayerProgressState.Set(player, nextProgressState)

	return true, "Barbell equipped"
end

function BarbellTransition.RequestEquip(player, barbellId)
	local success, message = BarbellTransition.TryEquip(player, barbellId)

	return {
		Success = success,
		Message = message,
		Data = SnapshotTransition.GetPlayerSnapshot(player),
	}
end

return BarbellTransition
