local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
local BarbellDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("BarbellDisplayTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)

local BarbellWorldSync = {}

local DISPLAY_MODEL_NAME = BarbellDisplayTheta.DisplayModelName
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

local function alignInstanceAnchorTo(instance, targetCFrame)
	if not instance or not targetCFrame then
		return false
	end

	local sourceAnchor = BarbellObservation.GetFirstBasePart(instance)
	if not sourceAnchor then
		return pivotInstanceTo(instance, targetCFrame)
	end

	local delta = targetCFrame * sourceAnchor.CFrame:Inverse()
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

local function getRotationOffsetCFrame(rotationDegrees)
	if type(rotationDegrees) ~= "table" then
		return CFrame.new()
	end

	return CFrame.Angles(
		math.rad(tonumber(rotationDegrees.X) or 0),
		math.rad(tonumber(rotationDegrees.Y) or 0),
		math.rad(tonumber(rotationDegrees.Z) or 0)
	)
end

local function getParentPath(path)
	path = InstancePath.Components(path)
	if not path then
		return nil
	end

	local parentPath = {}
	for index = 1, #path - 1 do
		parentPath[index] = path[index]
	end

	return parentPath
end

local function ensurePath(root, path)
	path = InstancePath.Components(path)
	if not path then
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		local child = current:FindFirstChild(childName)
		if not child then
			child = Instance.new("Folder")
			child.Name = childName
			child.Parent = current
		end

		current = child
	end

	return current
end

local function requireTextLabelByPath(root, path, context)
	local label = InstancePath.FindSpec({ DisplayModel = root }, path)
	if not label then
		error(context .. " was not found under " .. root:GetFullName() .. ".", 2)
	end

	assert(label:IsA("TextLabel"), context .. " must be a TextLabel.")
	return label
end

local function prepareDisplayModel(instance)
	disableScripts(instance)

	for _, part in ipairs(BarbellObservation.GetBaseParts(instance)) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
	end
end

local function cloneDisplayBillboard(oldDisplay, nextDisplay)
	if not oldDisplay or not nextDisplay then
		return
	end

	local billboardPath = BarbellDisplayTheta.BillboardGuiPath
	local oldBillboard = InstancePath.FindSpec({ DisplayModel = oldDisplay }, billboardPath)
	if not oldBillboard then
		error("Barbell display billboard was not found under " .. oldDisplay:GetFullName() .. ".", 2)
	end
	assert(oldBillboard:IsA("BillboardGui"), "Barbell display billboard must be a BillboardGui.")

	local parent = ensurePath(nextDisplay, getParentPath(billboardPath))
	assert(parent, "Barbell display billboard parent path is invalid.")
	local existingBillboard = parent:FindFirstChild(oldBillboard.Name)
	if existingBillboard then
		existingBillboard:Destroy()
	end

	local billboardCopy = oldBillboard:Clone()
	local adornee = BarbellObservation.GetFirstBasePart(nextDisplay)
	if adornee then
		billboardCopy.Adornee = adornee
	end
	billboardCopy.Parent = parent
end

local function renderDisplayBillboard(displayNode, barbellId)
	local barbellConfig = BarbellTheta[barbellId]
	if not barbellConfig or not displayNode then
		return
	end

	local fieldPaths = BarbellDisplayTheta.FieldPaths
	local powerText = requireTextLabelByPath(displayNode, fieldPaths.PowerText, "Barbell power text")
	local trophiesText = requireTextLabelByPath(displayNode, fieldPaths.CostText, "Barbell cost text")

	powerText.Text = formatMultiplier(barbellConfig.Multiplier) .. " Gain"
	trophiesText.Text = formatNumber(barbellConfig.RequiredTrophies)
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
			local displayPivot = BarbellObservation.GetFirstBasePart(oldDisplay)
			local displayCFrame = displayPivot and displayPivot.CFrame
				or BarbellObservation.GetInstancePivot(displayHolder)

			local nextDisplay = source:Clone()
			nextDisplay.Name = DISPLAY_MODEL_NAME
			nextDisplay.Parent = displayHolder
			cloneDisplayBillboard(oldDisplay, nextDisplay)

			if oldDisplay then
				oldDisplay:Destroy()
			end

			prepareDisplayModel(nextDisplay)
			if displayCFrame then
				alignInstanceAnchorTo(
					nextDisplay,
					displayCFrame * getRotationOffsetCFrame(SceneTheta.BarbellDisplayRotationOffsetDegrees)
				)
			end
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
