-- AutoAreaController
-- Binds every configured auto-area scene instance and reports the shared AreaId.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local AutoAreaTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("AutoAreaTheta"))
local AutoAreaSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("AutoAreaSceneTheta"))

local AutoAreaController = {}
local BIND_WAIT_SECONDS = 30

function AutoAreaController.Init(remoteClient, sceneQuery)
	local currentAutoAreaId = nil

	local function waitForPath(root, path, timeout)
		if not root or type(path) ~= "table" then
			return nil
		end

		local current = root
		for _, childName in ipairs(path) do
			if type(childName) ~= "string" or childName == "" then
				return nil
			end

			current = current:WaitForChild(childName, timeout or 10)
			if not current then
				return nil
			end
		end

		return current
	end

	-- 重置本地自动区状态，并通知服务端离开旧区域。
	local function reset()
		if currentAutoAreaId ~= nil then
			local areaId = currentAutoAreaId
			currentAutoAreaId = nil
			remoteClient.Fire("LeaveAutoArea", areaId)
		end
	end

	local function bindAutoAreaInstance(instanceId, instanceConfig)
		if type(instanceConfig) ~= "table" then
			warn("Missing auto area scene instance config: " .. tostring(instanceId))
			return
		end

		local areaId = instanceConfig.AreaId
		if type(areaId) ~= "string" or type(AutoAreaTheta[areaId]) ~= "table" then
			warn("Invalid auto area scene instance AreaId: " .. tostring(instanceId))
			return
		end

		local touch = waitForPath(Workspace, instanceConfig.TouchPath, BIND_WAIT_SECONDS)
		if not touch or not touch:IsA("BasePart") then
			warn("Missing auto area Touch part: " .. tostring(instanceId))
			return
		end

		touch.Touched:Connect(function(hit)
			if not sceneQuery.IsLocalRootPart(hit) or currentAutoAreaId == areaId then
				return
			end

			currentAutoAreaId = areaId
			remoteClient.Fire("OnAutoArea", areaId)
		end)

		touch.TouchEnded:Connect(function(hit)
			if not sceneQuery.IsLocalRootPart(hit) or currentAutoAreaId ~= areaId then
				return
			end

			currentAutoAreaId = nil
			remoteClient.Fire("LeaveAutoArea", areaId)
		end)
	end

	local function bindAll()
		for instanceId, instanceConfig in pairs(AutoAreaSceneTheta.Instances or {}) do
			task.spawn(bindAutoAreaInstance, instanceId, instanceConfig)
		end
	end

	return {
		Reset = reset,
		BindAll = bindAll,
	}
end

return AutoAreaController
