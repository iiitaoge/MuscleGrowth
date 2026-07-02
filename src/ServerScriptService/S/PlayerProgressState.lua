local PlayerProgressState = {}
local states = {}

local function cloneState(state)
	if type(state) ~= "table" then
		return nil
	end

	return table.clone(state)
end

-- 初始化玩家进度状态
function PlayerProgressState.Init(player, initialState)
	states[player] = cloneState(initialState) or {}
end

-- 移除玩家进度状态
function PlayerProgressState.Remove(player)
	states[player] = nil
end

-- 获取玩家进度状态的副本
function PlayerProgressState.Get(player)
	local state = states[player]
	if not state then
		return nil
	end

	return cloneState(state)
end

-- 设置玩家进度状态
function PlayerProgressState.Set(player, nextState)
	if not nextState then	-- 如果传入的状态为 nil，则移除玩家的状态
		states[player] = nil
		return
	end

	states[player] = cloneState(nextState) or {}
end

return PlayerProgressState
