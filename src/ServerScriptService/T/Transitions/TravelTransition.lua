local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TravelDestinationTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("TravelDestinationTheta")
)

local TravelDestinationWorldSync = require(script.Parent.Parent.WorldSync.TravelDestinationWorldSync)
local TransitionResult = require(script.Parent.TransitionResult)

local TravelTransition = {}

local INVALID_DESTINATION_MESSAGE = "Invalid travel destination"
local travelRevisionByPlayer = setmetatable({}, {
	__mode = "k",
})

local function isValidDestinationId(destinationId)
	return type(destinationId) == "string"
		and type(TravelDestinationTheta.Destinations) == "table"
		and type(TravelDestinationTheta.Destinations[destinationId]) == "table"
end

local function getTravelRevision(player)
	return math.max(0, math.floor(tonumber(travelRevisionByPlayer[player]) or 0))
end

function TravelTransition.Request(player, destinationId)
	if not isValidDestinationId(destinationId) then
		return TransitionResult.New(false, INVALID_DESTINATION_MESSAGE, {
			DestinationId = destinationId,
		})
	end

	local previousDestinationId = player:GetAttribute("CurrentDestinationId")
	local ok, err = pcall(TravelDestinationWorldSync.TeleportPlayer, player, destinationId)
	if not ok then
		return TransitionResult.New(false, tostring(err), {
			DestinationId = destinationId,
		})
	end

	if previousDestinationId ~= destinationId then
		travelRevisionByPlayer[player] = getTravelRevision(player) + 1
	end

	return TransitionResult.New(true, "Travel succeeded", {
		DestinationId = destinationId,
	})
end

function TravelTransition.GetRevision(player)
	return getTravelRevision(player)
end

return TravelTransition
