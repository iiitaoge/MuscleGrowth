-- PushBallTeleportController
-- Client-side diagnostics and streaming preparation for push-ball teleports.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))

local PushBallTeleportController = {}

local OVERLAP_SIZE = Vector3.new(10, 12, 10)
local RAYCAST_HEIGHT = 5
local RAYCAST_DEPTH = 80
local MAX_PARTS_TO_LOG = 12

local function debugLog(...)
	if PushBallTheta.DebugPushBall == true then
		print("[PushBallTeleportController]", ...)
	end
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

local function getCharacter()
	return Players.LocalPlayer and Players.LocalPlayer.Character or nil
end

local function getGroundHit(position)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getCharacter() }
	params.IgnoreWater = true

	local origin = position + Vector3.new(0, RAYCAST_HEIGHT, 0)
	local direction = Vector3.new(0, -(RAYCAST_HEIGHT + RAYCAST_DEPTH), 0)
	return Workspace:Raycast(origin, direction, params)
end

local function getOverlapParts(position)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getCharacter() }

	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), OVERLAP_SIZE, params)
	local collidable = {}

	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and part.CanCollide then
			table.insert(collidable, part)
		end
	end

	return collidable
end

local function summarizeParts(parts)
	local summary = {}
	for index, part in ipairs(parts) do
		if index > MAX_PARTS_TO_LOG then
			break
		end

		table.insert(summary, {
			Name = part:GetFullName(),
			Size = tostring(part.Size),
			Position = tostring(part.Position),
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			CanQuery = part.CanQuery,
			CollisionGroup = part.CollisionGroup,
		})
	end

	return summary
end

local function requestStreamAround(position, timeout)
	if Workspace.StreamingEnabled ~= true then
		return true, "streaming disabled"
	end

	local success, err = pcall(function()
		if timeout and timeout > 0 then
			Players.LocalPlayer:RequestStreamAroundAsync(position, timeout)
		else
			Players.LocalPlayer:RequestStreamAroundAsync(position)
		end
	end)

	if not success then
		return false, tostring(err)
	end

	return true, nil
end

local function buildResult(payload, position, destination, groundHit, overlapParts, streamOk, streamError)
	return {
		Success = destination ~= nil and groundHit ~= nil,
		Label = payload and payload.Label or "",
		Position = tostring(position),
		StreamingEnabled = Workspace.StreamingEnabled == true,
		StreamOk = streamOk == true,
		StreamError = streamError,
		DestinationVisible = destination ~= nil,
		DestinationFullName = destination and destination:GetFullName() or nil,
		DestinationClassName = destination and destination.ClassName or nil,
		GroundHitName = groundHit and groundHit.Instance and groundHit.Instance:GetFullName() or nil,
		GroundHitMaterial = groundHit and groundHit.Material.Name or nil,
		GroundHitPosition = groundHit and tostring(groundHit.Position) or nil,
		OverlapCount = #overlapParts,
		OverlapParts = summarizeParts(overlapParts),
	}
end

function PushBallTeleportController.Init(remoteClient)
	local remote = remoteClient.Get("PushBallPrepareTeleport")

	remote.OnClientInvoke = function(payload)
		local position = type(payload) == "table" and payload.Position or nil
		if typeof(position) ~= "Vector3" then
			debugLog("Prepare failed", "reason=", "missing position")
			return {
				Success = false,
				Error = "missing position",
			}
		end

		local path = type(payload) == "table" and payload.Path or nil
		local streamTimeout = math.max(0, tonumber(payload and payload.StreamTimeout) or tonumber(PushBallTheta.TeleportStreamTimeout) or 0)
		local verifyTimeout = math.max(0, tonumber(payload and payload.VerifyTimeout) or tonumber(PushBallTheta.TeleportClientVerifyTimeout) or 0)

		debugLog(
			"Prepare start",
			"label=", payload and payload.Label or "",
			"position=", position,
			"path=", type(path) == "table" and table.concat(path, "/") or tostring(path),
			"streamTimeout=", streamTimeout,
			"verifyTimeout=", verifyTimeout
		)

		local streamOk, streamError = requestStreamAround(position, streamTimeout)
		local deadline = os.clock() + verifyTimeout
		local destination = findPath(Workspace, path)
		local groundHit = getGroundHit(position)
		local overlapParts = getOverlapParts(position)

		while os.clock() < deadline and (not destination or not groundHit) do
			task.wait(0.1)
			destination = findPath(Workspace, path)
			groundHit = getGroundHit(position)
			overlapParts = getOverlapParts(position)
		end

		local result = buildResult(payload, position, destination, groundHit, overlapParts, streamOk, streamError)
		debugLog(
			"Prepare result",
			"success=", result.Success,
			"streamOk=", result.StreamOk,
			"destinationVisible=", result.DestinationVisible,
			"destination=", result.DestinationFullName,
			"ground=", result.GroundHitName,
			"groundMaterial=", result.GroundHitMaterial,
			"overlapCount=", result.OverlapCount
		)

		for index, partInfo in ipairs(result.OverlapParts) do
			debugLog(
				"Prepare overlap",
				index,
				partInfo.Name,
				"size=", partInfo.Size,
				"position=", partInfo.Position,
				"transparency=", partInfo.Transparency,
				"collisionGroup=", partInfo.CollisionGroup
			)
		end

		return result
	end

	debugLog("Bind prepare teleport remote")
end

return PushBallTeleportController
