-- FloatingGain/Renderer
-- 只负责克隆模板和播放位移淡出动画。

local TweenService = game:GetService("TweenService")

local Renderer = {}

-- 基于模板位置随机偏移的偏移量
local RANDOM_OFFSET_SCALE_X = 0.18
local RANDOM_OFFSET_SCALE_Y = 0.18
local random = Random.new()

local function setText(instance, value)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		instance.Text = value
	end
end

-- 给根节点和子孙文本节点写入飘字文本。
local function setDescendantText(root, value)
	setText(root, value)
	for _, descendant in ipairs(root:GetDescendants()) do
		setText(descendant, value)
	end
end

local function getRandomStartPosition(templatePosition)
	return templatePosition
		+ UDim2.new(
			random:NextNumber(-RANDOM_OFFSET_SCALE_X, RANDOM_OFFSET_SCALE_X),
			0,
			random:NextNumber(-RANDOM_OFFSET_SCALE_Y, RANDOM_OFFSET_SCALE_Y),
			0
		)
end

local function tweenTransparency(instance, tweenInfo)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		TweenService:Create(instance, tweenInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	elseif instance:IsA("UIStroke") then
		TweenService:Create(instance, tweenInfo, {
			Transparency = 1,
		}):Play()
	elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		TweenService:Create(instance, tweenInfo, {
			ImageTransparency = 1,
		}):Play()
	end
end

-- 对文本和图片节点播放淡出动画。
local function tweenDescendantTransparency(root, tweenInfo)
	tweenTransparency(root, tweenInfo)
	for _, descendant in ipairs(root:GetDescendants()) do
		tweenTransparency(descendant, tweenInfo)
	end
end

local function destroyAfterTween(clone, tween, delaySeconds)
	tween.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed then
			return
		end

		task.delay(math.max(0, tonumber(delaySeconds) or 0), function()
			if clone.Parent then
				clone:Destroy()
			end
		end)
	end)
end

local function playGain(template, animation, text, startPosition)
	local clone = template:Clone()
	local tweenInfo = TweenInfo.new(animation.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	clone.Visible = true
	clone.Parent = template.Parent
	clone.Position = startPosition
	setDescendantText(clone, text)

	local moveTween = TweenService:Create(clone, tweenInfo, {
		Position = clone.Position + UDim2.new(0, 0, animation.OffsetScaleY, 0),
	})
	destroyAfterTween(clone, moveTween, animation.DestroyDelay)
	moveTween:Play()
	tweenDescendantTransparency(clone, tweenInfo)
end

local function getTargetPosition(clone, target)
	if not clone.Parent or not target or not target:IsA("GuiObject") then
		return nil
	end

	local targetCenter = target.AbsolutePosition + target.AbsoluteSize * 0.5
	local parentPosition = Vector2.zero
	if clone.Parent:IsA("GuiObject") then
		parentPosition = clone.Parent.AbsolutePosition
	end

	local localTopLeft = targetCenter - parentPosition - clone.AnchorPoint * clone.AbsoluteSize
	return UDim2.fromOffset(localTopLeft.X, localTopLeft.Y)
end

local function playGainToTarget(template, animation, text, startPosition, target)
	local clone = template:Clone()
	clone.Visible = true
	clone.Parent = template.Parent
	clone.Position = startPosition
	setDescendantText(clone, text)

	local floatTween = TweenService:Create(
		clone,
		TweenInfo.new(animation.FloatDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = clone.Position + UDim2.new(0, 0, animation.OffsetScaleY, 0),
		}
	)

	floatTween.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or not clone.Parent then
			return
		end

		local targetPosition = getTargetPosition(clone, target)
		if not targetPosition then
			clone:Destroy()
			return
		end

		local convergeInfo = TweenInfo.new(
			animation.ConvergeDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
		local convergeTween = TweenService:Create(clone, convergeInfo, {
			Position = targetPosition,
		})
		destroyAfterTween(clone, convergeTween, animation.DestroyDelay)
		convergeTween:Play()
		tweenDescendantTransparency(clone, convergeInfo)
	end)

	floatTween:Play()
end

-- 播放指定模板的飘字动画。
function Renderer.PlayGain(template, animation, text)
	playGain(template, animation, text, template.Position)
end

function Renderer.PlayGainInRandomArea(template, animation, text)
	playGain(template, animation, text, getRandomStartPosition(template.Position))
end

function Renderer.PlayGainInRandomAreaToTarget(template, animation, text, target)
	playGainToTarget(template, animation, text, getRandomStartPosition(template.Position), target)
end

return Renderer
