-- AutoAreaController
-- 客户端自动训练区输入层，只负责本地触碰绑定和 Remote 上报。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local AutoAreaTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("AutoAreaTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local AutoAreaController = {}

-- 初始化自动训练区控制器。
function AutoAreaController.Init(remoteClient, sceneQuery)
	local currentAutoAreaId = nil

	-- 重置本地自动区状态，并通知服务端离开旧区域。
	local function reset()
		if currentAutoAreaId ~= nil then
			local areaId = currentAutoAreaId
			currentAutoAreaId = nil
			remoteClient.Fire("LeaveAutoArea", areaId)
		end
	end

	-- 绑定单个自动训练区的触碰事件。
	local function bindAutoArea(areaId)
		local trainAreas = sceneQuery.GetSceneChild(SceneTheta.SceneTrainAreaRootName)
		if not trainAreas then
			warn("Missing train area root")
			return
		end

		local area = trainAreas:WaitForChild(areaId, 10)
		if not area then
			warn("Missing auto area: " .. areaId)
			return
		end

		local touch = area:WaitForChild("Touch", 10)
		if not touch or not touch:IsA("BasePart") then
			warn("Missing auto area Touch part: " .. areaId)
			return
		end

		-- 进入自动区时上报服务端。
		local function handleTouched(hit)
			if not sceneQuery.IsLocalRootPart(hit) or currentAutoAreaId == areaId then
				return
			end

			currentAutoAreaId = areaId
			remoteClient.Fire("OnAutoArea", areaId)
		end

		-- 离开当前自动区时上报服务端。
		local function handleTouchEnded(hit)
			if not sceneQuery.IsLocalRootPart(hit) or currentAutoAreaId ~= areaId then
				return
			end

			currentAutoAreaId = nil
			remoteClient.Fire("LeaveAutoArea", areaId)
		end

		touch.Touched:Connect(handleTouched)
		touch.TouchEnded:Connect(handleTouchEnded)
	end

	-- 绑定配置里的所有自动训练区。
	local function bindAll()
		for areaId, areaConfig in pairs(AutoAreaTheta) do
			if type(areaId) == "string" and type(areaConfig) == "table" then
				bindAutoArea(areaId)
			end
		end
	end

	return {
		Reset = reset,
		BindAll = bindAll,
	}
end

return AutoAreaController
