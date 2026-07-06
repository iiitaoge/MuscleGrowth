-- RebirthPanel/Renderer
-- 只负责查找重生面板节点、写入文本和切换可见性。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local RebirthPanelTheta = require(theta:WaitForChild("RebirthPanelTheta"))

local Renderer = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local setTextSequenceByPredicate

-- 按路径查找或等待 UI 节点。
local function waitForPath(root, path, optional)
	if type(path) ~= "table" then
		warn("Missing Rebirth UI path config.")
		return nil
	end

	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		if optional then
			current = current:FindFirstChild(childName)
		else
			current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
		end
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

-- 设置 GuiObject 的 Size.X.Scale，并保留 Offset 和 Y。
local function setSizeXScale(guiObject, value)
	if not (guiObject and guiObject:IsA("GuiObject")) then
		return
	end

	local ratio = math.clamp(tonumber(value) or 0, 0, 1)
	local size = guiObject.Size
	guiObject.Size = UDim2.new(ratio, size.X.Offset, size.Y.Scale, size.Y.Offset)
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

-- 规范化序列文本。
local function normalizeSequenceValues(values)
	if type(values) == "table" then
		return values
	end

	if values == nil then
		return {}
	end

	return { tostring(values) }
end

-- 判断文本是否匹配 theta 中声明的规则。
local function textMatches(matchConfig, text)
	if type(matchConfig) ~= "table" or type(text) ~= "string" then
		return false
	end

	if matchConfig.MatchType == "Pattern" and type(matchConfig.Pattern) == "string" then
		return text:match(matchConfig.Pattern) ~= nil
	end

	if matchConfig.MatchType == "Contains" and type(matchConfig.Contains) == "string" then
		return text:find(matchConfig.Contains, 1, true) ~= nil
	end

	return false
end

-- 根据渲染绑定解析目标节点。
local function resolveBindingTarget(refs, binding)
	if binding.Ref then
		return refs[binding.Ref]
	end

	if binding.Path then
		return waitForPath(refs.PanelRoot, binding.Path, binding.Optional == true)
	end

	if binding.RootPath then
		return waitForPath(refs.PanelRoot, binding.RootPath, binding.Optional == true)
	end

	return refs.PanelRoot
end

-- 解析 theta 中声明的渲染绑定。
local function resolveRenderBindings(refs)
	local resolvedBindings = {}

	for _, binding in ipairs(RebirthPanelTheta.RenderBindings or {}) do
		if type(binding) == "table" then
			local target = resolveBindingTarget(refs, binding)
			if target or binding.Optional == true then
				table.insert(resolvedBindings, {
					Config = binding,
					Target = target,
				})
			else
				warn("Missing Rebirth render binding target: " .. tostring(binding.Key or binding.ModelKey))
			end
		end
	end

	return resolvedBindings
end

-- 执行单个渲染绑定。
local function applyRenderBinding(bindingEntry, model)
	local binding = bindingEntry.Config
	local target = bindingEntry.Target
	if not binding or not target then
		return
	end

	local value = model[binding.ModelKey]
	if binding.Operation == "SetText" then
		setText(target, value or "")
	elseif binding.Operation == "SetDescendantTexts" then
		setDescendantTexts(target, value or "")
	elseif binding.Operation == "SetTextSequenceByMatch" then
		setTextSequenceByPredicate(target, function(text)
			return textMatches(binding.Match, text)
		end, normalizeSequenceValues(value))
	elseif binding.Operation == "SetSizeXScale" then
		setSizeXScale(target, value)
	end
end

-- 按谓词顺序替换文本序列。
setTextSequenceByPredicate = function(root, predicate, values)
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

	local refs = {
		PanelRoot = panelRoot,
		CloseButton = panelRoot:FindFirstChild(nodes.CloseButtonName or "Close", true),
		RequestButton = findActionButton(panelRoot, nodes.ActionButtonName or "Rebirth"),
		TitleText = findFirstText(panelRoot, nodes.TitleTextName or "Title"),
		TipText = findFirstText(panelRoot, nodes.TipTextName or "Tip")
			or findFirstText(panelRoot, nodes.FallbackTipTextName or "TextLabel"),
	}
	refs.RenderBindings = resolveRenderBindings(refs)

	return refs
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

	for _, bindingEntry in ipairs(refs.RenderBindings or {}) do
		applyRenderBinding(bindingEntry, model)
	end
end

return Renderer
