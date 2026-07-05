-- HUD/Renderer
-- 只负责查找 HUD 节点和写入文本、经验条尺寸。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local HUDPanelTheta = require(theta:WaitForChild("HUDPanelTheta"))

local Renderer = {}

local HUD_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

-- 按路径等待 HUD 节点。
local function waitForPath(root, path)
	local current = root

	for _, childName in ipairs(path) do
		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
		if not current then
			warn("Missing HUD node: " .. table.concat(path, "/"))
			return nil
		end
	end

	return current
end

-- 给 TextLabel 写入文本。
local function setText(label, value)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

-- 设置经验条填充比例。
local function setProgressFill(fill, ratio)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.new(ratio, 0, fill.Size.Y.Scale, fill.Size.Y.Offset)
	end
end

-- 解析 HUD 所需的所有 UI 引用。
function Renderer.Resolve(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild(HUDPanelTheta.ScreenGuiName or "HUD", HUD_WAIT_SECONDS)
	if not hud then
		warn("HUD ScreenGui was not found in PlayerGui. UI rendering is disabled.")
		return nil
	end

	local paths = HUDPanelTheta.Paths or {}
	return {
		StrengthText = waitForPath(hud, paths.StrengthText or { "Friend", "Power", "Text" }),
		TrophiesText = waitForPath(hud, paths.TrophiesText or { "Friend", "trophy", "Text" }),
		RebirthMultiplierText = waitForPath(hud, paths.RebirthMultiplierText or { "Bottom", "Bottom", "Rebirth", "Level" }),
		BarbellMultiplierText = waitForPath(hud, paths.BarbellMultiplierText or { "Bottom", "Bottom", "Dumbbell", "Level" }),
		PetMultiplierText = waitForPath(hud, paths.PetMultiplierText or { "Bottom", "Bottom", "Pet", "Level" }),
		ExpBar = waitForPath(hud, paths.ExpBar or { "Bottom", "Progress", "Bar" }),
		LevelText = waitForPath(hud, paths.LevelText or { "Bottom", "Progress", "Level" }),
		ExpText = waitForPath(hud, paths.ExpText or { "Bottom", "Progress", "Progress" }),
		RebirthButton = waitForPath(hud, paths.RebirthButton or { "LeftButtons", "Button", "Rebirth" }),
	}
end

-- 渲染 HUD 长期数值。
function Renderer.Render(refs, model)
	if not refs or not model then
		return
	end

	setText(refs.StrengthText, model.StrengthText)
	setText(refs.TrophiesText, model.TrophiesText)
	setText(refs.RebirthMultiplierText, model.RebirthMultiplierText)
	setText(refs.BarbellMultiplierText, model.BarbellMultiplierText)
	setText(refs.PetMultiplierText, model.PetMultiplierText)
	setProgressFill(refs.ExpBar, model.ExpRatio or 0)
	setText(refs.LevelText, model.LevelText)
	setText(refs.ExpText, model.ExpText)
end

-- 返回可绑定的重生入口按钮。
function Renderer.GetRebirthButton(refs)
	if refs and refs.RebirthButton and refs.RebirthButton:IsA("GuiButton") then
		return refs.RebirthButton
	end

	return nil
end

return Renderer
