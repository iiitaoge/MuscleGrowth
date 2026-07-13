local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PlayerProgressRules = require(script.Parent.Parent.Rules.PlayerProgressRules)
local TrainingTransition = require(script.Parent.TrainingTransition)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)

local PlayerLifecycleTransition = {}

-- 只接受已经加载成功的长期状态；加载失败不能隐式回退到初始数据。
function PlayerLifecycleTransition.Init(player, progressState)
	local normalizedState = PlayerProgressRules.NormalizePersistedState(progressState)
	assert(normalizedState, "Player progress state must be loaded before lifecycle initialization.")

	PlayerProgressState.Init(player, normalizedState)
	TrainingTransition.InitRuntime(player)	--运行时的初始化
	PlayerVisualStateSync.Refresh(player)
	PlayerVisualStateSync.SetTrainingActive(player, false)
	PlayerVisualStateSync.SetPushBallActive(player, false, "")
end

function PlayerLifecycleTransition.Remove(player)
	TrainingTransition.RemoveRuntime(player)
	PlayerProgressState.Remove(player)
	PlayerVisualStateSync.Clear(player)
end

return PlayerLifecycleTransition
