local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = {}

local DESTINATION_WAIT_SECONDS = 5

local function waitForPath(root, path)
	assert(type(path) == "table" and #path > 0, "Travel destination path must not be empty.")

	local current = root

	for _, name in ipairs(path) do
		assert(type(name) == "string" and name ~= "", "Travel destination path contains an invalid child name.")

		local nextChild = current:WaitForChild(name, DESTINATION_WAIT_SECONDS)
		assert(
			nextChild,
			("Travel destination path missing child '%s' under %s."):format(name, current:GetFullName())
		)

		current = nextChild
	end

	return current
end

-- 有错直接报，不兜底
-- 执行传送 玩家 目的地
function TravelDestinationWorldSync.TeleportPlayer(player, destinationId)
	local config = TravelDestinationTheta.Destinations[destinationId]
	assert(config, "Invalid destinationId: " .. tostring(destinationId))

	local character = player.Character
	assert(character, "Player has no character: " .. player.Name)

	local destinationPart = waitForPath(Workspace, config.Path)
	assert(destinationPart:IsA("BasePart"), "Travel destination must be a BasePart: " .. destinationPart:GetFullName())

	local offsetY = config.OffsetY or 5

	character:PivotTo(destinationPart.CFrame + Vector3.new(0, offsetY, 0))

	player:SetAttribute("CurrentDestinationId", destinationId)
end

return TravelDestinationWorldSync
