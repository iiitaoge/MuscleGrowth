-- TrainingGainAttributeController
-- 客户端训练增长视觉事件层，监听服务端发布的 Attribute 并触发飘字。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local TrainingGainAttributeController = {}

-- 初始化训练增长 Attribute 监听器。
function TrainingGainAttributeController.Init(player, floatingGainView, snapshotController)
	local lastTrainingGainSerial = tonumber(player:GetAttribute(SceneTheta.Attributes.LastTrainingGainSerial)) or 0

	-- 处理服务端发布的新训练增长序号。
	local function handleTrainingGainChanged()
		local nextSerial = tonumber(player:GetAttribute(SceneTheta.Attributes.LastTrainingGainSerial)) or 0
		if nextSerial <= lastTrainingGainSerial then
			lastTrainingGainSerial = nextSerial
			return
		end

		lastTrainingGainSerial = nextSerial
		floatingGainView.PlayStrengthGain(player:GetAttribute(SceneTheta.Attributes.LastTrainingStrengthGain))
		snapshotController.RefreshFromServer()
	end

	player:GetAttributeChangedSignal(SceneTheta.Attributes.LastTrainingGainSerial):Connect(handleTrainingGainChanged)

	return {}
end

return TrainingGainAttributeController
