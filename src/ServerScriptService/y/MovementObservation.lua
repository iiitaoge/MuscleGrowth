local MovementObservation = {}

local MIN_HORIZONTAL_DISTANCE = 0.5
local MAX_HORIZONTAL_SPEED = 80
local MAX_HORIZONTAL_DISTANCE = 120
local MIN_OBSERVE_INTERVAL = 0.05

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getHorizontalDistance(fromPosition, toPosition)
	local deltaX = toPosition.X - fromPosition.X
	local deltaZ = toPosition.Z - fromPosition.Z

	return math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
end

function MovementObservation.Reset(runtimeState)
	runtimeState.LastMovementPosition = nil
	runtimeState.LastMovementObservedAt = 0
	runtimeState.UnconfirmedMoveChecks = 0

	return runtimeState
end

-- 算法检测玩家是否真实移动
function MovementObservation.Observe(player, runtimeState)
	runtimeState = runtimeState or {}

	local root = getCharacterRoot(player)
	local now = os.clock()
	if not root then
		runtimeState.IsMoving = false
		runtimeState.UnconfirmedMoveChecks = (tonumber(runtimeState.UnconfirmedMoveChecks) or 0) + 1
		return false, runtimeState
	end

	local currentPosition = root.Position
	local lastPosition = runtimeState.LastMovementPosition
	local lastObservedAt = tonumber(runtimeState.LastMovementObservedAt) or 0

	runtimeState.LastMovementPosition = currentPosition
	runtimeState.LastMovementObservedAt = now

	if typeof(lastPosition) ~= "Vector3" or lastObservedAt <= 0 then
		runtimeState.IsMoving = false
		runtimeState.UnconfirmedMoveChecks = (tonumber(runtimeState.UnconfirmedMoveChecks) or 0) + 1
		return false, runtimeState
	end

	local elapsed = math.max(now - lastObservedAt, MIN_OBSERVE_INTERVAL)
	local horizontalDistance = getHorizontalDistance(lastPosition, currentPosition)
	local maxAllowedDistance = math.min(MAX_HORIZONTAL_SPEED * elapsed, MAX_HORIZONTAL_DISTANCE)
	local isMoving = horizontalDistance >= MIN_HORIZONTAL_DISTANCE and horizontalDistance <= maxAllowedDistance

	runtimeState.IsMoving = isMoving
	if isMoving then
		runtimeState.UnconfirmedMoveChecks = 0
	else
		runtimeState.UnconfirmedMoveChecks = (tonumber(runtimeState.UnconfirmedMoveChecks) or 0) + 1
	end

	return isMoving, runtimeState
end

return MovementObservation
