local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = require(script.Parent.Parent.WorldSync.TravelDestinationWorldSync)
local TransitionResult = require(script.Parent.TransitionResult)

local TravelTransition = {}

local INVALID_DESTINATION_MESSAGE = "Invalid travel destination"

local function isValidDestinationId(destinationId)
	return type(destinationId) == "string"
		and type(TravelDestinationTheta.Destinations) == "table"
		and type(TravelDestinationTheta.Destinations[destinationId]) == "table"
end

function TravelTransition.Request(player, destinationId)
	if not isValidDestinationId(destinationId) then
		return TransitionResult.New(false, INVALID_DESTINATION_MESSAGE, {
			DestinationId = destinationId,
		})
	end

	local ok, err = pcall(TravelDestinationWorldSync.TeleportPlayer, player, destinationId)
	if not ok then
		return TransitionResult.New(false, tostring(err), {
			DestinationId = destinationId,
		})
	end

	return TransitionResult.New(true, "Travel succeeded", {
		DestinationId = destinationId,
	})
end

return TravelTransition
