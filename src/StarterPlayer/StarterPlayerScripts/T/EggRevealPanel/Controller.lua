-- EggRevealPanel/Controller
-- 编排抽蛋开奖展示流程和继续/停止输入。

local RunService = game:GetService("RunService")

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
	local revealStartCount = 0
	local diagnosticSequence = 0

	local function isEffectivelyVisible(guiObject)
		if guiObject.Visible ~= true then
			return false
		end

		local ancestor = guiObject.Parent
		while ancestor do
			if ancestor:IsA("GuiObject") and ancestor.Visible ~= true then
				return false
			end
			if ancestor:IsA("ScreenGui") and ancestor.Enabled ~= true then
				return false
			end
			ancestor = ancestor.Parent
		end

		return true
	end

	local function getPromptCandidates()
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		local candidates = {}
		local hasVisibleCandidate = false
		if not playerGui then
			return candidates, hasVisibleCandidate
		end

		for _, descendant in ipairs(playerGui:GetDescendants()) do
			if (descendant:IsA("TextLabel") or descendant:IsA("TextButton"))
				and string.find(string.lower(descendant.Text), "click anywhere", 1, true)
			then
				local effectivelyVisible = isEffectivelyVisible(descendant)
				hasVisibleCandidate = hasVisibleCandidate or effectivelyVisible
				table.insert(candidates, ("%s[visible=%s,effective=%s]"):format(
					descendant:GetFullName(),
					tostring(descendant.Visible),
					tostring(effectivelyVisible)
				))
			end
		end

		return candidates, hasVisibleCandidate
	end

	local function getDebugState()
		local state = Renderer.GetDebugState(refs)
		state.IsBusy = isBusy
		state.IsWaitingForContinue = isWaitingForContinue
		state.RevealStartCount = revealStartCount
		return state
	end

	local function recordDiagnostic(stage)
		if not RunService:IsStudio() then
			return
		end

		diagnosticSequence += 1
		local state = getDebugState()
		local promptCandidates, hasVisiblePromptCandidate = getPromptCandidates()
		print(("[EggRevealTest] sequence=%d stage=%s reveals=%d busy=%s waiting=%s panel=%s button=%s active=%s textVisible=%s text=%s"):format(
			diagnosticSequence,
			tostring(stage),
			state.RevealStartCount,
			tostring(state.IsBusy),
			tostring(state.IsWaitingForContinue),
			tostring(state.PanelOpen),
			tostring(state.ContinueButtonVisible),
			tostring(state.ContinueButtonActive),
			tostring(state.ContinueTextVisible),
			tostring(state.ContinueText)
		))

		if hasVisiblePromptCandidate and state.RevealStartCount == 0 then
			warn("[EggRevealTest] anomaly=continue-visible-before-first-reveal")
		elseif hasVisiblePromptCandidate and not state.IsBusy then
			warn("[EggRevealTest] anomaly=continue-visible-while-reveal-idle")
		elseif hasVisiblePromptCandidate and not state.IsWaitingForContinue then
			warn("[EggRevealTest] anomaly=continue-visible-outside-waiting-phase")
		end

		if hasVisiblePromptCandidate or stage == "before-initial-reset" then
			print("[EggRevealTest] promptCandidates=" .. table.concat(promptCandidates, " | "))
		end
	end

	local function watchDiagnosticProperty(instance, propertyName, label)
		instance:GetPropertyChangedSignal(propertyName):Connect(function()
			task.defer(recordDiagnostic, "changed:" .. label)
		end)
	end

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
		recordDiagnostic("close")
	end

	local function playReveal(eggId, rollResults, options)
		if isBusy then
			return false
		end

		isBusy = true
		isWaitingForContinue = false
		releaseRequested = false
		revealStartCount += 1
		recordDiagnostic("play-reveal:start")

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
		recordDiagnostic("play-reveal:waiting-for-continue")
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
		recordDiagnostic("play-reveal:finished")
		return true
	end

	local function isRevealBusy()
		return isBusy
	end

	local function setStopHandler(handler)
		stopHandler = handler
	end

	recordDiagnostic("before-initial-reset")
	Renderer.SetOpen(refs, false)
	recordDiagnostic("after-initial-reset")

	if RunService:IsStudio() then
		watchDiagnosticProperty(refs.PanelRoot, "Visible", "PanelRoot.Visible")
		watchDiagnosticProperty(refs.ContinueButton, "Visible", "ContinueButton.Visible")
		watchDiagnosticProperty(refs.ContinueButton, "Active", "ContinueButton.Active")
		watchDiagnosticProperty(refs.ContinueText, "Visible", "ContinueText.Visible")
		watchDiagnosticProperty(refs.ContinueText, "Text", "ContinueText.Text")
	end

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
		GetDebugState = getDebugState,
		RecordDiagnostic = recordDiagnostic,
	}
end

return Controller
