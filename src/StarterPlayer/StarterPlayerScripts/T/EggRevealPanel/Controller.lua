-- EggRevealPanel/Controller
-- 编排抽蛋开奖展示流程和继续/停止输入。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

function Controller.Init(player)
	local refs = UIRefs.ResolveEggRevealPanel(player)
	local continueEvent = Instance.new("BindableEvent")

	local isBusy = false
	local isWaitingForContinue = false
	local releaseRequested = false
	local stopHandler = nil

	local function releaseContinue()
		releaseRequested = true
		if isWaitingForContinue then
			continueEvent:Fire()
		end
	end

	local function close()
		isBusy = false
		isWaitingForContinue = false
		releaseRequested = true
		continueEvent:Fire()
		Renderer.SetOpen(refs, false)
	end

	local function playReveal(eggId, rollResults, options)
		if isBusy then
			return false
		end

		isBusy = true
		isWaitingForContinue = false
		releaseRequested = false

		local revealModel = DataAdapter.BuildRevealModel(eggId, rollResults)
		local shouldKeepOpen = options and options.KeepOpenAfterContinue == true
		local shouldShowStop = options and options.ShowStopButton == true

		Renderer.RenderEggs(refs, revealModel)
		Renderer.SetStopVisible(refs, shouldShowStop)
		Renderer.PlayShake(refs, revealModel)
		if not isBusy then
			return false
		end

		Renderer.RenderRewards(refs, revealModel)
		isWaitingForContinue = true
		if not releaseRequested then
			continueEvent.Event:Wait()
		end
		isWaitingForContinue = false
		if not isBusy then
			return false
		end

		releaseRequested = false
		Renderer.SetContinuePrompt(refs, false, "")

		if shouldKeepOpen then
			Renderer.ClearSlots(refs)
			Renderer.SetOpen(refs, true)
			Renderer.SetStopVisible(refs, shouldShowStop)
		else
			Renderer.SetOpen(refs, false)
		end

		isBusy = false
		return true
	end

	local function isRevealBusy()
		return isBusy
	end

	local function setStopHandler(handler)
		stopHandler = handler
	end

	Renderer.SetOpen(refs, false)

	Renderer.ConnectActivated(refs.ContinueButton, function()
		if isWaitingForContinue then
			releaseContinue()
		end
	end, {
		DisableMotion = true,
	})

	Renderer.ConnectActivated(refs.StopButton, function()
		if stopHandler then
			stopHandler()
		end
		releaseContinue()
	end)

	return {
		PlayReveal = playReveal,
		Close = close,
		IsBusy = isRevealBusy,
		SetStopHandler = setStopHandler,
	}
end

return Controller
