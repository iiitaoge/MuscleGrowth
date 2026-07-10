local TweenService = game:GetService("TweenService")

local ButtonMotion = {}

local BOUND_ATTRIBUTE = "MuscleGrowthButtonMotionBound"
local SCALE_NAME = "UIScale"	-- 查找的UIScale的节点名称

local NORMAL_SCALE = 1
local HOVER_SCALE = 1.06
local PRESS_SCALE = 0.94

local HOVER_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getOrCreateScale(visualTarget)
	local scale = visualTarget:FindFirstChild(SCALE_NAME)
	if scale and not scale:IsA("UIScale") then
		scale:Destroy()
		scale = nil
	end

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = SCALE_NAME
		scale.Scale = NORMAL_SCALE
		scale.Parent = visualTarget
	end

	return scale
end

function ButtonMotion.Bind(inputTarget, visualTarget)
	if not inputTarget or not inputTarget:IsA("GuiButton") then
		return nil
	end

	visualTarget = visualTarget or inputTarget
	if not visualTarget:IsA("GuiObject") then
		return nil
	end

	if inputTarget:GetAttribute(BOUND_ATTRIBUTE) then
		return inputTarget
	end
	inputTarget:SetAttribute(BOUND_ATTRIBUTE, true)

	local scale = getOrCreateScale(visualTarget)
	local isHovering = false
	local isPressing = false
	local activeTween = nil

	local function tweenTo(nextScale, tweenInfo)
		if activeTween then
			activeTween:Cancel()
		end

		activeTween = TweenService:Create(scale, tweenInfo or HOVER_TWEEN, {
			Scale = nextScale,
		})
		activeTween:Play()
	end

	local function refreshScale()
		if isPressing then
			tweenTo(PRESS_SCALE, PRESS_TWEEN)
		elseif isHovering then
			tweenTo(HOVER_SCALE, HOVER_TWEEN)
		else
			tweenTo(NORMAL_SCALE, HOVER_TWEEN)
		end
	end

	inputTarget.MouseEnter:Connect(function()
		isHovering = true
		refreshScale()
	end)

	inputTarget.MouseLeave:Connect(function()
		isHovering = false
		isPressing = false
		refreshScale()
	end)

	inputTarget.MouseButton1Down:Connect(function()
		isPressing = true
		refreshScale()
	end)

	inputTarget.MouseButton1Up:Connect(function()
		isPressing = false
		refreshScale()
	end)

	inputTarget.Activated:Connect(function()
		isPressing = false
		if isHovering then
			refreshScale()
			return
		end

		tweenTo(PRESS_SCALE, PRESS_TWEEN)
		task.delay(0.08, function()
			if inputTarget.Parent and scale.Parent then
				refreshScale()
			end
		end)
	end)

	return inputTarget
end

return ButtonMotion
