local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)
local RemoteBinder = require(script.Parent.Parent.Parent.u.RemoteBinder)
local TransitionResult = require(script.Parent.TransitionResult)
local TrainingTransition = require(script.Parent.TrainingTransition)
local TravelTransition = require(script.Parent.TravelTransition)

local PushBallTransition = {}

local ATTRIBUTES = SceneTheta.Attributes
local BALL_FOLDER_NAME = "MG_PushBalls"
local DEFAULT_FORWARD = Vector3.new(0, 0, -1)
local DEFAULT_LATERAL = Vector3.new(1, 0, 0)
local PATH_WAIT_SECONDS = 5
local UP_VECTOR = Vector3.new(0, 1, 0)
local TELEPORT_OVERLAP_SIZE = Vector3.new(10, 12, 10)
local TELEPORT_RAYCAST_HEIGHT = 5
local TELEPORT_RAYCAST_DEPTH = 80
local MAX_DIAGNOSTIC_PARTS = 12

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
	return TransitionResult.New(success, message, {
		StageId = stageId,
	})
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

local function collectBaseParts(instance)
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

local function getTeleportRaycastHit(position, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local origin = position + UP_VECTOR * TELEPORT_RAYCAST_HEIGHT
	local direction = UP_VECTOR * -(TELEPORT_RAYCAST_HEIGHT + TELEPORT_RAYCAST_DEPTH)
	return Workspace:Raycast(origin, direction, params)
end

local function getTeleportOverlapParts(position, character)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), TELEPORT_OVERLAP_SIZE, params)
	local collidable = {}

	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and part.CanCollide then
			table.insert(collidable, part)
		end
	end

	return collidable
end

