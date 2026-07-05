-- FloatingGain/Renderer
-- 只负责查找飘字模板、克隆模板和播放位移淡出动画。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local theta = ReplicatedStorage:WaitForChild("theta")
local FloatingGainTheta = require(theta:WaitForChild("FloatingGainTheta"))

local Renderer = {}

local HUD_WAIT_SECONDS = 10

-- 给根节点和子孙文本节点写入飘字文本。
local function setDescendantText(root, value)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			descendant.Text = value
		end
	end
end

-- 对文本和图片子孙节点播放淡出动画。
local function tweenDescendantTransparency(root, duration)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			TweenService:Create(descendant, TweenInfo.new(duration), {
				TextTransparency = 1,
			}):Play()
		elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			TweenService:Create(descendant, TweenInfo.new(duration), {
				ImageTransparency = 1,
			}):Play()
		end
	end
end

-- 解析训练和奖杯飘字模板。
function Renderer.Resolve(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild(FloatingGainTheta.ScreenGuiName or "HUD", HUD_WAIT_SECONDS)
	if not hud then
		warn("Floating gain HUD ScreenGui was not found.")
		return nil
	end

	local templates = FloatingGainTheta.Templates or {}
	local strengthTemplate = hud:FindFirstChild(templates.StrengthGain or "+1")
	local trophyTemplate = hud:FindFirstChild(templates.TrophyGain or "+1trophy")

	if strengthTemplate and strengthTemplate:IsA("GuiObject") then
		strengthTemplate.Visible = false
	end

	if trophyTemplate and trophyTemplate:IsA("GuiObject") then
		trophyTemplate.Visible = false
	end

	return {
		StrengthTemplate = strengthTemplate,
		TrophyTemplate = trophyTemplate,
		Animation = FloatingGainTheta.Animation or {},
	}
end

-- 播放指定模板的飘字动画。
function Renderer.PlayGain(template, animationConfig, model)
	if not template or not template:IsA("GuiObject") or not model then
		return
	end

	local duration = tonumber(animationConfig.Duration) or 0.65
	local destroyDelay = tonumber(animationConfig.DestroyDelay) or 0.75
	local offsetScaleY = tonumber(animationConfig.OffsetScaleY) or -0.08
	local clone = template:Clone()

	clone.Visible = true
	clone.Parent = template.Parent
	clone.Position = template.Position
	setDescendantText(clone, model.Text)

	TweenService:Create(clone, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = clone.Position + UDim2.new(0, 0, offsetScaleY, 0),
	}):Play()
	tweenDescendantTransparency(clone, duration)

	-- 动画结束后清理克隆出来的飘字节点。
	task.delay(destroyDelay, function()
		if clone then
			clone:Destroy()
		end
	end)
end

return Renderer
