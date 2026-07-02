local TrainingRuntimeState = {}
local states = {}

local function cloneState(state)
	if type(state) ~= "table" then
		return nil
	end

	local copy = {}

	for key, value in pairs(state) do
		if type(value) == "table" then
			copy[key] = table.clone(value)
		else
			copy[key] = value
		end
	end

	return copy
end

function TrainingRuntimeState.Init(player, initialState)
	states[player] = cloneState(initialState) or {}
end

function TrainingRuntimeState.Remove(player)
	states[player] = nil
end

function TrainingRuntimeState.Get(player)
	local state = states[player]
	if not state then
		return nil
	end

	return cloneState(state)
end

function TrainingRuntimeState.Set(player, nextState)
	if not nextState then
		states[player] = nil
		return
	end

	states[player] = cloneState(nextState) or {}
end

return TrainingRuntimeState
