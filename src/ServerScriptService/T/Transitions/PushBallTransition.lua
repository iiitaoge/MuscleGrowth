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
local TravelTransition = require(script.Parent.TravelTransition)

local PushBallTransition = {}

local BALL_FOLDER_NAME = "MG_PushBalls"
local DEFAULT_FORWARD = Vector3.new(0, 0, -1)
local DEFAULT_LATERAL = Vector3.new(1, 0, 0)
local PATH_WAIT_SECONDS = 5
local UP_VECTOR = Vector3.new(0, 1, 0)

local activeStates = {}
local runtimeStates = {}
local heartbeatConnection = nil

local function debugLog(message)
	if PushBallTheta.DebugPushBall == true then
		print("[PushBallTransition] " .. message)
	end
end

local function pathToString(path)
	return type(path) == "table" and table.concat(path, "/") or tostring(path)
end

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

local function getHorizontalDirection(value, fallback)
	if typeof(value) ~= "Vector3" then
		return fallback
	end

	local horizontal = Vector3.new(value.X, 0, value.Z)
	if horizontal.Magnitude <= 0 then
		return fallback
	end

	return horizontal.Unit
end

local function getStageForward(sourcePivot, wallPivot)
	local fallback = getHorizontalDirection(getForwardDirection(), DEFAULT_FORWARD)
	if not sourcePivot or not wallPivot then
		return fallback
	end

	return getHorizontalDirection(wallPivot.Position - sourcePivot.Position, fallback)
end

local function getStageLateral(forward)
	local lateral = forward:Cross(UP_VECTOR)
	if lateral.Magnitude > 0 then
		return lateral.Unit
	end

	return getLateralDirection(forward)
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

local function buildTrackRaycastParams(trackRoot)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { trackRoot }
	params.IgnoreWater = true
	return params
end

local function raycastTrackPosition(raycastParams, targetPosition)
	if not raycastParams or typeof(targetPosition) ~= "Vector3" then
		return nil
	end

	local height = math.max(0, tonumber(PushBallTheta.TrackRaycastHeight) or 80)
	local depth = math.max(0, tonumber(PushBallTheta.TrackRaycastDepth) or 160)
	local origin = targetPosition + UP_VECTOR * height
	local direction = UP_VECTOR * -(height + depth)
	local raycastResult = Workspace:Raycast(origin, direction, raycastParams)

	return raycastResult and raycastResult.Position or nil
end

local function warnRaycastMiss(state, label, targetPosition)
	local now = os.clock()
	if state.LastRaycastWarnTime and now - state.LastRaycastWarnTime < 1 then
		return
	end

	state.LastRaycastWarnTime = now
	warn(
		("Push ball track raycast missed for %s stage %s at %s. Check TrackPath and CanQuery."):format(
			label,
			tostring(state.StageId),
			tostring(targetPosition)
		)
	)
end

local function getGroundedPosition(state, targetPosition, offsetY, label, fallbackPosition)
	local groundPosition = raycastTrackPosition(state.TrackRaycastParams, targetPosition)
	if groundPosition then
		return groundPosition + UP_VECTOR * offsetY
	end

	warnRaycastMiss(state, label, targetPosition)
	return fallbackPosition
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
			ClaimableStageRewards = {},
		}
		runtimeStates[player] = state
	end

	if type(state.ClaimableStageRewards) ~= "table" then
		state.ClaimableStageRewards = {}
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

local function getBallConfig(ballInstanceId)
	if type(ballInstanceId) ~= "string" or ballInstanceId == "" then
		return nil
	end

	local balls = PushBallSceneTheta.Balls
	return type(balls) == "table" and balls[ballInstanceId] or nil
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
		if sceneConfig then
			teleportPlayerToPath(player, sceneConfig.TeleportPath, "Stage " .. tostring(options.TeleportStageId))
		end
	end

	if type(options) == "table" and type(options.TravelDestinationId) == "string" then
		local travelResult = TravelTransition.Request(player, options.TravelDestinationId)
		if travelResult.Success == false and travelResult.Message then
			warn(travelResult.Message)
		end
	end

	stopHeartbeatIfIdle()
end

local function markStageCompleted(player, stageId)
	local runtimeState = getRuntimeState(player)
	runtimeState.CompletedStage = math.max(normalizeCompletedStage(runtimeState.CompletedStage), stageId)
end

local function markStageRewardClaimable(player, stageId)
	local runtimeState = getRuntimeState(player)
	runtimeState.ClaimableStageRewards[stageId] = true
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
		markStageCompleted(player, stageId)
		markStageRewardClaimable(player, stageId)
		cleanupState(player, {
			TeleportStageId = stageId,
		})
	else
		if stageId <= 1 then
			cleanupState(player, {
				TravelDestinationId = "World2",
			})
		else
			cleanupState(player, {
				TeleportStageId = stageId - 1,
			})
		end
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
	local ballGroundOffsetY = tonumber(PushBallTheta.BallGroundOffsetY) or 0

	state.Progress += pushSpeed * dt
	state.LateralOffset = math.clamp(state.LateralOffset + state.LateralInput * lateralSpeed * dt, -laneHalfWidth, laneHalfWidth)

	local targetBallPosition = state.OriginPosition
		+ state.Forward * state.Progress
		+ state.Lateral * state.LateralOffset
	local ballPosition = getGroundedPosition(
		state,
		targetBallPosition,
		ballRadius + ballGroundOffsetY,
		"ball",
		state.BallPosition
	)
	state.BallPosition = ballPosition

	local rollAngle = -state.Progress / ballRadius
	local ballCFrame = CFrame.new(ballPosition) * CFrame.fromAxisAngle(state.Lateral, rollAngle) * state.BallBaseRotation
	pivotTo(state.Ball, ballCFrame)

	local playerForwardOffset = tonumber(PushBallTheta.PlayerForwardOffset) or 0
	local playerLateralOffset = tonumber(PushBallTheta.PlayerLateralOffset) or 0
	local targetPlayerPosition = targetBallPosition
		- state.Forward * (tonumber(PushBallTheta.PlayerBehindBallDistance) or 5)
		+ state.Forward * playerForwardOffset
		+ state.Lateral * playerLateralOffset
	local playerPosition = getGroundedPosition(
		state,
		targetPlayerPosition,
		state.PlayerGroundOffsetY,
		"player",
		state.PlayerPosition or (ballPosition - state.Forward * (tonumber(PushBallTheta.PlayerBehindBallDistance) or 5))
	)
	state.PlayerPosition = playerPosition
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

