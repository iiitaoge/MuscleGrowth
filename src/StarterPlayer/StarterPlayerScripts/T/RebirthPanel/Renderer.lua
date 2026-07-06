-- RebirthPanel/Renderer
-- 只负责查找重生面板节点、写入文本和切换可见性。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local RebirthPanelTheta = require(theta:WaitForChild("RebirthPanelTheta"))

local Renderer = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

-- 按路径等待 UI 节点。
local function waitForPath(root, path)
	if type(path) ~= "table" then
		warn("Missing Rebirth UI path config.")
		return nil
	end

	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
	end

	return current
end

-- 按名字查找第一个 TextLabel。
local function findFirstText(root, childName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("TextLabel") then
			return descendant
		end
	end

	return nil
end

-- 查找重生请求按钮。
local function findActionButton(root, actionButtonName)
	if not root then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name == actionButtonName then
			return descendant
		end
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name ~= "Close" then
			return descendant
		end
	end

	return nil
end

-- 判断实例是否能写 Text。
local function isTextObject(instance)
	return instance and (instance:IsA("TextLabel") or instance:IsA("TextButton"))
end

-- 给文本节点写入文本。
local function setText(label, value)
	if isTextObject(label) then
		label.Text = value
	end
end

-- 给根节点及子孙文本节点批量写文本。
local function setDescendantTexts(root, value)
	if not root then
		return
	end

	if isTextObject(root) then
		root.Text = value
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if isTextObject(descendant) then
			descendant.Text = value
		end
	end
end

-- 按谓词顺序替换文本序列。
local function setTextSequenceByPredicate(root, predicate, values)
	local valueIndex = 1
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if isTextObject(descendant) and predicate(descendant.Text, descendant) then
			descendant.Text = values[valueIndex] or values[#values] or descendant.Text
			valueIndex += 1
			if valueIndex > #values then
				break
			end
		end
	end
end

-- 解析重生面板 UI 引用。
function Renderer.Resolve(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild(RebirthPanelTheta.ScreenGuiName or "Main", GUI_WAIT_SECONDS)
	if not mainGui then
		return nil
	end

	local paths = RebirthPanelTheta.Paths or {}
	local nodes = RebirthPanelTheta.Nodes or {}
	local panelRoot = waitForPath(mainGui, paths.PanelRoot)
	if not panelRoot then
		return nil
	end

	return {
		PanelRoot = panelRoot,
		CloseButton = panelRoot:FindFirstChild(nodes.CloseButtonName or "Close", true),
		RequestButton = findActionButton(panelRoot, nodes.ActionButtonName or "Rebirth"),
		TitleText = findFirstText(panelRoot, nodes.TitleTextName or "Title"),
		TipText = findFirstText(panelRoot, nodes.TipTextName or "Tip")
			or findFirstText(panelRoot, nodes.FallbackTipTextName or "TextLabel"),
	}
end

-- 给按钮绑定 Activated 事件。
function Renderer.ConnectActivated(root, callback)
	if root and root:IsA("GuiButton") and callback then
		root.Activated:Connect(callback)
	end
end

-- 切换重生面板开关。
function Renderer.SetOpen(refs, isOpen)
	if refs and refs.PanelRoot and refs.PanelRoot:IsA("GuiObject") then
		refs.PanelRoot.Visible = isOpen == true
	end
end

-- 判断重生面板是否打开。
function Renderer.IsOpen(refs)
	return refs and refs.PanelRoot and refs.PanelRoot.Visible == true
end

-- 渲染重生面板内容。
function Renderer.Render(refs, model)
	if not refs or not model then
		return
	end

	setText(refs.TitleText, model.TitleText)
	setText(refs.TipText, model.TipText)
	setTextSequenceByPredicate(refs.PanelRoot, function(text)
		return type(text) == "string" and text:match("^%{%d+%}$") ~= nil
	end, model.RebirthTexts or {})
	setTextSequenceByPredicate(refs.PanelRoot, function(text)
		return type(text) == "string" and text:find("Power", 1, true) ~= nil
	end, model.PowerTexts or {})
	setTextSequenceByPredicate(refs.PanelRoot, function(text)
		return type(text) == "string" and text:find("Max Level", 1, true) ~= nil
	end, model.MaxLevelTexts or {})
	setDescendantTexts(refs.RequestButton, model.RequestText or "")
end

return Renderer
