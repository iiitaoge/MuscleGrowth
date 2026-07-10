local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = {}

local DESTINATION_WAIT_SECONDS = 5

-- 有错直接报，不兜底
-- 执行传送 玩家 目的地
function TravelDestinationWorldSync.TeleportPlayer(player, destinationId)
	local config = TravelDestinationTheta.Destinations[destinationId]
	assert(config, "Invalid destinationId: " .. tostring(destinationId))

	local character = player.Character
	assert(character, "Player has no character: " .. player.Name)

	local destinationPart = InstancePath.RequireSpec(
		{ Workspace = Workspace },
		config.Path,
		"Travel destination " .. tostring(destinationId)
	)
	assert(destinationPart:IsA("BasePart"), "Travel destination must be a BasePart: " .. destinationPart:GetFullName())

	local offsetY = config.OffsetY or 5

	character:PivotTo(destinationPart.CFrame + Vector3.new(0, offsetY, 0))

	player:SetAttribute("CurrentDestinationId", destinationId)
end

return TravelDestinationWorldSync
