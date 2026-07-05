local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local theta = ReplicatedStorage:WaitForChild("theta")

local AutoAreaTheta = require(theta:WaitForChild("AutoAreaTheta"))
local EggSceneTheta = require(theta:WaitForChild("EggTheta"):WaitForChild("EggSceneTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))
local RemoteTheta = require(theta:WaitForChild("RemoteTheta"))
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local BarbellDisplayController = require(script.Parent.Parent.T.BarbellDisplay.Controller)
local EggPanelController = require(script.Parent.Parent.T.EggPanel.Controller)
local FloatingGainController = require(script.Parent.Parent.T.FloatingGain.Controller)
local HUDController = require(script.Parent.Parent.T.HUD.Controller)
local PetInventoryController = require(script.Parent.Parent.T.PetInventory.Controller)
local PlayerVisualSync = require(script.Parent.Parent.T.PlayerVisualSync)
local RebirthPanelController = require(script.Parent.Parent.T.RebirthPanel.Controller)

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

local hudView = HUDController.Init(player)
local floatingGainView = FloatingGainController.Init(player)
local petInventoryView = PetInventoryController.Init(player)
local rebirthPanelView = RebirthPanelController.Init(player)
local eggPanelView = EggPanelController.Init(player)
local barbellDisplayView = BarbellDisplayController.Init()

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
	floatingGainView.PlayStrengthGain(player:GetAttribute(SceneTheta.Attributes.LastTrainingStrengthGain))
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

local function refreshUi(data)
	latestData = data
	hudView.Refresh(data)
	floatingGainView.Refresh(data)
	petInventoryView.Refresh(data)
	rebirthPanelView.Refresh(data)
	eggPanelView.Refresh(data)
	barbellDisplayView.Refresh(data)
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
	local eggSceneConfig = EggSceneTheta[eggId]
	if type(eggSceneConfig) ~= "table" then
		return nil
	end

	local sceneEgg = getSceneChild(eggSceneConfig.SceneRootName or SceneTheta.SceneEggRootName)
	local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
	local promptPartName = eggSceneConfig.PromptPartName or SceneTheta.EggPromptPartName
	local eggHolder = sceneEgg and sceneEgg:FindFirstChild(sceneNodeName)
	return eggHolder and (eggHolder:FindFirstChild(promptPartName) or eggHolder)
end

local function isPlayerNearEgg(eggId)
	local eggSceneConfig = EggSceneTheta[eggId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local interactionPosition = getInstancePosition(getEggInteractionNode(eggId))
	if not eggSceneConfig or not root or not interactionPosition then
		return false
	end

	local interactionDistance = tonumber(eggSceneConfig.InteractionDistance) or SceneTheta.EggInteractionDistance
	return (root.Position - interactionPosition).Magnitude <= interactionDistance + 2
end

local function bindEggPrompt(eggId)
	local eggSceneConfig = EggSceneTheta[eggId]
	if type(eggSceneConfig) ~= "table" then
		warn("Missing egg scene config: " .. tostring(eggId))
		return
	end

	local sceneEgg = getSceneChild(eggSceneConfig.SceneRootName or SceneTheta.SceneEggRootName)
	local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
	local eggHolder = sceneEgg and sceneEgg:WaitForChild(sceneNodeName, 10)
	if not eggHolder then
		warn("Missing egg holder: " .. tostring(sceneNodeName))
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

for eggId, eggSceneConfig in pairs(EggSceneTheta) do
	if type(eggId) == "string" and type(eggSceneConfig) == "table" then
		bindEggPrompt(eggId)
	end
end

refreshUiFromServer()

while task.wait(5) do
	refreshUiFromServer()
end
