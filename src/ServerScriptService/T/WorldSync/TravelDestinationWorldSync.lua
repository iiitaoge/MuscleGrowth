local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = {}

local function waitForPath(root, path)
	local current = root

	for _, name in ipairs(path) do
		current = current:WaitForChild(name)
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
	local offsetY = config.OffsetY or 5

	character:PivotTo(destinationPart.CFrame * CFrame.new(0, offsetY, 0))

	player:SetAttribute("CurrentDestinationId", destinationId)
end

return TravelDestinationWorldSync