local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaConfig = require(ReplicatedStorage.Configs.AutoAreaConfig)

local GrowthState = {}
local states = {}

local function getState(player)
	local state = states[player]
	if not state then
		state = {
			IsMoving = false,
			AutoAreas = {},
		}
		states[player] = state
	end

	return state
end

local function canUseAutoArea(playerData, areaConfig)
	if not playerData or not areaConfig then
		return false
	end

	local requiredRebirth = areaConfig.RequiredRebirth or 0
	return playerData.RebirthCount >= requiredRebirth
end

function GrowthState.setMoving(player, isMoving)
	getState(player).IsMoving = isMoving == true
end

function GrowthState.enterAutoArea(player, areaId)
	if not AutoAreaConfig[areaId] then
		return false
	end

	getState(player).AutoAreas[areaId] = true
	return true
end

function GrowthState.leaveAutoArea(player, areaId)
	local state = getState(player)
	state.AutoAreas[areaId] = nil
end

function GrowthState.getAutoAreas(player)
	return getState(player).AutoAreas
end

function GrowthState.getActiveContext(player, playerData)
	local state = getState(player)
	local bestAreaId = nil
	local bestAreaConfig = nil
	local bestMultiplier = 1

	-- 玩家可能同时接触多个区域，最终只取已解锁区域中倍率最高的一个。
	for areaId in pairs(state.AutoAreas) do
		local areaConfig = AutoAreaConfig[areaId]
		if canUseAutoArea(playerData, areaConfig) then
			local multiplier = areaConfig.Multiplier or 1
			if not bestAreaConfig or multiplier > bestMultiplier then
				bestAreaId = areaId
				bestAreaConfig = areaConfig
				bestMultiplier = multiplier
			end
		end
	end

	return {
		IsMoving = state.IsMoving,
		AutoAreaId = bestAreaId,
		AutoAreaName = bestAreaConfig and bestAreaConfig.Name or nil,
		AutoAreaMultiplier = bestMultiplier,
		ShouldGrow = state.IsMoving or bestAreaId ~= nil,
	}
end

function GrowthState.remove(player)
	states[player] = nil
end

return GrowthState