local function createState(player, stageId, ballInstanceId, sourceBall, trackRoot, wall, root, humanoid, character)
	local sourcePivot = getPivot(sourceBall)
	if not sourcePivot then
		return nil
	end

	local wallPivot = getPivot(wall)
	if not wallPivot then
		return nil
	end

	local trackRaycastParams = buildTrackRaycastParams(trackRoot)
	local forward = getStageForward(sourcePivot, wallPivot)
	local lateral = getStageLateral(forward)
	local ballClone = sourceBall:Clone()
	ballClone.Name = "PushBall_" .. tostring(player.UserId) .. "_" .. ballInstanceId
	prepareBallClone(ballClone)
	ballClone.Parent = getBallFolder()

	local ballBaseRotation = sourcePivot - sourcePivot.Position
	local originPosition = sourcePivot.Position
	local ballRadius = math.max(0.1, tonumber(PushBallTheta.BallRadius) or 3)
	local ballGroundOffsetY = tonumber(PushBallTheta.BallGroundOffsetY) or 0
	local initialBallGround = raycastTrackPosition(trackRaycastParams, originPosition)
	local initialBallPosition = initialBallGround and initialBallGround + UP_VECTOR * (ballRadius + ballGroundOffsetY)
		or originPosition
	local configuredPlayerGroundOffsetY = tonumber(PushBallTheta.PlayerGroundOffsetY)
	local playerGround = raycastTrackPosition(trackRaycastParams, root.Position)
	local playerGroundOffsetY = configuredPlayerGroundOffsetY or (playerGround and root.Position.Y - playerGround.Y) or 3

	debugLog(
		("Stage %s ball=%s track=%s forward=%s lateral=%s"):format(
			tostring(stageId),
			tostring(ballInstanceId),
			trackRoot:GetFullName(),
			tostring(forward),
			tostring(lateral)
		)
	)

	return {
		Player = player,
		BallInstanceId = ballInstanceId,
		Character = character,
		Humanoid = humanoid,
		RootPart = root,
		Ball = ballClone,
		BallBaseRotation = ballBaseRotation,
		BallPosition = initialBallPosition,
		PlayerPosition = root.Position,
		OriginPosition = originPosition,
		Forward = forward,
		Lateral = lateral,
		TrackRoot = trackRoot,
		TrackRaycastParams = trackRaycastParams,
		StageId = stageId,
		Progress = 0,
		LateralOffset = 0,
		LateralInput = 0,
		PlayerGroundOffsetY = playerGroundOffsetY,
		OriginalWalkSpeed = humanoid.WalkSpeed,
		OriginalJumpPower = humanoid.JumpPower,
		OriginalAutoRotate = humanoid.AutoRotate,
		OriginalRootAnchored = root.Anchored,
	}
end

function PushBallTransition.RequestStart(player, ballInstanceId)
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

	local ballConfig = getBallConfig(ballInstanceId)
	if not ballConfig then
		return result(false, "Invalid push ball", stageId)
	end

	local ballStageId = math.floor(tonumber(ballConfig.StageId) or 0)
	if ballStageId ~= stageId then
		return result(false, "Push ball does not match current stage", stageId)
	end

	local sceneConfig = getStageConfig(stageId)
	if not sceneConfig then
		return result(false, "Missing push ball stage config", stageId)
	end

	local character, humanoid, root = getCharacterParts(player)
	if not character then
		return result(false, "Missing player character", stageId)
	end

	local sourceBall = waitForPath(Workspace, ballConfig.Path)
	if not sourceBall then
		return result(false, "Missing push ball source", stageId)
	end

	local trackRoot = waitForPath(Workspace, sceneConfig.TrackPath)
	if not trackRoot then
		return result(false, "Missing push ball track: " .. pathToString(sceneConfig.TrackPath), stageId)
	end

	local wall = waitForPath(Workspace, sceneConfig.WallPath)
	if not wall then
		return result(false, "Missing push ball wall: " .. pathToString(sceneConfig.WallPath), stageId)
	end

	if not isPlayerNearSourceBall(root, sourceBall) then
		return result(false, "Too far from push ball", stageId)
	end

	local state = createState(player, stageId, ballInstanceId, sourceBall, trackRoot, wall, root, humanoid, character)
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

function PushBallTransition.ConsumeClaimableStageReward(player, stageId)
	local normalizedStageId = math.floor(tonumber(stageId) or 0)
	if normalizedStageId <= 0 then
		return false
	end

	local runtimeState = runtimeStates[player]
	local claimableRewards = runtimeState and runtimeState.ClaimableStageRewards
	if type(claimableRewards) ~= "table" or claimableRewards[normalizedStageId] ~= true then
		return false
	end

	claimableRewards[normalizedStageId] = nil
	return true
end

function PushBallTransition.ResetRuntimeState(player)
	runtimeStates[player] = nil
end

function PushBallTransition.RemovePlayer(player)
	cleanupState(player)
	runtimeStates[player] = nil
end

return PushBallTransition
