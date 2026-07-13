-- AutoAreaDisplay/Renderer
-- 只负责写入自动区场景展示文本和可见性。

local Renderer = {}

function Renderer.RenderNode(displayNode, model)
	displayNode.PowerText.Text = model.PowerText
	displayNode.PowerText.Visible = true
	displayNode.RebirthText.Text = model.RebirthText
	displayNode.RebirthText.Visible = true
	displayNode.Locked.Visible = not model.IsUnlocked
	displayNode.Unlocked.Visible = model.IsUnlocked
end

function Renderer.RenderAvailable(displayNodes, models)
	for instanceId, displayNode in pairs(displayNodes) do
		local model = models[instanceId]
		if model then
			Renderer.RenderNode(displayNode, model)
		end
	end
end

return Renderer
