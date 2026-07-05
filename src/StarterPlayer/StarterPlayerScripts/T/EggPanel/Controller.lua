-- EggPanel/Controller
-- 编排蛋面板打开关闭、按钮事件和键盘快捷键。

local UserInputService = game:GetService("UserInputService")

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 空视图里使用的无操作函数。
local function noop() end

-- 空视图里使用的 false 返回函数。
local function returnFalse()
	return false
end

-- 空视图里使用的 nil 返回函数。
local function returnNil()
	return nil
end

-- 构造 UI 不可用时的空视图。
local function createNoopView()
	return {
		Open = noop,
		Close = noop,
		Refresh = noop,
		SetRollHandler = noop,
		SetAutoRolling = noop,
		ShowRollResults = noop,
		ShowAutoSummary = noop,
		IsOpen = returnFalse,
		GetCurrentEggId = returnNil,
	}
end

-- 初始化蛋面板控制器。
function Controller.Init(player)
	local refs = Renderer.Resolve(player)
	if not refs then
		return createNoopView()
	end

	local currentEggId = nil
	local latestData = nil
	local rollHandler = nil
	local isAutoRolling = false

	-- 判断面板是否打开。
	local function isOpen()
		return Renderer.IsOpen(refs)
	end

	-- 按当前状态刷新蛋面板。
	local function renderEgg()
		local eggModel = DataAdapter.BuildEggModel(currentEggId, isAutoRolling)
		Renderer.RenderEgg(refs, eggModel)
	end

	-- 触发外部抽奖请求处理器。
	local function requestRoll(rollCount, isAuto)
		if rollHandler and currentEggId then
			rollHandler(currentEggId, rollCount, isAuto == true)
		end
	end

	-- 打开指定蛋面板。
	local function open(eggId, data)
		currentEggId = eggId
		latestData = data or latestData
		Renderer.SetOpen(refs, true)
		Renderer.ClearResult(refs)
		renderEgg()
	end

	-- 关闭蛋面板并停止自动抽状态。
	local function close()
		Renderer.SetOpen(refs, false)
		isAutoRolling = false
		Renderer.ClearResult(refs)
	end

	-- 按最新快照刷新蛋面板。
	local function refresh(data)
		latestData = data
		if isOpen() then
			renderEgg()
		end
	end

	-- 注册外部抽奖请求处理器。
	local function setRollHandler(handler)
		rollHandler = handler
	end

	-- 设置自动抽按钮展示状态。
	local function setAutoRolling(nextIsAutoRolling)
		isAutoRolling = nextIsAutoRolling == true
		renderEgg()
	end

	-- 展示抽奖结果。
	local function showRollResults(rollResults, message)
		if not isOpen() then
			return
		end

		Renderer.RenderResult(refs, DataAdapter.BuildRollResultModel(rollResults, message))
	end

	-- 展示自动抽结束总结。
	local function showAutoSummary(rollCount)
		if not isOpen() then
			return
		end

		Renderer.RenderResult(refs, DataAdapter.BuildAutoSummaryModel(rollCount))
	end

	-- 返回当前打开的蛋 id。
	local function getCurrentEggId()
		return currentEggId
	end

	Renderer.SetOpen(refs, false)
	Renderer.ClearResult(refs)

	-- 关闭按钮隐藏面板。
	Renderer.ConnectActivated(refs.CloseButton, close)
	-- 单抽按钮请求一次抽奖。
	Renderer.ConnectActivated(refs.SingleButton, function()
		requestRoll(1, false)
	end)
	-- 三连抽按钮请求三次抽奖。
	Renderer.ConnectActivated(refs.TripleButton, function()
		requestRoll(3, false)
	end)
	-- 自动抽按钮切换自动抽流程。
	Renderer.ConnectActivated(refs.AutoButton, function()
		requestRoll(1, true)
	end)
	-- 键盘快捷键映射抽奖动作。
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isOpen() then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			requestRoll(1, false)
		elseif input.KeyCode == Enum.KeyCode.H then
			requestRoll(3, false)
		elseif input.KeyCode == Enum.KeyCode.A then
			requestRoll(1, true)
		end
	end)

	return {
		Open = open,
		Close = close,
		Refresh = refresh,
		SetRollHandler = setRollHandler,
		SetAutoRolling = setAutoRolling,
		ShowRollResults = showRollResults,
		ShowAutoSummary = showAutoSummary,
		IsOpen = isOpen,
		GetCurrentEggId = getCurrentEggId,
	}
end

return Controller
