-- BarbellDisplay/Renderer
-- 只负责写入杠铃场景展示文本和可见性。

local Renderer = {}

local function renderDisplayNode(displayNode, model)
	displayNode.PowerText.Text = model.PowerText
	displayNode.CostText.Text = model.CostText
	displayNode.Locked.Visible = not model.IsUnlocked
	displayNode.Equip.Visible = model.IsUnlocked and not model.IsEquipped
	displayNode.Equipped.Visible = model.IsEquipped
end

-- 渲染所有杠铃展示状态。
function Renderer.Render(refs, models)
	for _, model in ipairs(models) do
		local displayNode = refs.DisplayNodes[model.BarbellId]
		assert(displayNode, "Missing barbell display refs for barbellId: " .. tostring(model.BarbellId))
		renderDisplayNode(displayNode, model)
	end
end

return Renderer
