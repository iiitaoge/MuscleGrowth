-- TravelActionController
-- Sends travel requests when a destination button is activated.

local TravelActionController = {}

function TravelActionController.Init(remoteClient, snapshotController, travelPanelView)
	local function requestTravel(destinationId)
		local result = snapshotController.ApplyRemoteResult(
			remoteClient.SafeInvoke("RequestTravelDestination", destinationId)
		)

		if result and result.Success == true then
			travelPanelView.SetOpen(false)
		end
	end

	travelPanelView.SetDestinationHandler(requestTravel)

	return {}
end

return TravelActionController
