-- TravelActionController
-- Sends travel requests when a destination button is activated.

local TravelActionController = {}

function TravelActionController.Init(snapshotController, travelPanelView)
	local function requestTravel(destinationId)
		local result = snapshotController.InvokeAction("RequestTravelDestination", destinationId)

		if result and result.Success == true then
			travelPanelView.SetOpen(false)
		end
	end

	travelPanelView.SetDestinationHandler(requestTravel)
end

return TravelActionController
