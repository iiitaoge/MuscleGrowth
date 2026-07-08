local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)
local TrainingTransition = require(script.Parent.TrainingTransition)

local PushBallTransition = {}

local BALL_FOLDER_NAME = "MG_PushBalls"
local DEFAULT_FORWARD = Vector3.new(0, 0, -1)
local DEFAULT_LATERAL = Vector3.new(1, 0, 0)
local PATH_WAIT_SECONDS = 5

local activeStates = {}
local runtimeStates = {}
local heartbeatConnection = nil

local function result(success, message, stageId)
	return {
		Success = success == true,
		Message = message,
		StageId = stageId,
	}
end

local function normalizeVector(value, fallback)
	if typeof(value) ~= "Vector3" or value.Magnitude <= 0 then
		return fallback
	end

	return value.Unit
end

local function getForwardDirection()
	return normalizeVector(PushBallSceneTheta.ForwardDirection, DEFAULT_FORWARD)
end

local function getLateralDirection(forward)
	local lateral = normalizeVector(PushBallSceneTheta.LateralDirection, DEFAULT_LATERAL)
	local projected = lateral - forward * lateral:Dot(forward)

	if projected.Magnitude <= 0 then
		local fallback = DEFAULT_LATERAL - forward * DEFAULT_LATERAL:Dot(forward)
		if fallback.Magnitude <= 0 then
			local fallbackSource = Vector3.new(0, 0, 1)
			fallback = fallbackSource - forward * fallbackSource:Dot(forward)
		end

		return fallback.Magnitude > 0 and fallback.Unit or DEFAULT_LATERAL
	end

	return projected.Unit
end

local function findPath(root, path)
	if not root or type(path) ~= "table" then
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current and current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

local function waitForPath(root, path)
	if not root or type(path) ~= "table" then
		return nil
	end

	local current = root
	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current:WaitForChild(childName, PATH_WAIT_SECONDS)
		if not current then
			return nil
		end
	end

	return current
end

local function getFirstBasePart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
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

	local firstPart = getFirstBasePart(instance)
	return firstPart and firstPart.CFrame or nil
end

local function pivotTo(instance, cframe)
	if not instance or not cframe then
		return false
	end

	if instance:IsA("Model") then
		instance:PivotTo(cframe)
		return true
	end

	if instance:IsA("BasePart") then
		instance.CFrame = cframe
		return true
	end

	return false
end

local function getCharacterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not character or not humanoid or not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end

	return character, humanoid, root
end

