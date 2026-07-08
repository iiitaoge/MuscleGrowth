local TrainingRuntimeState = {}
local states = {}

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in pairs(value) do
		copy[cloneValue(key)] = cloneValue(childValue)
	end

	return copy
end

local function cloneState(state)
	if type(state) ~= "table" then
		return nil
	end

	return cloneValue(state)
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

-- TrainingRuntimeState暴露给外界的写入函数
function TrainingRuntimeState.Set(player, nextState)
	if not nextState then
		states[player] = nil
		return
	end

	states[player] = cloneState(nextState) or {}
end

return TrainingRuntimeState
