-- RebirthPanel/Refs
-- 按已验证 UI 合同解析重生面板运行时实例。

local UIContract = require(script.Parent.Parent.UIContract)

local Refs = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local function waitForRequiredChild(parent, childName, context)
	local child = parent:WaitForChild(childName, NODE_WAIT_SECONDS)
	if not child then
		error(context .. " '" .. childName .. "' was not found under " .. parent:GetFullName() .. ".", 2)
	end

	return child
end

local function waitForPath(root, path, context, optional)
	local current = root
	for _, childName in ipairs(path) do
		if optional then
			current = current and current:FindFirstChild(childName)
			if not current then
				return nil
			end
		else
			current = waitForRequiredChild(current, childName, context)
		end
	end

	return current
end

local function findFirstText(root, childName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("TextLabel") then
			return descendant
		end
	end

	return nil
end

local function requireFirstText(root, names, context)
	for _, childName in ipairs(names) do
		local textObject = findFirstText(root, childName)
		if textObject then
			return textObject
		end
	end

	error(context .. " was not found under " .. root:GetFullName() .. ".", 2)
end

local function findActionButton(root, actionButtonName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name == actionButtonName then
			return descendant
		end
	end

	error("Rebirth action button '" .. actionButtonName .. "' was not found under " .. root:GetFullName() .. ".", 2)
end

local function resolveBindingTarget(refs, binding)
	if binding.Ref then
		local target = refs[binding.Ref]
		assert(target, "Missing Rebirth render binding ref: " .. binding.Ref)
		return target
	end

	if binding.Path then
		return waitForPath(refs.PanelRoot, binding.Path, "Rebirth render binding " .. binding.Key, binding.Optional == true)
	end

	if binding.RootPath then
		return waitForPath(refs.PanelRoot, binding.RootPath, "Rebirth render binding " .. binding.Key, binding.Optional == true)
	end

	return refs.PanelRoot
end

local function resolveRenderBindings(refs, bindings)
	local resolvedBindings = {}
	for index, binding in ipairs(bindings) do
		local target = resolveBindingTarget(refs, binding)
		if target or binding.Optional == true then
			resolvedBindings[index] = {
				Config = binding,
				Target = target,
			}
		else
			error("Missing Rebirth render binding target: " .. binding.Key, 2)
		end
	end

	return resolvedBindings
end

function Refs.Resolve(player)
	local config = UIContract.GetConfig("RebirthPanel")
	local playerGui = player:WaitForChild("PlayerGui", GUI_WAIT_SECONDS)
	if not playerGui then
		error("PlayerGui was not found under " .. player:GetFullName() .. ".", 2)
	end

	local mainGui = playerGui:WaitForChild(config.ScreenGuiName, GUI_WAIT_SECONDS)
	if not mainGui then
		error("Rebirth ScreenGui '" .. config.ScreenGuiName .. "' was not found under " .. playerGui:GetFullName() .. ".", 2)
	end
	assert(mainGui:IsA("ScreenGui"), "Rebirth ScreenGui '" .. config.ScreenGuiName .. "' must be a ScreenGui.")

	local panelRoot = waitForPath(mainGui, config.Paths.PanelRoot, "Rebirth PanelRoot")
	assert(panelRoot:IsA("GuiObject"), "Rebirth PanelRoot must be a GuiObject.")

	local nodes = config.Nodes
	local refs = {
		PanelRoot = panelRoot,
		CloseButton = findActionButton(panelRoot, nodes.CloseButtonName),
		RequestButton = findActionButton(panelRoot, nodes.ActionButtonName),
		TitleText = requireFirstText(panelRoot, { nodes.TitleTextName }, "Rebirth title text"),
		TipText = requireFirstText(panelRoot, { nodes.TipTextName, nodes.FallbackTipTextName }, "Rebirth tip text"),
	}
	refs.RenderBindings = resolveRenderBindings(refs, config.RenderBindings)

	return refs
end

return Refs
