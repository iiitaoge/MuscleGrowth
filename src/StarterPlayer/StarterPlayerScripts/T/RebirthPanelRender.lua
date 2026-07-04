local RebirthPanelRender = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local function waitForPath(root, path)
	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
	end

	return current
end

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

local function findFirstText(root, childName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("TextLabel") then
			return descendant
		end
	end

	return nil
end

local function findActionButton(root)
	local namedButton = root and root:FindFirstChild("Rebirth", true)
	if namedButton and namedButton:IsA("GuiButton") then
		return namedButton
	end

	return root and root:FindFirstChildWhichIsA("GuiButton", true)
end

local function setText(label, value)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function createNoopView()
	return {
		Refresh = function() end,
		SetOpen = function() end,
		SetRequestHandler = function() end,
	}
end

function RebirthPanelRender.Init(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("Main", GUI_WAIT_SECONDS)
	if not mainGui then
		return createNoopView()
	end

	local rebirthScreen = waitForPath(mainGui, { "Rebirth" })
	if not rebirthScreen then
		return createNoopView()
	end

	local closeButton = rebirthScreen:FindFirstChild("Close", true)
	local requestButton = findActionButton(rebirthScreen)
	local titleText = findFirstText(rebirthScreen, "Title")
	local tipText = findFirstText(rebirthScreen, "Tip") or findFirstText(rebirthScreen, "TextLabel")
	local requestHandler = nil
	local latestData = nil

	rebirthScreen.Visible = false

	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			rebirthScreen.Visible = false
		end)
	end

	if requestButton then
		requestButton.Activated:Connect(function()
			if requestHandler then
				requestHandler()
			end
		end)
	end

	local view = {}

	function view.Refresh(data)
		latestData = data

		if not data then
			setText(titleText, "Rebirth")
			setText(tipText, "")
			return
		end

		setText(titleText, "Rebirth " .. formatMultiplier(data.RebirthMultiplier))
		if data.CanRebirth then
			setText(tipText, "Ready at Level " .. formatNumber(data.Level))
		else
			setText(tipText, "Level " .. formatNumber(data.Level) .. "/" .. formatNumber(data.MaxLevel))
		end
	end

	function view.SetOpen(isOpen)
		rebirthScreen.Visible = isOpen == true
		if rebirthScreen.Visible then
			view.Refresh(latestData)
		end
	end

	function view.SetRequestHandler(handler)
		requestHandler = handler
	end

	return view
end

return RebirthPanelRender
