local PlayerProgressState = {}
local states = {}

local function cloneState(state)
	if type(state) ~= "table" then
		return nil
	end

	return table.clone(state)
end

function PlayerProgressState.Init(player, initialState)
	states[player] = cloneState(initialState) or {}
end

function PlayerProgressState.Remove(player)
	states[player] = nil
end

function PlayerProgressState.Get(player)
	local state = states[player]
	if not state then
		return nil
	end

	return cloneState(state)
end

function PlayerProgressState.Set(player, nextState)
	if not nextState then
		states[player] = nil
		return
	end

	states[player] = cloneState(nextState) or {}
end

return PlayerProgressState
