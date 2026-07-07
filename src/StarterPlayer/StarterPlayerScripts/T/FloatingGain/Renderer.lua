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

local function playGain(template, animation, text, startPosition)
	local clone = template:Clone()
	local tweenInfo = TweenInfo.new(animation.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	clone.Visible = true
	clone.Parent = template.Parent
	clone.Position = startPosition
	setDescendantText(clone, text)

	TweenService:Create(clone, tweenInfo, {
		Position = clone.Position + UDim2.new(0, 0, animation.OffsetScaleY, 0),
	}):Play()
	tweenDescendantTransparency(clone, tweenInfo)

	-- 动画结束后清理克隆出来的飘字节点。
	task.delay(animation.DestroyDelay, function()
		clone:Destroy()
	end)
end

-- 播放指定模板的飘字动画。
function Renderer.PlayGain(template, animation, text)
	playGain(template, animation, text, template.Position)
end

function Renderer.PlayGainInRandomArea(template, animation, text)
	playGain(template, animation, text, getRandomStartPosition(template.Position))
end

return Renderer
