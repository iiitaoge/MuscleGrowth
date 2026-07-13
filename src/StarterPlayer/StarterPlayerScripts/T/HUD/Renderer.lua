-- HUD/Renderer
-- 只负责写入 HUD 文本、经验条尺寸和 Auto Win 可见状态。

local Renderer = {}

local function setText(label, value)
	label.Text = value
end

local function setProgressFill(fill, ratio)
	local size = fill.Size
	fill.Size = UDim2.new(ratio, size.X.Offset, size.Y.Scale, size.Y.Offset)
end

-- 渲染 HUD 长期数值。
function Renderer.Render(refs, model)
	setText(refs.StrengthText, model.StrengthText)
	setText(refs.TrophiesText, model.TrophiesText)
	setText(refs.RebirthMultiplierText, model.RebirthMultiplierText)
	setText(refs.BarbellMultiplierText, model.BarbellMultiplierText)
	setText(refs.PetMultiplierText, model.PetMultiplierText)
	setProgressFill(refs.ExpBar, model.ExpRatio)
	setText(refs.LevelText, model.LevelText)
	setText(refs.ExpText, model.ExpText)
	setText(refs.RebirthProgressText, model.RebirthProgressText)
end

function Renderer.GetRebirthButton(refs)
	return refs.RebirthButton
end

function Renderer.SetAutoWinEnabled(refs, isEnabled)
	local enabled = isEnabled == true
	refs.AutoWinOn.Visible = enabled
	refs.AutoWinOff.Visible = not enabled
end

function Renderer.GetAutoWinButton(refs)
	return refs.AutoWinButton
end

return Renderer
