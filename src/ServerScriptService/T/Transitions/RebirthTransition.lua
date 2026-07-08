local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local TransitionResult = require(script.Parent.TransitionResult)

local RebirthTransition = {}

function RebirthTransition.TryApply(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	-- 检查是否可以重生
	if not LevelRules.CanRebirth(progressState) then
		return false, "Current max level has not been reached"
	end

	-- 获取进度数据，进行重生配置：重生次数加一。等级和经验归0
	local nextProgressState = table.clone(progressState)
	nextProgressState.RebirthCount += 1
	nextProgressState.Strength = 0
	nextProgressState.Exp = 0

	PlayerProgressState.Set(player, nextProgressState)

	return true, "Rebirth succeeded"
end

-- 失败输出失败，成功输出成功，并返回当前玩家数据快照
function RebirthTransition.Request(player)
	local success, message = RebirthTransition.TryApply(player)

	return TransitionResult.WithSnapshot(player, success, message)
end

return RebirthTransition
