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
	if not root then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name == "Rebirth" then
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

local function isTextObject(instance)
	return instance and (instance:IsA("TextLabel") or instance:IsA("TextButton"))
end

local function setText(label, value)
	if isTextObject(label) then
		label.Text = value
	end
end

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

local function refreshStatTexts(rebirthScreen, requestButton, data)
	local currentRebirthCount = tonumber(data.RebirthCount) or 0
	local nextRebirthCount = tonumber(data.NextRebirthCount) or currentRebirthCount + 1
	local currentMaxLevel = tonumber(data.MaxLevel) or 1
	local nextMaxLevel = tonumber(data.NextMaxLevel) or currentMaxLevel
	local currentMultiplier = tonumber(data.RebirthMultiplier) or 1
	local nextMultiplier = tonumber(data.NextRebirthMultiplier) or currentMultiplier

	setTextSequenceByPredicate(rebirthScreen, function(text)
		return type(text) == "string" and text:match("^%{%d+%}$") ~= nil
	end, {
		"{" .. formatNumber(currentRebirthCount) .. "}",
		"{" .. formatNumber(nextRebirthCount) .. "}",
	})

	setTextSequenceByPredicate(rebirthScreen, function(text)
		return type(text) == "string" and text:find("Power", 1, true) ~= nil
	end, {
		formatMultiplier(currentMultiplier) .. " Power",
		formatMultiplier(nextMultiplier) .. " Power",
	})

	setTextSequenceByPredicate(rebirthScreen, function(text)
		return type(text) == "string" and text:find("Max Level", 1, true) ~= nil
	end, {
		"Max Level " .. formatNumber(currentMaxLevel),
		"Max Level " .. formatNumber(nextMaxLevel),
	})

	setDescendantTexts(requestButton, "Rebirth " .. formatMultiplier(nextMultiplier))
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
		refreshStatTexts(rebirthScreen, requestButton, data)
		if data.CanRebirth then
			setText(tipText, "Ready at Level " .. formatNumber(data.Level))
		else
			setText(
				tipText,
				"Level " .. formatNumber(data.Level)
					.. "/" .. formatNumber(data.MaxLevel)
					.. "  Exp "
					.. formatNumber(data.Exp)
					.. "/"
					.. formatNumber(data.MaxExp)
			)
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
