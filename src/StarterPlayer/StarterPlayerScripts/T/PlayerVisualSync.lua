local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local theta = ReplicatedStorage:WaitForChild("theta")
local AnimationTheta = require(theta:WaitForChild("System"):WaitForChild("AnimationTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))
local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local PlayerVisualSync = {}

local ATTRIBUTES = SceneTheta.Attributes
local VISUAL_BARBELL_NAME = "MG_ClientBarbell"
local VISUAL_PET_FOLDER_NAME = "MG_ClientPets"

-- 杠铃跟随右手；左手是否握住另一端由训练动画里的手部姿势决定。
-- Position 是相对右手的位置：主要调 X 把杠铃中心推到两手之间，再调 Y/Z 贴合手掌。
-- Rotation 是相对右手的旋转角度；如果杠铃没横过来，优先试 Z=90/-90，再试 Y=90/-90。
local BARBELL_GRIP_POSITION = Vector3.new(-1.5, -0.05, -0.25)
local BARBELL_GRIP_ROTATION_DEGREES = Vector3.new(90, 0, 0)

local playerStates = {}
local renderConnection = nil

local function getBarbellSource(barbellId)
	local trainEquipment = InstancePath.FindSpec(
		{ ReplicatedStorage = ReplicatedStorage },
		SceneTheta.ClientTrainEquipmentPathSpec
	)
	local barbellNode = trainEquipment and trainEquipment:FindFirstChild(tostring(barbellId))
	return barbellNode and barbellNode:FindFirstChild(SceneTheta.BarbellTrainModelName)
end

local function getPetSource(modelName)
	local petRoot = InstancePath.FindSpec(
		{ ReplicatedStorage = ReplicatedStorage },
		SceneTheta.ClientPetSourcePathSpec
	)
	return petRoot and petRoot:FindFirstChild(tostring(modelName))
end

local function getBaseParts(instance)
	local parts = {}
	if not instance then
		return parts
	end

	if instance:IsA("BasePart") then
		table.insert(parts, instance)
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	return parts
end

local function getPivot(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)
	return firstPart and firstPart.CFrame or nil
end

local function pivotTo(instance, cframe)
	if not instance or not cframe then
		return
	end

	if instance:IsA("Model") then
		instance:PivotTo(cframe)
	elseif instance:IsA("BasePart") then
		instance.CFrame = cframe
	else
		local currentPivot = getPivot(instance)
		if currentPivot then
			local delta = cframe * currentPivot:Inverse()
			for _, part in ipairs(getBaseParts(instance)) do
				part.CFrame = delta * part.CFrame
			end
		end
	end
end

local function prepareAnchoredVisual(instance)
	for _, part in ipairs(getBaseParts(instance)) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
	end
end

local function prepareWeldedVisual(instance)
	for _, part in ipairs(getBaseParts(instance)) do
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
	end
end

local function getBarbellGripHand(character)
	return character and (
		character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("HumanoidRootPart")
	)
end

local function getBarbellGripCFrame(hand)
	local rotation = BARBELL_GRIP_ROTATION_DEGREES
	return hand.CFrame
		* CFrame.new(BARBELL_GRIP_POSITION)
		* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
end

local function clearBarbell(character)
	local existing = character and character:FindFirstChild(VISUAL_BARBELL_NAME)
	if existing then
		existing:Destroy()
	end
end

local function weldToHand(instance, hand)
	for _, part in ipairs(getBaseParts(instance)) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
	end
end

local function refreshBarbell(player)
	local character = player.Character
	if not character then
		return
	end

	clearBarbell(character)

	if player:GetAttribute(ATTRIBUTES.IsPushingBall) == true then
		return
	end

	local barbellId = player:GetAttribute(ATTRIBUTES.CurrentBarbellId)
	if type(barbellId) ~= "string" or barbellId == "" then
		return
	end

	local source = getBarbellSource(barbellId)
	local hand = getBarbellGripHand(character)
	if not source or not hand then
		return
	end

	local visual = source:Clone()
	visual.Name = VISUAL_BARBELL_NAME
	visual.Parent = character
	prepareWeldedVisual(visual)
	-- 不要同时焊左右手：单个刚体双手焊接会和手部动画互相拉扯。
	pivotTo(visual, getBarbellGripCFrame(hand))
	weldToHand(visual, hand)
end

local function decodePets(jsonText)
	if type(jsonText) ~= "string" or jsonText == "" then
		return {}
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(jsonText)
	end)

	return success and type(result) == "table" and result or {}
end

local function clearPets(state)
	if state.petFolder then
		state.petFolder:Destroy()
	end

	state.petFolder = nil
	state.petModels = {}
end

local function ensurePetFolder(character)
	local folder = character:FindFirstChild(VISUAL_PET_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = VISUAL_PET_FOLDER_NAME
		folder.Parent = character
	end

	return folder
end

local function refreshPets(player)
	local state = playerStates[player]
	local character = player.Character
	if not state or not character then
		return
	end

	clearPets(state)

	local pets = decodePets(player:GetAttribute(ATTRIBUTES.EquippedPetsJson))
	if #pets == 0 then
		return
	end

	local folder = ensurePetFolder(character)
	state.petFolder = folder

	for index, petInfo in ipairs(pets) do
		local source = type(petInfo) == "table" and getPetSource(petInfo.ModelName)
		if source then
			local visual = source:Clone()
			visual.Name = "Pet_" .. tostring(petInfo.InstanceId or index)
			visual.Parent = folder
			prepareAnchoredVisual(visual)
			table.insert(state.petModels, {
				Model = visual,
				SlotIndex = tonumber(petInfo.SlotIndex) or index,
			})
		end
	end
end

local function getAnimator(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

local function stopTrainingTrack(state)
	if state.trainingTrack then
		state.trainingTrack:Stop(AnimationTheta.Training.FadeTime or 0.15)
		state.trainingTrack:Destroy()
		state.trainingTrack = nil
	end
end

local function refreshTrainingAnimation(player)
	local state = playerStates[player]
	if not state then
		return
	end

	if player:GetAttribute(ATTRIBUTES.IsTraining) ~= true then
		stopTrainingTrack(state)
		return
	end

	if state.trainingTrack and state.trainingTrack.IsPlaying then
		return
	end

	local animator = getAnimator(player.Character)
	if not animator then
		return
	end

	stopTrainingTrack(state)

	local animation = Instance.new("Animation")
	animation.AnimationId = AnimationTheta.Training.AnimationId
	local track = animator:LoadAnimation(animation)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(AnimationTheta.Training.FadeTime or 0.15)
	state.trainingTrack = track
end

local function stopPushBallTrack(state)
	if state.pushBallTrack then
		local pushBallConfig = AnimationTheta.PushBall or {}
		state.pushBallTrack:Stop(pushBallConfig.FadeTime or 0.15)
		state.pushBallTrack:Destroy()
		state.pushBallTrack = nil
	end
end

local function refreshPushBallAnimation(player)
	local state = playerStates[player]
	if not state then
		return
	end

	local pushBallConfig = AnimationTheta.PushBall or {}
	if player:GetAttribute(ATTRIBUTES.IsPushingBall) ~= true or type(pushBallConfig.AnimationId) ~= "string" or pushBallConfig.AnimationId == "" then
		stopPushBallTrack(state)
		return
	end

	if state.pushBallTrack and state.pushBallTrack.IsPlaying then
		return
	end

	local animator = getAnimator(player.Character)
	if not animator then
		return
	end

	stopPushBallTrack(state)

	local animation = Instance.new("Animation")
	animation.AnimationId = pushBallConfig.AnimationId
	local track = animator:LoadAnimation(animation)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(pushBallConfig.FadeTime or 0.15)
	state.pushBallTrack = track
end

local function refreshAll(player)
	refreshBarbell(player)
	refreshPets(player)
	refreshTrainingAnimation(player)
	refreshPushBallAnimation(player)
end

local function disconnectConnection(connection)
	local ok = true

	if typeof(connection) == "RBXScriptConnection" then
		ok = pcall(function()
			connection:Disconnect()
		end)
	elseif type(connection) == "table" and type(connection.Disconnect) == "function" then
		ok = pcall(function()
			connection:Disconnect()
		end)
	end

	if not ok then
		warn("Failed to disconnect player visual sync connection.")
	end
end

local function updatePetFollow()
	local now = os.clock()

	for player, state in pairs(playerStates) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			for _, petVisual in ipairs(state.petModels or {}) do
				local slotIndex = petVisual.SlotIndex or 1
				local angle = now * 1.4 + slotIndex * math.pi * 2 / 3
				local offset = Vector3.new(math.cos(angle) * 4, 2.2, math.sin(angle) * 4 + 3)
				local targetPosition = root.Position + root.CFrame:VectorToWorldSpace(offset)
				local targetCFrame = CFrame.new(targetPosition, root.Position)
				pivotTo(petVisual.Model, targetCFrame)
			end
		end
	end
end

local function bindPlayer(player)
	if playerStates[player] then
		return
	end

	local state = {
		connections = {},
		petModels = {},
		petFolder = nil,
		trainingTrack = nil,
		pushBallTrack = nil,
	}
	playerStates[player] = state

	table.insert(state.connections, player:GetAttributeChangedSignal(ATTRIBUTES.CurrentBarbellId):Connect(function()
		refreshBarbell(player)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal(ATTRIBUTES.EquippedPetsJson):Connect(function()
		refreshPets(player)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal(ATTRIBUTES.IsTraining):Connect(function()
		refreshTrainingAnimation(player)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal(ATTRIBUTES.IsPushingBall):Connect(function()
		refreshBarbell(player)
		refreshPushBallAnimation(player)
	end))
	table.insert(state.connections, player.CharacterAdded:Connect(function()
		stopTrainingTrack(state)
		stopPushBallTrack(state)
		task.defer(function()
			refreshAll(player)
		end)
	end))

	refreshAll(player)
end

local function unbindPlayer(player)
	local state = playerStates[player]
	if not state then
		return
	end

	for _, connection in ipairs(state.connections or {}) do
		disconnectConnection(connection)
	end

	stopTrainingTrack(state)
	stopPushBallTrack(state)
	clearPets(state)
	if player.Character then
		clearBarbell(player.Character)
	end

	playerStates[player] = nil
end

function PlayerVisualSync.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(unbindPlayer)

	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(updatePetFollow)
	end
end

return PlayerVisualSync
