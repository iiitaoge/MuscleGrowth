local HUDRender = {}

local HUD_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

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

local function getProgressRatio(value, maxValue)
	local numberValue = tonumber(value) or 0
	local numberMaxValue = tonumber(maxValue) or 0

	if numberMaxValue <= 0 then
		return 0
	end

	return math.clamp(numberValue / numberMaxValue, 0, 1)
end

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

local function setText(label, value)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function setProgressFill(fill, ratio)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.new(ratio, 0, fill.Size.Y.Scale, fill.Size.Y.Offset)
	end
end

local function createNoopView()
	return {
		Refresh = function() end,
		GetRebirthButton = function()
			return nil
		end,
	}
end

function HUDRender.Init(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild("HUD", HUD_WAIT_SECONDS)
	if not hud then
		warn("HUD ScreenGui was not found in PlayerGui. UI rendering is disabled.")
		return createNoopView()
	end

	local strengthText = waitForPath(hud, { "Friend", "Power", "Text" })
	local trophiesText = waitForPath(hud, { "Friend", "trophy", "Text" })
	local rebirthMultiplierText = waitForPath(hud, { "Bottom", "Bottom", "Rebirth", "Level" })
	local barbellMultiplierText = waitForPath(hud, { "Bottom", "Bottom", "Dumbbell", "Level" })
	local petMultiplierText = waitForPath(hud, { "Bottom", "Bottom", "Pet", "Level" })
	local expBar = waitForPath(hud, { "Bottom", "Progress", "Bar" })
	local levelText = waitForPath(hud, { "Bottom", "Progress", "Level" })
	local expText = waitForPath(hud, { "Bottom", "Progress", "Progress" })
	local rebirthButton = waitForPath(hud, { "LeftButtons", "Button", "Rebirth" })

	local view = {}

	function view.Refresh(data)
		if not data then
			setText(strengthText, "0")
			setText(trophiesText, "0")
			setText(rebirthMultiplierText, "x1.0")
			setText(barbellMultiplierText, "x1.0")
			setText(petMultiplierText, "x1.0")
			setProgressFill(expBar, 0)
			setText(levelText, "Level 1")
			setText(expText, "0/0")
			return
		end

		setText(strengthText, formatNumber(data.Strength))
		setText(trophiesText, formatNumber(data.Trophies))
		setText(rebirthMultiplierText, formatMultiplier(data.RebirthMultiplier))
		setText(barbellMultiplierText, formatMultiplier(data.BarbellMultiplier))
		setText(petMultiplierText, formatMultiplier(data.PetMultiplier))
		setProgressFill(expBar, getProgressRatio(data.Exp, data.MaxExp))
		setText(levelText, "Level " .. formatNumber(data.Level))
		setText(expText, formatNumber(data.Exp) .. "/" .. formatNumber(data.MaxExp))
	end

	function view.GetRebirthButton()
		if rebirthButton and rebirthButton:IsA("GuiButton") then
			return rebirthButton
		end

		return nil
	end

	return view
end

return HUDRender
