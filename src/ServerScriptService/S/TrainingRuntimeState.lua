local TrainingRuntimeState = {}
local states = {}

local function cloneContacts(contacts)
	local copy = {}

	if type(contacts) ~= "table" then
		return copy
	end

	for areaId, isActive in pairs(contacts) do
		if type(areaId) == "string" and isActive == true then
			copy[areaId] = true
		end
	end

	return copy
end

local function cloneRuntimeState(state)
	state = state or {}

	return {
		IsMoving = state.IsMoving == true,
		AutoAreaContacts = cloneContacts(state.AutoAreaContacts),
		GrowthLoopActive = state.GrowthLoopActive == true,
	}
end

function TrainingRuntimeState.Init(player)
	states[player] = cloneRuntimeState()
end

function TrainingRuntimeState.Remove(player)
	states[player] = nil
end

function TrainingRuntimeState.Get(player)
	local state = states[player]
	if not state then
		return nil
	end

	return cloneRuntimeState(state)
end

function TrainingRuntimeState.Set(player, nextState)
	if not nextState then
		states[player] = nil
		return
	end

	states[player] = cloneRuntimeState(nextState)
end

return TrainingRuntimeState