local function getBallFolder()
	local folder = Workspace:FindFirstChild(BALL_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = BALL_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
end

local function prepareBallClone(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BaseScript") or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
	end
end

local function isPlayerNearSourceBall(root, sourceBall)
	local sourcePivot = getPivot(sourceBall)
	if not sourcePivot then
		return false
	end

	local maxDistance = math.max(0, tonumber(PushBallTheta.InteractionDistance) or 14)
	return (root.Position - sourcePivot.Position).Magnitude <= maxDistance
end

local function normalizeCompletedStage(value)
	return math.max(0, math.floor(tonumber(value) or 0))
end

local function getRuntimeState(player)
	local state = runtimeStates[player]
	if not state then
		state = {
			CompletedStage = 0,
		}
		runtimeStates[player] = state
	end

	return state
end

local function getNextStageId(player)
	local firstStageId = math.max(1, math.floor(tonumber(PushBallTheta.FirstStageId) or 1))
	local lastStageId = math.max(firstStageId, math.floor(tonumber(PushBallTheta.LastStageId) or firstStageId))
	local completedStage = normalizeCompletedStage(getRuntimeState(player).CompletedStage)
	local nextStageId = math.max(firstStageId, completedStage + 1)

	if nextStageId > lastStageId then
		return nil
	end

	return nextStageId
end

local function getStageConfig(stageId)
	local sceneConfig = type(PushBallSceneTheta.Stages) == "table" and PushBallSceneTheta.Stages[stageId] or nil
	local gameplayConfig = type(StageTheta.Stages) == "table" and StageTheta.Stages[stageId] or nil

	if type(sceneConfig) ~= "table" or type(gameplayConfig) ~= "table" then
		return nil, nil
	end

	return sceneConfig, gameplayConfig
end

local function setCharacterPushLocked(state, locked)
	local humanoid = state.Humanoid
	local root = state.RootPart

	if humanoid then
		if locked then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		else
			humanoid.WalkSpeed = state.OriginalWalkSpeed or humanoid.WalkSpeed
			humanoid.JumpPower = state.OriginalJumpPower or humanoid.JumpPower
			humanoid.AutoRotate = state.OriginalAutoRotate == true
		end
	end

	if root then
		root.Anchored = locked and true or state.OriginalRootAnchored == true
	end
end

local function teleportPlayerToPath(player, path, label)
	if type(path) ~= "table" then
		warn("Missing push ball teleport path: " .. tostring(label))
		return false
	end

	local destination = waitForPath(Workspace, path)
	if not destination or not destination:IsA("BasePart") then
		warn("Invalid push ball teleport path: " .. tostring(label))
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local offsetY = tonumber(PushBallTheta.TeleportOffsetY) or 5
	character:PivotTo(destination.CFrame + Vector3.new(0, offsetY, 0))
	return true
end

local function stopHeartbeatIfIdle()
	if next(activeStates) ~= nil or not heartbeatConnection then
		return
	end

	heartbeatConnection:Disconnect()
	heartbeatConnection = nil
end

local function cleanupState(player, options)
	local state = activeStates[player]
	if not state then
		return
	end

	activeStates[player] = nil

	setCharacterPushLocked(state, false)
	PlayerVisualStateSync.SetPushBallActive(player, false)

	if state.Ball then
		state.Ball:Destroy()
	end

	if type(options) == "table" and options.TeleportStageId then
		local sceneConfig = type(PushBallSceneTheta.Stages) == "table" and PushBallSceneTheta.Stages[options.TeleportStageId] or nil
		teleportPlayerToPath(player, sceneConfig and sceneConfig.TeleportPath, "Stage " .. tostring(options.TeleportStageId))
	end

	stopHeartbeatIfIdle()
end

local function applyStageReward(player, stageId, gameplayConfig)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.Trophies = math.max(0, (tonumber(nextProgressState.Trophies) or 0) + (tonumber(gameplayConfig.RewardTrophies) or 0))
	PlayerProgressState.Set(player, nextProgressState)

	return true
end

local function markStageCompleted(player, stageId)
	local runtimeState = getRuntimeState(player)
	runtimeState.CompletedStage = math.max(normalizeCompletedStage(runtimeState.CompletedStage), stageId)
end

local function handleStageReached(player, state)
	local stageId = state.StageId
	local _, gameplayConfig = getStageConfig(stageId)
	if not gameplayConfig then
		cleanupState(player)
		return
	end

	local progressState = PlayerProgressState.Get(player)
	local strength = tonumber(progressState and progressState.Strength) or 0
	local requiredStrength = tonumber(gameplayConfig.RecommendedStrength) or math.huge

	if strength >= requiredStrength then
		applyStageReward(player, stageId, gameplayConfig)
		markStageCompleted(player, stageId)
		cleanupState(player, {
			TeleportStageId = stageId,
		})
	else
		cleanupState(player, {
			TeleportStageId = stageId - 1,
		})
	end
end

local function isBallTouchingWall(state)
	local sceneConfig = type(PushBallSceneTheta.Stages) == "table" and PushBallSceneTheta.Stages[state.StageId] or nil
	local wall = sceneConfig and findPath(Workspace, sceneConfig.WallPath)
	local wallPart = getFirstBasePart(wall)
	if not wallPart or not state.BallPosition then
		return false
	end

	local relative = wallPart.CFrame:PointToObjectSpace(state.BallPosition)
	local radius = math.max(0, tonumber(PushBallTheta.BallRadius) or 0)
	local halfSize = wallPart.Size * 0.5 + Vector3.new(radius, radius, radius)

	return math.abs(relative.X) <= halfSize.X
		and math.abs(relative.Y) <= halfSize.Y
		and math.abs(relative.Z) <= halfSize.Z
end

local function updateState(player, state, dt)
	local character, humanoid, root = getCharacterParts(player)
	if character ~= state.Character or humanoid ~= state.Humanoid or root ~= state.RootPart then
		cleanupState(player)
		return
	end

	local pushSpeed = math.max(0, tonumber(PushBallTheta.PushSpeed) or 0)
	local lateralSpeed = math.max(0, tonumber(PushBallTheta.LateralSpeed) or 0)
	local laneHalfWidth = math.max(0, tonumber(PushBallTheta.LaneHalfWidth) or 0)
	local ballRadius = math.max(0.1, tonumber(PushBallTheta.BallRadius) or 3)

	state.Progress += pushSpeed * dt
	state.LateralOffset = math.clamp(state.LateralOffset + state.LateralInput * lateralSpeed * dt, -laneHalfWidth, laneHalfWidth)

	local ballPosition = state.OriginPosition
		+ state.Forward * state.Progress
		+ state.Lateral * state.LateralOffset
	state.BallPosition = ballPosition

	local rollAngle = -state.Progress / ballRadius
	local ballCFrame = CFrame.new(ballPosition) * CFrame.fromAxisAngle(state.Lateral, rollAngle) * state.BallBaseRotation
	pivotTo(state.Ball, ballCFrame)

	local playerPosition = ballPosition
		- state.Forward * (tonumber(PushBallTheta.PlayerBehindBallDistance) or 5)
		+ Vector3.new(0, state.PlayerBallYOffset, 0)
	character:PivotTo(CFrame.lookAt(playerPosition, playerPosition + state.Forward))

	if isBallTouchingWall(state) then
		handleStageReached(player, state)
	end
end

local function updateAll(dt)
	for player, state in pairs(activeStates) do
		updateState(player, state, dt)
	end
end

local function ensureHeartbeat()
	if heartbeatConnection then
		return
	end

	heartbeatConnection = RunService.Heartbeat:Connect(updateAll)
end

local function createState(player, stageId, sourceBall, root, humanoid, character)
	local sourcePivot = getPivot(sourceBall)
	if not sourcePivot then
		return nil
	end

	local forward = getForwardDirection()
	local lateral = getLateralDirection(forward)
	local ballClone = sourceBall:Clone()
	ballClone.Name = "PushBall_" .. tostring(player.UserId)
	prepareBallClone(ballClone)
	ballClone.Parent = getBallFolder()

	local ballBaseRotation = sourcePivot - sourcePivot.Position
	local originPosition = sourcePivot.Position

	return {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		RootPart = root,
		Ball = ballClone,
		BallBaseRotation = ballBaseRotation,
		BallPosition = originPosition,
		OriginPosition = originPosition,
		Forward = forward,
		Lateral = lateral,
		StageId = stageId,
		Progress = 0,
		LateralOffset = 0,
		LateralInput = 0,
		PlayerBallYOffset = root.Position.Y - originPosition.Y,
		OriginalWalkSpeed = humanoid.WalkSpeed,
		OriginalJumpPower = humanoid.JumpPower,
		OriginalAutoRotate = humanoid.AutoRotate,
		OriginalRootAnchored = root.Anchored,
	}
end

function PushBallTransition.RequestStart(player)
	if activeStates[player] then
		return result(false, "Already pushing ball", activeStates[player].StageId)
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return result(false, "Missing player progress")
	end

	local stageId = getNextStageId(player)
	if not stageId then
		return result(false, "All push ball stages completed")
	end

	local sceneConfig = getStageConfig(stageId)
	if not sceneConfig then
		return result(false, "Missing push ball stage config", stageId)
	end

	local character, humanoid, root = getCharacterParts(player)
	if not character then
		return result(false, "Missing player character", stageId)
	end

	local sourceBall = waitForPath(Workspace, PushBallSceneTheta.BallPath)
	if not sourceBall then
		return result(false, "Missing push ball source", stageId)
	end

	if not isPlayerNearSourceBall(root, sourceBall) then
		return result(false, "Too far from push ball", stageId)
	end

	local state = createState(player, stageId, sourceBall, root, humanoid, character)
	if not state then
		return result(false, "Invalid push ball source", stageId)
	end

	activeStates[player] = state
	setCharacterPushLocked(state, true)
	TrainingTransition.SetMoving(player, false)
	PlayerVisualStateSync.SetPushBallActive(player, true)
	ensureHeartbeat()

	return result(true, "Push ball started", stageId)
end

function PushBallTransition.SetLateralInput(player, lateralInput)
	local state = activeStates[player]
	if not state then
		return false
	end

	local input = tonumber(lateralInput) or 0
	if input > 0 then
		state.LateralInput = 1
	elseif input < 0 then
		state.LateralInput = -1
	else
		state.LateralInput = 0
	end

	return true
end

function PushBallTransition.RequestStop(player)
	local stageId = activeStates[player] and activeStates[player].StageId or nil
	cleanupState(player)
	return result(true, "Push ball stopped", stageId)
end

function PushBallTransition.RemovePlayer(player)
	cleanupState(player)
	runtimeStates[player] = nil
end

return PushBallTransition
