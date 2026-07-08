local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = require(script.Parent.Parent.WorldSync.TravelDestinationWorldSync)

local TravelTransition = {}

local INVALID_DESTINATION_MESSAGE = "Invalid travel destination"

local function failure(message, destinationId)
	return {
		Success = false,
		Message = message,
		DestinationId = destinationId,
	}
end

local function success(message, destinationId)
	return {
		Success = true,
		Message = message,
		DestinationId = destinationId,
	}
end

local function isValidDestinationId(destinationId)
	return type(destinationId) == "string"
		and type(TravelDestinationTheta.Destinations) == "table"
		and type(TravelDestinationTheta.Destinations[destinationId]) == "table"
end

function TravelTransition.Request(player, destinationId)
	if not isValidDestinationId(destinationId) then
		return failure(INVALID_DESTINATION_MESSAGE, destinationId)
	end

	local ok, err = pcall(TravelDestinationWorldSync.TeleportPlayer, player, destinationId)
	if not ok then
		return failure(tostring(err), destinationId)
	end

	return success("Travel succeeded", destinationId)
end

return TravelTransition
