-- AutoAreaDisplay/Controller
-- 编排自动区场景展示节点的异步绑定和快照刷新。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIContract = require(script.Parent.Parent.UIContract)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

function Controller.Init()
	local config = UIContract.GetConfig("AutoAreaDisplay")
	local displayNodes = {}
	local latestModels = nil

	local function bindInstance(instanceId, instanceConfig)
		local displayNode = UIRefs.ResolveAutoAreaDisplayInstance(instanceId, instanceConfig)
		if not displayNode then
			return
		end

		displayNodes[instanceId] = displayNode
		local model = latestModels and latestModels[instanceId]
		if model then
			Renderer.RenderNode(displayNode, model)
		end
	end

	for instanceId, instanceConfig in pairs(config.Instances) do
		task.spawn(bindInstance, instanceId, instanceConfig)
	end

	local function refresh(data)
		latestModels = DataAdapter.BuildModels(data)
		Renderer.RenderAvailable(displayNodes, latestModels)
	end

	return {
		Refresh = refresh,
	}
end

return Controller
