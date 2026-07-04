local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local theta = ReplicatedStorage:WaitForChild("theta")

local AutoAreaTheta = require(theta:WaitForChild("AutoAreaTheta"))
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))
local EggTheta = require(theta:WaitForChild("EggTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))
local RemoteTheta = require(theta:WaitForChild("RemoteTheta"))
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local EggPanelRender = require(script.Parent.Parent.T.EggPanelRender)
local HUDRender = require(script.Parent.Parent.T.HUDRender)
local PetInventoryRender = require(script.Parent.Parent.T.PetInventoryRender)
local PlayerVisualSync = require(script.Parent.Parent.T.PlayerVisualSync)
local RebirthPanelRender = require(script.Parent.Parent.T.RebirthPanelRender)

local function waitForRemote(remoteId)
	local remoteSpec = RemoteTheta[remoteId]
	assert(remoteSpec, "Missing remote theta: " .. tostring(remoteId))

	return ReplicatedStorage:WaitForChild(remoteSpec.Name)
end

local getData = waitForRemote("GetData")
local moveStart = waitForRemote("MoveStart")
local moveStop = waitForRemote("MoveStop")
local onAutoArea = waitForRemote("OnAutoArea")
local leaveAutoArea = waitForRemote("LeaveAutoArea")
local requestRebirth = waitForRemote("RequestRebirth")
local requestPetEquip = waitForRemote("RequestPetEquip")
local requestPetUnequip = waitForRemote("RequestPetUnequip")
local requestPetRoll = waitForRemote("RequestPetRoll")
local requestPetDelete = waitForRemote("RequestPetDelete")

local hudView = HUDRender.Init(player)
local petInventoryView = PetInventoryRender.Init(player)
local rebirthPanelView = RebirthPanelRender.Init(player)
local eggPanelView = EggPanelRender.Init(player)

PlayerVisualSync.Init()

local latestData = nil
local isMoving = false
local currentAutoAreaId = nil
local isRequestingPetRoll = false
local isAutoRolling = false
local lastTrainingGainSerial = tonumber(player:GetAttribute(SceneTheta.Attributes.LastTrainingGainSerial)) or 0
local refreshUiFromServer = nil

player:GetAttributeChangedSignal(SceneTheta.Attributes.LastTrainingGainSerial):Connect(function()
	local nextSerial = tonumber(player:GetAttribute(SceneTheta.Attributes.LastTrainingGainSerial)) or 0
	if nextSerial <= lastTrainingGainSerial then
		lastTrainingGainSerial = nextSerial
		return
	end

	lastTrainingGainSerial = nextSerial
	hudView.PlayStrengthGain(player:GetAttribute(SceneTheta.Attributes.LastTrainingStrengthGain))
	if refreshUiFromServer then
		refreshUiFromServer()
	end
end)

local function getUseSceneRoot()
	return Workspace:WaitForChild(SceneTheta.WorkspaceRootName, 10)
end

local function getSceneChild(childName)
	local useScene = getUseSceneRoot()
	return useScene and useScene:WaitForChild(childName, 10)
end

local function getInstancePosition(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot().Position
	end

	if instance:IsA("BasePart") then
		return instance.Position
	end

	local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)
	return firstPart and firstPart.Position or nil
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

local function setDisplayText(root, labelName, value)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function setDisplayVisible(root, labelName, isVisible)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("GuiObject") then
		label.Visible = isVisible == true
	end
end

local function refreshBarbellDisplays(data)
	local sceneEquipment = getSceneChild(SceneTheta.SceneEquipmentRootName)
	if not sceneEquipment then
		return
	end

	local trophies = data and tonumber(data.Trophies) or 0
	local currentBarbellId = data and data.CurrentBarbellId

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		if type(barbellId) == "string" and type(barbellConfig) == "table" then
			local barbellNode = sceneEquipment:FindFirstChild(barbellId)
			local displayNode = barbellNode and (barbellNode:FindFirstChild(SceneTheta.BarbellDisplayModelName) or barbellNode)
			local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
			local isEquipped = currentBarbellId == barbellId
			local isUnlocked = trophies >= requiredTrophies

			setDisplayText(displayNode, "power", formatMultiplier(barbellConfig.Multiplier) .. " Gain")
			setDisplayText(displayNode, "num", formatNumber(requiredTrophies))
			setDisplayVisible(displayNode, "Locked", not isUnlocked)
			setDisplayVisible(displayNode, "Equip", isUnlocked and not isEquipped)
			setDisplayVisible(displayNode, "Equipped", isEquipped)
		end
	end
end

local function refreshUi(data)
	latestData = data
	hudView.Refresh(data)
	petInventoryView.Refresh(data)
	rebirthPanelView.Refresh(data)
	eggPanelView.Refresh(data)
	refreshBarbellDisplays(data)
end

function refreshUiFromServer()
	local success, data = pcall(function()
		return getData:InvokeServer()
	end)

	if not success then
		warn(data)
		return nil
	end

	refreshUi(data)
	return data
end

-- 设置是否移动或者停止
local function setMoving(nextIsMoving)
	if isMoving == nextIsMoving then
		return
	end

	isMoving = nextIsMoving
	if isMoving then
		moveStart:FireServer()
	else
		moveStop:FireServer()
	end
end

local function resetAutoAreas()
	if currentAutoAreaId ~= nil then
		local areaId = currentAutoAreaId
		currentAutoAreaId = nil
		leaveAutoArea:FireServer(areaId)
	end
end

local function bindMovingDetection(character)
	setMoving(false)
	resetAutoAreas()

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Running:Connect(function(speed)
		setMoving(speed > 0.1)
	end)

	humanoid.Died:Connect(function()
		setMoving(false)
		resetAutoAreas()
	end)
end

local function isLocalRootPart(hit)
	local character = player.Character
	return character ~= nil and hit == character:FindFirstChild("HumanoidRootPart")
end

local function bindAutoArea(areaId)
	local trainAreas = getSceneChild(SceneTheta.SceneTrainAreaRootName)
	if not trainAreas then
		warn("Missing train area root")
		return
	end

	local area = trainAreas:WaitForChild(areaId, 10)
	if not area then
		warn("Missing auto area: " .. areaId)
		return
	end

	local touch = area:WaitForChild("Touch", 10)
	if not touch or not touch:IsA("BasePart") then
		warn("Missing auto area Touch part: " .. areaId)
		return
	end

	touch.Touched:Connect(function(hit)
		if not isLocalRootPart(hit) or currentAutoAreaId == areaId then
			return
		end

		currentAutoAreaId = areaId
		onAutoArea:FireServer(areaId)
	end)

	touch.TouchEnded:Connect(function(hit)
		if not isLocalRootPart(hit) or currentAutoAreaId ~= areaId then
			return
		end

		currentAutoAreaId = nil
		leaveAutoArea:FireServer(areaId)
	end)
end

local function getEggInteractionNode(eggId)
	local sceneEgg = getSceneChild(SceneTheta.SceneEggRootName)
	local eggHolder = sceneEgg and sceneEgg:FindFirstChild(eggId)
	return eggHolder and (eggHolder:FindFirstChild(SceneTheta.EggPromptPartName) or eggHolder)
end

local function isPlayerNearEgg(eggId)
	local eggConfig = EggTheta[eggId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local interactionPosition = getInstancePosition(getEggInteractionNode(eggId))
	if not eggConfig or not root or not interactionPosition then
		return false
	end

	local interactionDistance = tonumber(eggConfig.InteractionDistance) or SceneTheta.EggInteractionDistance
	return (root.Position - interactionPosition).Magnitude <= interactionDistance + 2
end

local function bindEggPrompt(eggId)
	local sceneEgg = getSceneChild(SceneTheta.SceneEggRootName)
	local eggHolder = sceneEgg and sceneEgg:WaitForChild(eggId, 10)
	if not eggHolder then
		warn("Missing egg holder: " .. eggId)
		return
	end

	local prompt = eggHolder:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		warn("Missing egg prompt: " .. eggId)
		return
	end

	prompt.Triggered:Connect(function()
		eggPanelView.Open(eggId, latestData)
		refreshUiFromServer()
	end)
end

local function invokePetRoll(eggId, rollCount)
	if isRequestingPetRoll then
		return nil
	end

	isRequestingPetRoll = true
	local success, result = pcall(function()
		return requestPetRoll:InvokeServer(eggId, rollCount)
	end)
	isRequestingPetRoll = false

	if not success then
		warn(result)
		return nil
	end

	if result and result.Data then
		refreshUi(result.Data)
	end

	if result and result.Success == false and result.Message then
		warn(result.Message)
	end

	eggPanelView.ShowRollResults(result and result.RollResults, result and result.Message)
	return result
end

local function stopAutoRoll(showSummary, rolledCount)
	isAutoRolling = false
	eggPanelView.SetAutoRolling(false)
	if showSummary then
		eggPanelView.ShowAutoSummary(rolledCount or 0)
	end
end

local function startAutoRoll(eggId)
	if isAutoRolling then
		stopAutoRoll(false, 0)
		return
	end

	isAutoRolling = true
	eggPanelView.SetAutoRolling(true)

	task.spawn(function()
		local rolledCount = 0
		local cooldown = math.max(0.1, tonumber(PetSystemTheta.RollCooldownSeconds) or 0.5)

		while isAutoRolling and eggPanelView.IsOpen() and eggPanelView.GetCurrentEggId() == eggId do
			if not isPlayerNearEgg(eggId) then
				break
			end

			local result = invokePetRoll(eggId, 1)
			if not result or result.Success ~= true then
				break
			end

			rolledCount += #(result.RollResults or {})
			task.wait(cooldown + 0.05)
		end

		stopAutoRoll(eggPanelView.IsOpen(), rolledCount)
	end)
end

rebirthPanelView.SetRequestHandler(function()
	local success, result = pcall(function()
		return requestRebirth:InvokeServer()
	end)

	if not success then
		warn(result)
		return
	end

	if result and result.Data then
		refreshUi(result.Data)
	end

	if result and result.Success == false and result.Message then
		warn(result.Message)
	end
end)

local function handlePetRequestResult(success, result)
	if not success then
		warn(result)
		return nil
	end

	if result and result.Data then
		refreshUi(result.Data)
	end

	if result and result.Success == false and result.Message then
		warn(result.Message)
	end

	return result
end

local function invokePetEquip(petInstanceId, slotIndex)
	return handlePetRequestResult(pcall(function()
		return requestPetEquip:InvokeServer(petInstanceId, slotIndex)
	end))
end

local function invokePetUnequip(slotIndex)
	return handlePetRequestResult(pcall(function()
		return requestPetUnequip:InvokeServer(slotIndex)
	end))
end

local function getOwnedPetsByBestMultiplier()
	local ownedPets = {}
	if type(latestData and latestData.OwnedPetSnapshots) == "table" then
		for _, petSnapshot in ipairs(latestData.OwnedPetSnapshots) do
			if type(petSnapshot) == "table" and type(petSnapshot.InstanceId) == "string" then
				table.insert(ownedPets, petSnapshot)
			end
		end
	end

	table.sort(ownedPets, function(left, right)
		local leftMultiplier = tonumber(left.Multiplier) or 0
		local rightMultiplier = tonumber(right.Multiplier) or 0
		if leftMultiplier == rightMultiplier then
			return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
		end

		return leftMultiplier > rightMultiplier
	end)

	return ownedPets
end

petInventoryView.SetActionHandlers({
	Equip = function(petInstanceId, slotIndex)
		invokePetEquip(petInstanceId, slotIndex)
	end,
	Unequip = function(slotIndex)
		invokePetUnequip(slotIndex)
	end,
	EquipBest = function()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		local ownedPets = getOwnedPetsByBestMultiplier()

		for slotIndex = 1, maxEquippedPets do
			invokePetUnequip(slotIndex)
		end

		for slotIndex = 1, math.min(maxEquippedPets, #ownedPets) do
			invokePetEquip(ownedPets[slotIndex].InstanceId, slotIndex)
		end
	end,
	UnequipAll = function()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		for slotIndex = 1, maxEquippedPets do
			invokePetUnequip(slotIndex)
		end
	end,
	DeleteSelected = function(petInstanceIds)
		if type(petInstanceIds) ~= "table" or #petInstanceIds <= 0 then
			warn("No pets selected")
			return
		end

		handlePetRequestResult(pcall(function()
			return requestPetDelete:InvokeServer(petInstanceIds)
		end))
	end,
})

eggPanelView.SetRollHandler(function(eggId, rollCount, isAuto)
	if isAuto then
		startAutoRoll(eggId)
		return
	end

	if isAutoRolling then
		return
	end

	if not isPlayerNearEgg(eggId) then
		warn("Player is not near this egg")
		return
	end

	invokePetRoll(eggId, rollCount)
end)

local rebirthButton = hudView.GetRebirthButton()
if rebirthButton then
	rebirthButton.Activated:Connect(function()
		rebirthPanelView.SetOpen(true)
		refreshUiFromServer()
	end)
end

local petButton = petInventoryView.GetPetButton()
if petButton then
	petButton.Activated:Connect(function()
		petInventoryView.SetOpen(true)
		refreshUiFromServer()
	end)
end

if player.Character then
	bindMovingDetection(player.Character)
end

player.CharacterAdded:Connect(bindMovingDetection)

for areaId, areaConfig in pairs(AutoAreaTheta) do
	if type(areaId) == "string" and type(areaConfig) == "table" then
		bindAutoArea(areaId)
	end
end

for eggId, eggConfig in pairs(EggTheta) do
	if type(eggId) == "string" and type(eggConfig) == "table" then
		bindEggPrompt(eggId)
	end
end

refreshUiFromServer()

while task.wait(5) do
	refreshUiFromServer()
end
