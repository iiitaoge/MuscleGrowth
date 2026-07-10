-- RebirthPanel/Renderer
-- 只负责写入重生面板文本和切换可见性。

local ButtonMotion = require(script.Parent.Parent.ButtonMotion)

local Renderer = {}

local function isTextObject(instance)
	return instance
		and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"))
end

local function setText(label, value)
	label.Text = value
end

local function setSizeXScale(guiObject, value)
	local ratio = math.clamp(tonumber(value) or 0, 0, 1)
	local size = guiObject.Size
	guiObject.Size = UDim2.new(ratio, size.X.Offset, size.Y.Scale, size.Y.Offset)
end

local function setTextTargets(targets, values)
	for index, target in ipairs(targets or {}) do
		if isTextObject(target) then
			target.Text = values[index] or values[#values] or target.Text
		end
	end
end

local function normalizeSequenceValues(values)
	if type(values) == "table" then
		return values
	end

	if values == nil then
		return {}
	end

	return { tostring(values) }
end

local function applyRenderBinding(bindingEntry, model)
	local binding = bindingEntry.Config
	local target = bindingEntry.Target
	if not target and binding.Operation ~= "SetTextTargets" then
		return
	end

	local value = model[binding.ModelKey]
	if binding.Operation == "SetText" then
		setText(target, value or "")
	elseif binding.Operation == "SetTextTargets" then
		setTextTargets(bindingEntry.Targets, normalizeSequenceValues(value))
	elseif binding.Operation == "SetSizeXScale" then
		setSizeXScale(target, value)
	end
end

function Renderer.ConnectActivated(root, callback)
	ButtonMotion.Bind(root)
	root.Activated:Connect(callback)
end

function Renderer.SetOpen(refs, isOpen)
	refs.PanelRoot.Visible = isOpen == true
end

function Renderer.IsOpen(refs)
	return refs.PanelRoot.Visible == true
end

function Renderer.Render(refs, model)
	for _, bindingEntry in ipairs(refs.RenderBindings) do
		applyRenderBinding(bindingEntry, model)
	end
end

return Renderer
