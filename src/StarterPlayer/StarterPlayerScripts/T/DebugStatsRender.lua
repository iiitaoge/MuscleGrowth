local DebugStatsRender = {}

local function formatNumber(value)
	local numberValue = tonumber(value) or 0
	if numberValue == math.floor(numberValue) then
		return string.format("%.0f", numberValue)
	end

	return string.format("%.2f", numberValue)
end

function DebugStatsRender.Init(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugStatsGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 240, 0, 90)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "Waiting for data..."
	label.Parent = gui

	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Size = UDim2.new(0, 240, 0, 36)
	rebirthButton.Position = UDim2.new(0, 10, 0, 110)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	rebirthButton.TextColor3 = Color3.new(1, 1, 1)
	rebirthButton.Text = "Rebirth"
	rebirthButton.Parent = gui

	local view = {}

	function view.Refresh(data)
		if not data then
			label.Text = "No data"
			rebirthButton.Active = false
			rebirthButton.AutoButtonColor = false
			rebirthButton.Text = "Rebirth unavailable"
			return
		end

		label.Text = "Strength: "
			.. formatNumber(data.Strength)
			.. "\nExp: "
			.. formatNumber(data.Exp)
			.. " / "
			.. formatNumber(data.MaxExp)
			.. "\nLevel: "
			.. formatNumber(data.Level)
			.. " / "
			.. formatNumber(data.MaxLevel)
			.. "\nRebirth: "
			.. formatNumber(data.RebirthCount)

		local canRebirth = data.CanRebirth == true
		rebirthButton.Active = canRebirth
		rebirthButton.AutoButtonColor = canRebirth
		rebirthButton.Text = if canRebirth then "Rebirth" else "Reach max level first"
	end

	function view.GetRebirthButton()
		return rebirthButton
	end

	return view
end

return DebugStatsRender
