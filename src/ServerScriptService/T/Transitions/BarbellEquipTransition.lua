local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarbellTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local BarbellObservation = require(script.Parent.Parent.Parent.y.BarbellObservation)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Snapshots.PlayerSnapshotBuilder)
local BarbellWorldSync = require(script.Parent.Parent.WorldSync.BarbellWorldSync)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)

local BarbellEquipTransition = {}

-- 尝试装备杠铃，会有失败和成功两种状态
function BarbellEquipTransition.TryEquip(player, barbellId)
	-- 类型检查：判断杠铃ID是否是有效的字符串，并且在 BarbellTheta 中存在对应的配置
	if not BarbellObservation.IsValidBarbellId(barbellId) then
		return false, "Invalid barbell id"
	end

	local barbellConfig = BarbellTheta[barbellId]

	-- 检查玩家是否靠近杠铃的显示位置
	if not BarbellObservation.IsPlayerNearDisplay(player, barbellId) then
		return false, "Player is not near this barbell"
	end

	-- 检查玩家的进度状态，防止出现玩家数据不存在的情况
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	-- 获取玩家的奖杯数量，并检查是否满足装备杠铃所需的奖杯数量
	local trophies = tonumber(progressState.Trophies) or 0
	local requiredTrophies = tonumber(barbellConfig.RequiredTrophies) or 0
	if trophies < requiredTrophies then
		return false, "Not enough trophies"
	end

	if not BarbellObservation.GetTrainSource(barbellId) then
		return false, "Barbell model does not exist"
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.CurrentBarbellId = barbellId
	PlayerProgressState.Set(player, nextProgressState)
	PlayerVisualStateSync.Refresh(player)

	return true, "Barbell equipped"
end

-- 回调函数：处理装备杠铃请求
function BarbellEquipTransition.RequestEquip(player, barbellId)
	local success, message = BarbellEquipTransition.TryEquip(player, barbellId)

	return {
		Success = success,
		Message = message,
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}
end

function BarbellEquipTransition.RefreshDisplays()
	return BarbellWorldSync.RefreshDisplays(function(player, barbellId)
		BarbellEquipTransition.TryEquip(player, barbellId)
	end)
end

-- 
function BarbellEquipTransition.InitWorld()
	BarbellWorldSync.InitWorld(function(player, barbellId)
		BarbellEquipTransition.TryEquip(player, barbellId)
	end)
end

return BarbellEquipTransition
