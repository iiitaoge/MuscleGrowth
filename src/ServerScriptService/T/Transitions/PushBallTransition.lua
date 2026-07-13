local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local StageTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("StageTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)
local TransitionResult = require(script.Parent.TransitionResult)
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

local function pathToString(path)
	return InstancePath.Format(path)
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

local function isAllowedTrackInstance(instance, trackSurfaces)
	if not instance then
		return false
	end

	for _, surface in ipairs(trackSurfaces) do
		if instance == surface or instance:IsDescendantOf(surface) then
			return true
		end
	end

	return false
end

local function buildTrackRaycastQuery(trackSurfaces, exclusions)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusions
	params.IgnoreWater = true

	return {
		AllowedSurfaces = trackSurfaces,
		Exclusions = exclusions,
		Params = params,
	}
end

local function raycastExactTrackPosition(raycastQuery, targetPosition)
	if not raycastQuery or typeof(targetPosition) ~= "Vector3" then
		return nil
	end

	local height = math.max(0, tonumber(PushBallTheta.TrackRaycastHeight) or 80)
	local depth = math.max(0, tonumber(PushBallTheta.TrackRaycastDepth) or 160)
	local origin = targetPosition + UP_VECTOR * height
	local direction = UP_VECTOR * -(height + depth)
	local raycastResult = Workspace:Raycast(origin, direction, raycastQuery.Params)
	if not raycastResult
		or not isAllowedTrackInstance(raycastResult.Instance, raycastQuery.AllowedSurfaces)
	then
		return nil
	end

	return raycastResult.Position
end

local function raycastTrackPosition(raycastQuery, targetPosition, probeDirection)
	local exactPosition = raycastExactTrackPosition(raycastQuery, targetPosition)
	if exactPosition then
		return exactPosition
	end

	local probeDistance = math.max(0, tonumber(PushBallTheta.TrackGroundProbeDistance) or 0)
	local horizontalDirection = getHorizontalDirection(probeDirection, nil)
	if probeDistance <= 0 or not horizontalDirection then
		return nil
	end

	for _, scale in ipairs({ 0.25, -0.25, 0.5, -0.5, 1, -1 }) do
		local sampledPosition = raycastExactTrackPosition(
			raycastQuery,
			targetPosition + horizontalDirection * (probeDistance * scale)
		)
		if sampledPosition then
			-- 探测点只提供地面高度；逻辑位置仍保持目标 X/Z，避免视觉横向跳变。
			return Vector3.new(targetPosition.X, sampledPosition.Y, targetPosition.Z)
		end
	end

	return nil
end

local function describeRaycastSurface(surface)
	if not surface then
		return "nil"
	end

	if surface:IsA("BasePart") then
		return ("%s<%s CanQuery=%s CanCollide=%s CollisionGroup=%s>"):format(
			surface:GetFullName(),
			surface.ClassName,
			tostring(surface.CanQuery),
			tostring(surface.CanCollide),
			tostring(surface.CollisionGroup)
		)
	end

	local queryableParts = 0
	for _, descendant in ipairs(surface:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.CanQuery then
			queryableParts += 1
		end
	end

	return ("%s<%s QueryableParts=%s>"):format(
		surface:GetFullName(),
		surface.ClassName,
		tostring(queryableParts)
	)
end

local function raycastWorldGround(targetPosition, exclusions)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclusions
	params.IgnoreWater = true

	local height = math.max(0, tonumber(PushBallTheta.TrackRaycastHeight) or 80)
	local depth = math.max(0, tonumber(PushBallTheta.TrackRaycastDepth) or 160)
	return Workspace:Raycast(
		targetPosition + UP_VECTOR * height,
		UP_VECTOR * -(height + depth),
		params
	)
end

local function describeUnfilteredGround(targetPosition, exclusions)
	local result = raycastWorldGround(targetPosition, exclusions)

	return result and describeRaycastSurface(result.Instance) or "nil"
end

local function addStartSurfaceFromWorldHit(trackSurfaces, worldHit)
	local hitInstance = worldHit and worldHit.Instance or nil
	if not hitInstance or isAllowedTrackInstance(hitInstance, trackSurfaces) then
		return false
	end

	local surfaceRoot = hitInstance.Parent
	if not surfaceRoot or surfaceRoot == Workspace then
		surfaceRoot = hitInstance
	end

	for _, surface in ipairs(trackSurfaces) do
		if surface == surfaceRoot then
			return false
		end
	end

	table.insert(trackSurfaces, surfaceRoot)
	return true
end

local function warnRaycastMiss(state, label, targetPosition)
	local now = os.clock()
	if state.LastRaycastWarnTime and now - state.LastRaycastWarnTime < 1 then
		return
	end

	state.LastRaycastWarnTime = now
	local allowedDescriptions = {}
	for _, surface in ipairs(state.TrackRaycastQuery.AllowedSurfaces) do
		table.insert(allowedDescriptions, describeRaycastSurface(surface))
	end

	warn(
		("Push ball track raycast missed for %s stage %s at %s worldHit=%s allowed=[%s]. Check track coverage and CanQuery."):format(
			label,
			tostring(state.StageId),
			tostring(targetPosition),
			describeUnfilteredGround(targetPosition, state.TrackRaycastQuery.Exclusions),
			table.concat(allowedDescriptions, "; ")
		)
	)
end

local function getPlayerTargetPosition(logicalBallPosition, forward, lateral)
	return logicalBallPosition
		- forward * (tonumber(PushBallTheta.PlayerBehindBallDistance) or 5)
		+ forward * (tonumber(PushBallTheta.PlayerForwardOffset) or 0)
		+ lateral * (tonumber(PushBallTheta.PlayerLateralOffset) or 0)
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

local function getTrackInfo(trackId)
	local trackConfig = type(PushBallTheta.Tracks) == "table" and PushBallTheta.Tracks[trackId] or nil
	if type(trackId) ~= "string" or type(trackConfig) ~= "table" then
		return nil
	end

	local firstStageId = math.max(1, math.floor(tonumber(trackConfig.FirstStageId) or 1))
	local lastStageId = math.max(firstStageId, math.floor(tonumber(trackConfig.LastStageId) or firstStageId))
	return {
		TrackId = trackId,
		FirstStageId = firstStageId,
		LastStageId = lastStageId,
		TravelDestinationId = type(trackConfig.TravelDestinationId) == "string"
			and trackConfig.TravelDestinationId
			or trackId,
	}
end

local function getTrackInfoForStage(stageId)
	if type(PushBallTheta.Tracks) ~= "table" then
		return nil
	end

	local matchedTrackInfo = nil
	for trackId in pairs(PushBallTheta.Tracks) do
		local trackInfo = getTrackInfo(trackId)
		if trackInfo then
			if stageId >= trackInfo.FirstStageId and stageId <= trackInfo.LastStageId then
				if matchedTrackInfo then
					return nil
				end

				matchedTrackInfo = trackInfo
			end
		end
	end

	return matchedTrackInfo
end

local function getRuntimeState(player, trackInfo)
	local travelRevision = TravelTransition.GetRevision(player)
	local state = runtimeStates[player]
	if not state or state.TrackId ~= trackInfo.TrackId or state.TravelRevision ~= travelRevision then
		state = {
			TrackId = trackInfo.TrackId,
			CompletedStage = trackInfo.FirstStageId - 1,
			TravelRevision = travelRevision,
			ClaimableStageRewards = {},
		}
		runtimeStates[player] = state
	end

	if type(state.ClaimableStageRewards) ~= "table" then
		state.ClaimableStageRewards = {}
	end

	return state
end

local function getNextStageId(player, trackInfo)
	local runtimeState = getRuntimeState(player, trackInfo)
	local completedStage = normalizeCompletedStage(runtimeState.CompletedStage)
	local nextStageId = math.max(trackInfo.FirstStageId, completedStage + 1)

	if nextStageId > trackInfo.LastStageId then
		return nil, runtimeState
	end

	return nextStageId, runtimeState
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

	local destination = InstancePath.WaitSpec({ Workspace = Workspace }, path, PATH_WAIT_SECONDS)
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
	character:PivotTo(destination.CFrame + Vector3.new(0, offsetY, 0))
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
		return
	end

	activeStates[player] = nil

	if state.Ball then
		state.Ball:Destroy()
	end

	if type(options) == "table" and options.TeleportStageId then
		local sceneConfig = type(PushBallSceneTheta.Stages) == "table" and PushBallSceneTheta.Stages[options.TeleportStageId] or nil
		if sceneConfig then
			teleportPlayerToPath(player, sceneConfig.TeleportPathSpec, "Stage " .. tostring(options.TeleportStageId))
		else
			warn("Missing push ball cleanup scene config: " .. tostring(options.TeleportStageId))
		end
	end

	if type(options) == "table" and type(options.TravelDestinationId) == "string" then
		local travelResult = TravelTransition.Request(player, options.TravelDestinationId)
		if travelResult.Success == false and travelResult.Message then
			warn(travelResult.Message)
		end
	end

	prepareCharacterForPushExit(state)
	setCharacterPushLocked(state, false)
	recoverHumanoidAfterPushExit(state)
	PlayerVisualStateSync.SetPushBallActive(player, false)

	stopHeartbeatIfIdle()

	if type(state.AutoCompletion) == "function" then
		local completion = state.AutoCompletion
		local completionResult = {
			StageId = state.StageId,
			TrackId = state.TrackId,
			Passed = type(options) == "table" and options.Passed == true,
			Cancelled = type(options) ~= "table" or options.Cancelled == true,
			Reason = type(options) == "table" and options.Reason or "Cancelled",
		}
		task.defer(function()
			local ok, err = pcall(completion, completionResult)
			if not ok then
				warn("Auto push completion callback failed: " .. tostring(err))
			end
		end)
	end

end

local function markStageCompleted(player, state)
	local runtimeState = runtimeStates[player]
	if not runtimeState
		or runtimeState.TrackId ~= state.TrackId
		or runtimeState.TravelRevision ~= state.TravelRevision
	then
		return false
	end

	runtimeState.CompletedStage = math.max(normalizeCompletedStage(runtimeState.CompletedStage), state.StageId)
	runtimeState.ClaimableStageRewards[state.StageId] = true
	return true
end

local function handleStageReached(player, state)
	local stageId = state.StageId
	local _, gameplayConfig = getStageConfig(stageId)
	if not gameplayConfig then
		cleanupState(player, {
			Cancelled = true,
			Reason = "MissingStageConfig",
		})
		return
	end

	local progressState = PlayerProgressState.Get(player)
	local strength = tonumber(progressState and progressState.Strength) or 0
	local requiredStrength = tonumber(gameplayConfig.RecommendedStrength) or math.huge
	warn(
		("[PushBallResult] player=%s track=%s stage=%s strength=%s required=%s passed=%s"):format(
			player.Name,
			tostring(state.TrackId),
			tostring(stageId),
			tostring(strength),
			tostring(requiredStrength),
			tostring(strength >= requiredStrength)
		)
	)

	if strength >= requiredStrength then
		if not markStageCompleted(player, state) then
			cleanupState(player, {
				Cancelled = true,
				Reason = "RuntimeStateChanged",
			})
			return
		end

		cleanupState(player, {
			TeleportStageId = stageId,
			Passed = true,
			Reason = "StageCompleted",
		})
	else
		if stageId == state.FirstStageId then
			cleanupState(player, {
				TravelDestinationId = state.TravelDestinationId,
				Passed = false,
				Reason = "InsufficientStrength",
			})
		else
			cleanupState(player, {
				TeleportStageId = stageId - 1,
				Passed = false,
				Reason = "InsufficientStrength",
			})
		end
	end
end

-- 使用逻辑球位置判断是否进入终点墙触发体，不依赖视觉球位置或物理碰撞。
local function isLogicalBallTouchingFinishWall(state, logicalBallPosition)
	if typeof(logicalBallPosition) ~= "Vector3" then
		return false
	end

	local finishWallParts = type(state.FinishWallParts) == "table" and state.FinishWallParts or {}
	if #finishWallParts <= 0 then
		return false
	end

	local radius = math.max(0, tonumber(PushBallTheta.BallRadius) or 0)
	local buffer = math.max(0, tonumber(PushBallTheta.FinishWallBuffer) or 0)
	local extent = radius + buffer

	for _, wallPart in ipairs(finishWallParts) do
		if wallPart and wallPart.Parent and wallPart:IsA("BasePart") then
			local relative = wallPart.CFrame:PointToObjectSpace(logicalBallPosition)
			local halfSize = wallPart.Size * 0.5 + Vector3.new(extent, extent, extent)
			-- The push ball's logical Y is not grounded by raycast, so finish detection is horizontal.
			local isTouching = math.abs(relative.X) <= halfSize.X
				and math.abs(relative.Z) <= halfSize.Z

			if isTouching then
				return true
			end
		end
	end

	return false
end

local function isWorldHitInsideStageFinishPlatform(state, logicalBallPosition)
	local worldHit = raycastWorldGround(logicalBallPosition, state.TrackRaycastQuery.Exclusions)
	local current = worldHit and worldHit.Instance or nil
	local expectedPlatformName = "M" .. tostring(state.StageId)

	while current and current ~= Workspace do
		if current.Name == expectedPlatformName
			and current.Parent
			and current.Parent.Name == "Mid"
		then
			return true
		end

		current = current.Parent
	end

	return false
end

local function updateState(player, state, dt)
	if state.TravelRevision ~= TravelTransition.GetRevision(player) then
		runtimeStates[player] = nil
		cleanupState(player, {
			Cancelled = true,
			Reason = "TravelChanged",
		})
		return
	end

	local character, humanoid, root = getCharacterParts(player)
	if character ~= state.Character or humanoid ~= state.Humanoid or root ~= state.RootPart then
		cleanupState(player, {
			Cancelled = true,
			Reason = "CharacterChanged",
		})
		return
	end

	local pushSpeed = math.max(0, tonumber(PushBallTheta.PushSpeed) or 0)
	local lateralSpeed = math.max(0, tonumber(PushBallTheta.LateralSpeed) or 0)
	local laneHalfWidth = math.max(0, tonumber(PushBallTheta.LaneHalfWidth) or 0)
	local ballRadius = math.max(0.1, tonumber(PushBallTheta.BallRadius) or 3)
	local ballGroundOffsetY = state.BallGroundOffsetY

	local nextProgress = state.Progress + pushSpeed * dt
	local nextLateralOffset = math.clamp(
		state.LateralOffset + state.LateralInput * lateralSpeed * dt,
		-laneHalfWidth,
		laneHalfWidth
	)

	local logicalBallPosition = state.OriginPosition
		+ state.Forward * nextProgress
		+ state.Lateral * nextLateralOffset

	if isLogicalBallTouchingFinishWall(state, logicalBallPosition) then
		handleStageReached(player, state)
		return
	end

	local ballGroundPosition = raycastTrackPosition(state.TrackRaycastQuery, logicalBallPosition, state.Forward)
	if not ballGroundPosition then
		-- 有些终点装饰会先于配置墙覆盖球心射线；进入当前关的 M 平台即视为到达终点。
		if isWorldHitInsideStageFinishPlatform(state, logicalBallPosition) then
			handleStageReached(player, state)
			return
		end

		warnRaycastMiss(state, "ball", logicalBallPosition)
		return
	end

	local nextStartElapsed = state.StartElapsed + dt
	local startAlignmentDuration = math.max(0, tonumber(PushBallTheta.StartAlignmentDuration) or 0)
	local alignmentAlpha = startAlignmentDuration > 0
		and math.clamp(nextStartElapsed / startAlignmentDuration, 0, 1)
		or 1

	local desiredPlayerPosition = getPlayerTargetPosition(logicalBallPosition, state.Forward, state.Lateral)
	local targetPlayerPosition = state.StartPlayerPosition:Lerp(desiredPlayerPosition, alignmentAlpha)
	local playerGroundPosition = raycastTrackPosition(state.TrackRaycastQuery, targetPlayerPosition, state.Forward)
	if not playerGroundPosition then
		warnRaycastMiss(state, "player", targetPlayerPosition)
		return
	end

	local ballPosition = ballGroundPosition + UP_VECTOR * (ballRadius + ballGroundOffsetY)
	local playerPosition = playerGroundPosition + UP_VECTOR * state.PlayerGroundOffsetY

	state.Progress = nextProgress
	state.LateralOffset = nextLateralOffset
	state.LogicalBallPosition = logicalBallPosition
	state.BallPosition = ballPosition
	state.PlayerPosition = playerPosition
	state.StartElapsed = nextStartElapsed

	local rollAngle = -state.Progress / ballRadius
	local ballCFrame = CFrame.new(ballPosition) * CFrame.fromAxisAngle(state.Lateral, rollAngle) * state.BallBaseRotation
	pivotTo(state.Ball, ballCFrame)

	local startFacingCFrame = CFrame.new(playerPosition) * state.StartPlayerRotation
	local pushFacingCFrame = CFrame.lookAt(playerPosition, playerPosition + state.Forward)
	character:PivotTo(startFacingCFrame:Lerp(pushFacingCFrame, alignmentAlpha))
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

local function createState(
	player,
	stageId,
	trackInfo,
	travelRevision,
	ballInstanceId,
	sourceBall,
	trackRoot,
	trackSurfaces,
	wall,
	root,
	humanoid,
	character
)
	local sourcePivot = getPivot(sourceBall)
	if not sourcePivot then
		return nil
	end

	local wallPivot = getPivot(wall)
	if not wallPivot then
		return nil
	end

	local exclusions = { sourceBall, character }
	local trackRaycastQuery = buildTrackRaycastQuery(trackSurfaces, exclusions)
	local forward = getStageForward(sourcePivot, wallPivot)
	local lateral = getStageLateral(forward)

	local ballBaseRotation = sourcePivot - sourcePivot.Position
	local originPosition = sourcePivot.Position
	local ballRadius = math.max(0.1, tonumber(PushBallTheta.BallRadius) or 3)
	local finishWallParts = collectBaseParts(wall)
	if #finishWallParts <= 0 then
		return nil
	end

	local initialBallGround = raycastTrackPosition(trackRaycastQuery, originPosition, forward)
	local initialPlayerTarget = getPlayerTargetPosition(originPosition, forward, lateral)
	local initialPlayerGround = raycastTrackPosition(trackRaycastQuery, initialPlayerTarget, forward)
	local currentPlayerGround = raycastTrackPosition(trackRaycastQuery, root.Position, forward)
	if not initialBallGround or not initialPlayerGround or not currentPlayerGround then
		local addedStartSurface = false
		for _, targetPosition in ipairs({ originPosition, initialPlayerTarget, root.Position }) do
			if addStartSurfaceFromWorldHit(
				trackSurfaces,
				raycastWorldGround(targetPosition, exclusions)
			) then
				addedStartSurface = true
			end
		end

		if addedStartSurface then
			trackRaycastQuery = buildTrackRaycastQuery(trackSurfaces, exclusions)
			initialBallGround = raycastTrackPosition(trackRaycastQuery, originPosition, forward)
			initialPlayerGround = raycastTrackPosition(trackRaycastQuery, initialPlayerTarget, forward)
			currentPlayerGround = raycastTrackPosition(trackRaycastQuery, root.Position, forward)
		end
	end

	if not initialBallGround or not initialPlayerGround or not currentPlayerGround then
		local surfaceDescriptions = {}
		for _, surface in ipairs(trackSurfaces) do
			table.insert(surfaceDescriptions, describeRaycastSurface(surface))
		end

		warn(
			("Push ball start surface missing for %s stage %s (ball=%s playerTarget=%s currentPlayer=%s) allowed=[%s] worldHits=[ball=%s playerTarget=%s currentPlayer=%s]."):format(
				player.Name,
				tostring(stageId),
				tostring(initialBallGround ~= nil),
				tostring(initialPlayerGround ~= nil),
				tostring(currentPlayerGround ~= nil),
				table.concat(surfaceDescriptions, "; "),
				describeUnfilteredGround(originPosition, exclusions),
				describeUnfilteredGround(initialPlayerTarget, exclusions),
				describeUnfilteredGround(root.Position, exclusions)
			)
		)
		return nil
	end

	local ballGroundOffsetY = tonumber(PushBallTheta.BallGroundOffsetY) or 0
	if PushBallTheta.PreserveSourceBallHeight == true then
		ballGroundOffsetY = originPosition.Y - initialBallGround.Y - ballRadius
	end

	local initialBallPosition = initialBallGround + UP_VECTOR * (ballRadius + ballGroundOffsetY)
	local configuredPlayerGroundOffsetY = tonumber(PushBallTheta.PlayerGroundOffsetY)
	local playerGroundOffsetY = configuredPlayerGroundOffsetY or (root.Position.Y - currentPlayerGround.Y)

	local ballClone = sourceBall:Clone()
	ballClone.Name = "PushBall_" .. tostring(player.UserId) .. "_" .. ballInstanceId
	prepareBallClone(ballClone)
	pivotTo(ballClone, CFrame.new(initialBallPosition) * ballBaseRotation)
	ballClone.Parent = getBallFolder()

	return {
		Player = player,
		BallInstanceId = ballInstanceId,
		Character = character,
		Humanoid = humanoid,
		RootPart = root,
		Ball = ballClone,
		BallBaseRotation = ballBaseRotation,
		BallGroundOffsetY = ballGroundOffsetY,
		BallPosition = initialBallPosition,
		PlayerPosition = root.Position,
		OriginPosition = originPosition,
		Forward = forward,
		Lateral = lateral,
		TrackRoot = trackRoot,
		TrackRaycastQuery = trackRaycastQuery,
		StageId = stageId,
		TrackId = trackInfo.TrackId,
		FirstStageId = trackInfo.FirstStageId,
		TravelDestinationId = trackInfo.TravelDestinationId,
		TravelRevision = travelRevision,
		FinishWallParts = finishWallParts,
		Progress = 0,
		LateralOffset = 0,
		LateralInput = 0,
		StartElapsed = 0,
		StartPlayerPosition = root.Position,
		StartPlayerRotation = root.CFrame - root.Position,
		PlayerGroundOffsetY = playerGroundOffsetY,
		OriginalWalkSpeed = humanoid.WalkSpeed,
		OriginalJumpPower = humanoid.JumpPower,
		OriginalAutoRotate = humanoid.AutoRotate,
		OriginalRootAnchored = root.Anchored,
	}
end

local function positionCharacterAtSource(character, root, sourceBall, trackSurfaces, wall)
	local sourcePivot = getPivot(sourceBall)
	local wallPivot = getPivot(wall)
	if not sourcePivot or not wallPivot then
		return false
	end

	local exclusions = { sourceBall, character }
	local forward = getStageForward(sourcePivot, wallPivot)
	local lateral = getStageLateral(forward)
	local targetPosition = getPlayerTargetPosition(sourcePivot.Position, forward, lateral)
	local raycastQuery = buildTrackRaycastQuery(trackSurfaces, exclusions)
	local groundPosition = raycastTrackPosition(raycastQuery, targetPosition, forward)

	if not groundPosition and addStartSurfaceFromWorldHit(
		trackSurfaces,
		raycastWorldGround(targetPosition, exclusions)
	) then
		raycastQuery = buildTrackRaycastQuery(trackSurfaces, exclusions)
		groundPosition = raycastTrackPosition(raycastQuery, targetPosition, forward)
	end

	if not groundPosition then
		return false
	end

	local playerGroundOffsetY = tonumber(PushBallTheta.PlayerGroundOffsetY) or 3.5
	local playerPosition = groundPosition + UP_VECTOR * playerGroundOffsetY
	clearCharacterVelocity(character)
	character:PivotTo(CFrame.lookAt(playerPosition, playerPosition + forward))
	clearCharacterVelocity(character)
	return (root.Position - sourcePivot.Position).Magnitude <= math.max(
		0,
		tonumber(PushBallTheta.InteractionDistance) or 14
	)
end

local function requestStart(player, ballInstanceId, options)
	options = type(options) == "table" and options or {}

	if activeStates[player] then
		return result(false, "Already pushing ball", activeStates[player].StageId)
	end

	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return result(false, "Missing player progress")
	end

	local ballConfig = getBallConfig(ballInstanceId)
	if not ballConfig then
		return result(false, "Invalid push ball")
	end

	local ballStageId = math.floor(tonumber(ballConfig.StageId) or 0)
	local trackInfo = getTrackInfoForStage(ballStageId)
	if not trackInfo then
		return result(false, "Missing or overlapping push ball track config", ballStageId)
	end
	if type(options.TrackId) == "string" and options.TrackId ~= trackInfo.TrackId then
		return result(false, "Push ball does not belong to Auto Win track", ballStageId)
	end

	local stageId, runtimeState = getNextStageId(player, trackInfo)
	if not stageId then
		return result(false, "All push ball stages completed", ballStageId)
	end

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

	local sourceBall = InstancePath.WaitSpec({ Workspace = Workspace }, ballConfig.PathSpec, PATH_WAIT_SECONDS)
	if not sourceBall then
		return result(false, "Missing push ball source", stageId)
	end

	local trackRoot = InstancePath.WaitSpec({ Workspace = Workspace }, sceneConfig.TrackPathSpec, PATH_WAIT_SECONDS)
	if not trackRoot then
		return result(false, "Missing push ball track: " .. pathToString(sceneConfig.TrackPathSpec), stageId)
	end

	local trackSurfaces = { trackRoot }
	if type(sceneConfig.StartSurfacePathSpec) == "table" then
		local startSurface = InstancePath.WaitSpec(
			{ Workspace = Workspace },
			sceneConfig.StartSurfacePathSpec,
			PATH_WAIT_SECONDS
		)
		if not startSurface then
			return result(
				false,
				"Missing push ball start surface: " .. pathToString(sceneConfig.StartSurfacePathSpec),
				stageId
			)
		end

		table.insert(trackSurfaces, startSurface)
	end

	local wall = InstancePath.WaitSpec({ Workspace = Workspace }, sceneConfig.WallPathSpec, PATH_WAIT_SECONDS)
	if not wall then
		return result(false, "Missing push ball wall: " .. pathToString(sceneConfig.WallPathSpec), stageId)
	end

	if options.PositionAtSource == true
		and not positionCharacterAtSource(character, root, sourceBall, trackSurfaces, wall)
	then
		return result(false, "Unable to position player at push ball", stageId)
	end

	if not isPlayerNearSourceBall(root, sourceBall) then
		return result(false, "Too far from push ball", stageId)
	end

	local state = createState(
		player,
		stageId,
		trackInfo,
		runtimeState.TravelRevision,
		ballInstanceId,
		sourceBall,
		trackRoot,
		trackSurfaces,
		wall,
		root,
		humanoid,
		character
	)
	if not state then
		return result(false, "Invalid push ball source", stageId)
	end

	state.IsAutoWin = options.IsAutoWin == true
	state.AutoCompletion = type(options.AutoCompletion) == "function" and options.AutoCompletion or nil

	activeStates[player] = state
	setCharacterPushLocked(state, true)
	TrainingTransition.SetMoving(player, false)
	-- 发布 推球状态 目前球的ID 可扩展
	PlayerVisualStateSync.SetPushBallActive(player, true, ballInstanceId)
	ensureHeartbeat()

	return result(true, "Push ball started", stageId)
end

function PushBallTransition.RequestStart(player, ballInstanceId)
	return requestStart(player, ballInstanceId)
end

function PushBallTransition.RequestAutoStart(player, trackId, ballInstanceId, onComplete)
	if not getTrackInfo(trackId) then
		return result(false, "Invalid Auto Win track")
	end
	if type(onComplete) ~= "function" then
		return result(false, "Missing Auto Win completion callback")
	end

	return requestStart(player, ballInstanceId, {
		TrackId = trackId,
		PositionAtSource = true,
		IsAutoWin = true,
		AutoCompletion = onComplete,
	})
end

function PushBallTransition.SetLateralInput(player, lateralInput)
	local state = activeStates[player]
	if not state then
		return false
	end
	if state.IsAutoWin then
		state.LateralInput = 0
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
	cleanupState(player, {
		Cancelled = true,
		Reason = "Stopped",
	})
	return result(true, "Push ball stopped", stageId)
end

function PushBallTransition.RequestStopAuto(player)
	local state = activeStates[player]
	if not state or not state.IsAutoWin then
		return result(true, "Auto push ball is not active")
	end

	local stageId = state.StageId
	cleanupState(player, {
		Cancelled = true,
		Reason = "AutoWinStopped",
	})
	return result(true, "Auto push ball stopped", stageId)
end

function PushBallTransition.GetTrackProgress(player, trackId)
	local trackInfo = getTrackInfo(trackId)
	if not trackInfo then
		return nil
	end

	local nextStageId, runtimeState = getNextStageId(player, trackInfo)
	return {
		TrackId = trackInfo.TrackId,
		FirstStageId = trackInfo.FirstStageId,
		LastStageId = trackInfo.LastStageId,
		CompletedStage = normalizeCompletedStage(runtimeState.CompletedStage),
		NextStageId = nextStageId,
	}
end

function PushBallTransition.ConsumeClaimableStageReward(player, stageId)
	local normalizedStageId = math.floor(tonumber(stageId) or 0)
	if normalizedStageId <= 0 then
		return false
	end

	local runtimeState = runtimeStates[player]
	if runtimeState and runtimeState.TravelRevision ~= TravelTransition.GetRevision(player) then
		runtimeStates[player] = nil
		return false
	end

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
	cleanupState(player, {
		Cancelled = true,
		Reason = "PlayerRemoved",
	})
	runtimeStates[player] = nil
end

return PushBallTransition