local function debugTeleportArea(player, label, path, destination, position)
	if PushBallTheta.DebugPushBall ~= true then
		return
	end

	local character = player and player.Character or nil
	local groundHit = getTeleportRaycastHit(position, character)
	local overlapParts = getTeleportOverlapParts(position, character)

	debugLog(
		("Teleport area %s player=%s path=%s position=%s destination=%s destinationSize=%s destinationTransparency=%s destinationCanCollide=%s destinationCanQuery=%s ground=%s groundPosition=%s groundMaterial=%s overlapCount=%s streamingEnabled=%s"):format(
			tostring(label),
			player and player.Name or "nil",
			pathToString(path),
			tostring(position),
			destination and destination:GetFullName() or "nil",
			destination and tostring(destination.Size) or "nil",
			destination and tostring(destination.Transparency) or "nil",
			destination and tostring(destination.CanCollide) or "nil",
			destination and tostring(destination.CanQuery) or "nil",
			groundHit and groundHit.Instance and groundHit.Instance:GetFullName() or "nil",
			groundHit and tostring(groundHit.Position) or "nil",
			groundHit and groundHit.Material.Name or "nil",
			tostring(#overlapParts),
			tostring(Workspace.StreamingEnabled)
		)
	)

	for index, part in ipairs(overlapParts) do
		if index > MAX_DIAGNOSTIC_PARTS then
			break
		end

		debugLog(
			("Teleport area overlap %s player=%s part=%s size=%s position=%s transparency=%s canQuery=%s collisionGroup=%s"):format(
				tostring(index),
				player and player.Name or "nil",
				part:GetFullName(),
				tostring(part.Size),
				tostring(part.Position),
				tostring(part.Transparency),
				tostring(part.CanQuery),
				tostring(part.CollisionGroup)
			)
		)
	end
end

local function requestTeleportStream(player, position, label)
	if not player or typeof(position) ~= "Vector3" then
		return false
	end

	if Workspace.StreamingEnabled ~= true then
		debugLog(("Teleport stream skipped player=%s label=%s reason=streaming disabled"):format(
			player.Name,
			tostring(label)
		))
		return true
	end

	local timeout = math.max(0, tonumber(PushBallTheta.TeleportStreamTimeout) or 0)
	debugLog(("Teleport stream request player=%s label=%s position=%s timeout=%s"):format(
		player.Name,
		tostring(label),
		tostring(position),
		tostring(timeout)
	))

	local success, err = pcall(function()
		if timeout > 0 then
			player:RequestStreamAroundAsync(position, timeout)
		else
			player:RequestStreamAroundAsync(position)
		end
	end)

	if not success then
		warn(("Push ball teleport stream request failed for %s (%s): %s"):format(
			player.Name,
			tostring(label),
			tostring(err)
		))
		return false
	end

	debugLog(("Teleport stream finished player=%s label=%s position=%s"):format(
		player.Name,
		tostring(label),
		tostring(position)
	))
	return true
end

local function debugClientTeleportResult(player, label, result)
	if PushBallTheta.DebugPushBall ~= true then
		return
	end

	debugLog(
		("Client teleport prepare result player=%s label=%s success=%s streamOk=%s destinationVisible=%s destination=%s ground=%s groundMaterial=%s overlapCount=%s error=%s"):format(
			player and player.Name or "nil",
			tostring(label),
			type(result) == "table" and tostring(result.Success) or "nil",
			type(result) == "table" and tostring(result.StreamOk) or "nil",
			type(result) == "table" and tostring(result.DestinationVisible) or "nil",
			type(result) == "table" and tostring(result.DestinationFullName) or "nil",
			type(result) == "table" and tostring(result.GroundHitName) or "nil",
			type(result) == "table" and tostring(result.GroundHitMaterial) or "nil",
			type(result) == "table" and tostring(result.OverlapCount) or "nil",
			type(result) == "table" and tostring(result.Error or result.StreamError) or tostring(result)
		)
	)

	if type(result) ~= "table" or type(result.OverlapParts) ~= "table" then
		return
	end

	for index, partInfo in ipairs(result.OverlapParts) do
		if index > MAX_DIAGNOSTIC_PARTS then
			break
		end

		debugLog(
			("Client teleport overlap %s player=%s part=%s size=%s position=%s transparency=%s collisionGroup=%s"):format(
				tostring(index),
				player and player.Name or "nil",
				tostring(partInfo.Name),
				tostring(partInfo.Size),
				tostring(partInfo.Position),
				tostring(partInfo.Transparency),
				tostring(partInfo.CollisionGroup)
			)
		)
	end
end

local function requestClientTeleportReadiness(player, path, position, label)
	if not player or typeof(position) ~= "Vector3" then
		return false, "invalid request"
	end

	local timeout = math.max(0.5, tonumber(PushBallTheta.TeleportClientPrepareTimeout) or 8)
	local remote = RemoteBinder.GetOrCreate("PushBallPrepareTeleport")
	local done = false
	local invokeOk = false
	local result = nil

	task.spawn(function()
		invokeOk, result = pcall(function()
			return remote:InvokeClient(player, {
				Label = label,
				Path = path,
				Position = position,
				StreamTimeout = math.max(0, tonumber(PushBallTheta.TeleportStreamTimeout) or 0),
				VerifyTimeout = math.max(0, tonumber(PushBallTheta.TeleportClientVerifyTimeout) or 0),
			})
		end)
		done = true
	end)

	local startedAt = os.clock()
	while not done and os.clock() - startedAt < timeout do
		task.wait(0.05)
	end

	if not done then
		warn(("Push ball client teleport prepare timed out for %s (%s) after %.2fs"):format(
			player.Name,
			tostring(label),
			timeout
		))
		return false, "timeout"
	end

	if not invokeOk then
		warn(("Push ball client teleport prepare failed for %s (%s): %s"):format(
			player.Name,
			tostring(label),
			tostring(result)
		))
		return false, result
	end

	debugClientTeleportResult(player, label, result)
	return type(result) == "table" and result.Success == true, result
end

local function teleportPlayerToPath(player, path, label)
	if type(path) ~= "table" then
		warn("Missing push ball teleport path: " .. tostring(label))
		return false
	end

	debugLog(("Teleport start player=%s label=%s path=%s"):format(
		player and player.Name or "nil",
		tostring(label),
		pathToString(path)
	))

	local destination = waitForPath(Workspace, path)
	if not destination or not destination:IsA("BasePart") then
		warn("Invalid push ball teleport path: " .. tostring(label))
		return false
	end

	local character = player.Character
	if not character then
		warn("Missing push ball teleport character: " .. tostring(label))
		return false
	end

	local offsetY = tonumber(PushBallTheta.TeleportOffsetY) or 5
	local teleportPosition = destination.Position + Vector3.new(0, offsetY, 0)
	debugTeleportArea(player, "before stream", path, destination, teleportPosition)
	if not requestTeleportStream(player, teleportPosition, label) then
		warn(("Push ball teleport cancelled because target area was not streamed: %s"):format(tostring(label)))
		return false
	end
	debugTeleportArea(player, "after server stream", path, destination, teleportPosition)

	local clientReady = requestClientTeleportReadiness(player, path, teleportPosition, label)
	if not clientReady then
		warn(("Push ball teleport cancelled because client target area was not ready: %s"):format(tostring(label)))
		return false
	end
	debugTeleportArea(player, "after client prepare", path, destination, teleportPosition)

	character:PivotTo(destination.CFrame + Vector3.new(0, offsetY, 0))
	debugLog(("Teleport done player=%s label=%s destination=%s offsetY=%s"):format(
		player.Name,
		tostring(label),
		destination:GetFullName(),
		tostring(offsetY)
	))

	local settleTime = math.max(0, tonumber(PushBallTheta.TeleportStreamSettleTime) or 0)
	if settleTime > 0 then
		task.wait(settleTime)
		debugLog(("Teleport settle done player=%s label=%s seconds=%s"):format(
			player.Name,
			tostring(label),
			tostring(settleTime)
		))
	end

	return true
end

local function clearCharacterVelocity(character)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function debugCharacterPhysics(state, label)
	if PushBallTheta.DebugPushBall ~= true then
		return
	end

	local humanoid = state and state.Humanoid
	local root = state and state.RootPart
	debugLog(("%s player=%s pos=%s velocity=%s angularVelocity=%s walkSpeed=%s jumpPower=%s autoRotate=%s rootAnchored=%s platformStand=%s sit=%s humanoidState=%s floor=%s"):format(
		tostring(label),
		state and state.Player and state.Player.Name or "nil",
		root and tostring(root.Position) or "nil",
		root and tostring(root.AssemblyLinearVelocity) or "nil",
		root and tostring(root.AssemblyAngularVelocity) or "nil",
		humanoid and tostring(humanoid.WalkSpeed) or "nil",
		humanoid and tostring(humanoid.JumpPower) or "nil",
		humanoid and tostring(humanoid.AutoRotate) or "nil",
		root and tostring(root.Anchored) or "nil",
		humanoid and tostring(humanoid.PlatformStand) or "nil",
		humanoid and tostring(humanoid.Sit) or "nil",
		humanoid and humanoid:GetState().Name or "nil",
		humanoid and humanoid.FloorMaterial.Name or "nil"
	))
end

local function prepareCharacterForPushExit(state)
	if not state then
		return
	end

	clearCharacterVelocity(state.Character)
	if state.Humanoid then
		state.Humanoid.PlatformStand = false
		state.Humanoid.Sit = false
	end
end

local function recoverHumanoidAfterPushExit(state)
	if not state then
		return
	end

	clearCharacterVelocity(state.Character)
	if state.Humanoid then
		state.Humanoid.PlatformStand = false
		state.Humanoid.Sit = false
		pcall(function()
			state.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
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
		debugLog(("Cleanup skipped player=%s reason=no active state"):format(player and player.Name or "nil"))
		return
	end

	debugLog(("Cleanup start player=%s stage=%s teleportStage=%s travelDestination=%s"):format(
		player.Name,
		tostring(state.StageId),
		type(options) == "table" and tostring(options.TeleportStageId) or "nil",
		type(options) == "table" and tostring(options.TravelDestinationId) or "nil"
	))

	activeStates[player] = nil

	if state.Ball then
		debugLog(("Destroy push ball clone player=%s ball=%s"):format(player.Name, state.Ball:GetFullName()))
		state.Ball:Destroy()
	end

	debugCharacterPhysics(state, "Cleanup before teleport while locked")
	if type(options) == "table" and options.TeleportStageId then
		local sceneConfig = type(PushBallSceneTheta.Stages) == "table" and PushBallSceneTheta.Stages[options.TeleportStageId] or nil
		if sceneConfig then
			local teleportOk = teleportPlayerToPath(player, sceneConfig.TeleportPath, "Stage " .. tostring(options.TeleportStageId))
			debugLog(("Cleanup teleport result player=%s stage=%s ok=%s"):format(
				player.Name,
				tostring(options.TeleportStageId),
				tostring(teleportOk)
			))
		else
			warn("Missing push ball cleanup scene config: " .. tostring(options.TeleportStageId))
		end
	end

	if type(options) == "table" and type(options.TravelDestinationId) == "string" then
		debugLog(("Cleanup travel start player=%s destination=%s"):format(player.Name, options.TravelDestinationId))
		local travelResult = TravelTransition.Request(player, options.TravelDestinationId)
		if travelResult.Success == false and travelResult.Message then
			warn(travelResult.Message)
		end
		debugLog(("Cleanup travel result player=%s success=%s message=%s"):format(
			player.Name,
			tostring(travelResult.Success),
			tostring(travelResult.Message)
		))
	end

	prepareCharacterForPushExit(state)
	debugCharacterPhysics(state, "Cleanup before unlock after teleport")
	setCharacterPushLocked(state, false)
	recoverHumanoidAfterPushExit(state)
	debugCharacterPhysics(state, "Cleanup after unlock recover")
	PlayerVisualStateSync.SetPushBallActive(player, false)
	debugLog(("Push attribute after cleanup player=%s isPushingBall=%s"):format(
		player.Name,
		tostring(player:GetAttribute(ATTRIBUTES.IsPushingBall))
	))

	stopHeartbeatIfIdle()
	debugLog(("Cleanup done player=%s heartbeatActive=%s"):format(player.Name, tostring(heartbeatConnection ~= nil)))
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
	print("撞墙的处理")
	local stageId = state.StageId
	local _, gameplayConfig = getStageConfig(stageId)
	if not gameplayConfig then
		debugLog(("Stage reached without gameplay config player=%s stage=%s"):format(player.Name, tostring(stageId)))
		cleanupState(player)
		return
	end

	local progressState = PlayerProgressState.Get(player)
	local strength = tonumber(progressState and progressState.Strength) or 0
	local requiredStrength = tonumber(gameplayConfig.RecommendedStrength) or math.huge
	debugLog(("Stage reached player=%s stage=%s strength=%s required=%s passes=%s"):format(
		player.Name,
		tostring(stageId),
		tostring(strength),
		tostring(requiredStrength),
		tostring(strength >= requiredStrength)
	))

	if strength >= requiredStrength then
		markStageCompleted(player, stageId)
		markStageRewardClaimable(player, stageId)
		debugLog(("Stage complete marked player=%s stage=%s"):format(player.Name, tostring(stageId)))
		cleanupState(player, {
			TeleportStageId = stageId,
		})
	else
		if stageId <= 1 then
			debugLog(("Stage failed travel player=%s stage=%s destination=World2"):format(player.Name, tostring(stageId)))
			cleanupState(player, {
				TravelDestinationId = "World2",
			})
		else
			debugLog(("Stage failed fallback player=%s stage=%s fallbackStage=%s"):format(
				player.Name,
				tostring(stageId),
				tostring(stageId - 1)
			))
			cleanupState(player, {
				TeleportStageId = stageId - 1,
			})
		end
	end
end

local function debugFinishWallCheck(state, logicalBallPosition, wallPartCount, matchedPart, relative, halfSize, isTouching, reason)
	if PushBallTheta.DebugPushBall ~= true then
		return
	end

	local now = os.clock()
	if not isTouching and state.LastFinishWallDebugTime and now - state.LastFinishWallDebugTime < 1 then
		return
	end

	state.LastFinishWallDebugTime = now
	debugLog(
		("Finish wall check stage=%s reason=%s wallPath=%s logicalBallPosition=%s wallPartCount=%s matchedPart=%s relative=%s halfSize=%s touching=%s"):format(
			tostring(state.StageId),
			tostring(reason or "checked"),
			pathToString(state.FinishWallPath),
			tostring(logicalBallPosition),
			tostring(wallPartCount or 0),
			matchedPart and matchedPart:GetFullName() or "nil",
			tostring(relative),
			tostring(halfSize),
			tostring(isTouching)
		)
	)
end

-- 使用逻辑球位置判断是否进入终点墙触发体，不依赖视觉球位置或物理碰撞。
local function isLogicalBallTouchingFinishWall(state, logicalBallPosition)
	if typeof(logicalBallPosition) ~= "Vector3" then
		debugFinishWallCheck(state, logicalBallPosition, 0, nil, nil, nil, false, "missing logical ball position")
		return false
	end

	local finishWallParts = type(state.FinishWallParts) == "table" and state.FinishWallParts or {}
	if #finishWallParts <= 0 then
		debugFinishWallCheck(state, logicalBallPosition, 0, nil, nil, nil, false, "missing finish wall parts")
		return false
	end

	local radius = math.max(0, tonumber(PushBallTheta.BallRadius) or 0)
	local buffer = math.max(0, tonumber(PushBallTheta.FinishWallBuffer) or 0)
	local extent = radius + buffer
	local bestPart = nil
	local bestRelative = nil
	local bestHalfSize = nil

	for _, wallPart in ipairs(finishWallParts) do
		if wallPart and wallPart.Parent and wallPart:IsA("BasePart") then
			local relative = wallPart.CFrame:PointToObjectSpace(logicalBallPosition)
			local halfSize = wallPart.Size * 0.5 + Vector3.new(extent, extent, extent)
			-- The push ball's logical Y is not grounded by raycast, so finish detection is horizontal.
			local isTouching = math.abs(relative.X) <= halfSize.X
				and math.abs(relative.Z) <= halfSize.Z

			if isTouching then
				debugFinishWallCheck(
					state,
					logicalBallPosition,
					#finishWallParts,
					wallPart,
					relative,
					halfSize,
					true,
					"matched"
				)
				debugLog(
					("Finish wall reached stage=%s wallPart=%s logicalBallPosition=%s"):format(
						tostring(state.StageId),
						wallPart:GetFullName(),
						tostring(logicalBallPosition)
					)
				)
				print("撞墙 触发了");
				return true
			end

			bestPart = wallPart
			bestRelative = relative
			bestHalfSize = halfSize
		end
	end

	debugFinishWallCheck(
		state,
		logicalBallPosition,
		#finishWallParts,
		bestPart,
		bestRelative,
		bestHalfSize,
		false,
		"checked"
	)
	return false
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

	local logicalBallPosition = state.OriginPosition
		+ state.Forward * state.Progress
		+ state.Lateral * state.LateralOffset
	state.LogicalBallPosition = logicalBallPosition

	if isLogicalBallTouchingFinishWall(state, logicalBallPosition) then
		handleStageReached(player, state)
		return
	end

	local ballPosition = getGroundedPosition(
		state,
		logicalBallPosition,
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
	local targetPlayerPosition = logicalBallPosition
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

local function createState(player, stageId, ballInstanceId, sourceBall, trackRoot, wall, wallPath, root, humanoid, character)
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
	local finishWallParts = collectBaseParts(wall)
	if #finishWallParts <= 0 then
		return nil
	end

	local ballGroundOffsetY = tonumber(PushBallTheta.BallGroundOffsetY) or 0
	local initialBallGround = raycastTrackPosition(trackRaycastParams, originPosition)
	local initialBallPosition = initialBallGround and initialBallGround + UP_VECTOR * (ballRadius + ballGroundOffsetY)
		or originPosition
	local configuredPlayerGroundOffsetY = tonumber(PushBallTheta.PlayerGroundOffsetY)
	local playerGround = raycastTrackPosition(trackRaycastParams, root.Position)
	local playerGroundOffsetY = configuredPlayerGroundOffsetY or (playerGround and root.Position.Y - playerGround.Y) or 3

	debugLog(
		("Stage %s ball=%s track=%s forward=%s lateral=%s finishWallParts=%s"):format(
			tostring(stageId),
			tostring(ballInstanceId),
			trackRoot:GetFullName(),
			tostring(forward),
			tostring(lateral),
			tostring(#finishWallParts)
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
		FinishWallParts = finishWallParts,
		FinishWallPath = wallPath,
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

	local state = createState(
		player,
		stageId,
		ballInstanceId,
		sourceBall,
		trackRoot,
		wall,
		sceneConfig.WallPath,
		root,
		humanoid,
		character
	)
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
