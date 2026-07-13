-- AutoWinActionController
-- 客户端只请求开关状态；服务端 Attribute 是 UI 的唯一事实来源。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneTheta = require(
	ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta")
)

local AutoWinActionController = {}

function AutoWinActionController.Init(player, snapshotController, hudView)
	local attributeName = SceneTheta.Attributes.IsAutoWinEnabled
	local requestInFlight = false

	local function syncView()
		hudView.SetAutoWinEnabled(player:GetAttribute(attributeName) == true)
	end

	player:GetAttributeChangedSignal(attributeName):Connect(syncView)
	hudView.GetAutoWinButton().Activated:Connect(function()
		if requestInFlight then
			return
		end

		requestInFlight = true
		local requestedEnabled = player:GetAttribute(attributeName) ~= true
		snapshotController.InvokeAction("RequestSetAutoWin", requestedEnabled)
		requestInFlight = false
		syncView()
	end)

	syncView()
end

return AutoWinActionController
