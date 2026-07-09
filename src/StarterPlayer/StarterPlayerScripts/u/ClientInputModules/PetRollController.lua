-- PetRollController
-- 客户端抽蛋动作层，负责按钮请求、自动抽循环和结果展示。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PetSystemTheta"))

local PetRollController = {}

-- 初始化抽蛋动作控制器。
function PetRollController.Init(snapshotController, eggPanelView, eggInteractionController, eggRevealView)
	local isRequestingPetRoll = false
	local isAutoRolling = false

	local function isRevealBusy()
		return eggRevealView and eggRevealView.IsBusy and eggRevealView.IsBusy()
	end

	-- 请求服务端执行一次或多次抽蛋。
	local function requestPetRoll(eggId, rollCount)
		if isRequestingPetRoll or isRevealBusy() then
			return nil
		end

		isRequestingPetRoll = true
		local result = snapshotController.InvokeAction("RequestPetRoll", eggId, rollCount)
		isRequestingPetRoll = false

		if not result then
			return nil
		end

		return result
	end

	-- 成功抽奖走开奖层；失败仍回到蛋面板展示错误信息。
	local function showPetRollOutcome(eggId, result, revealOptions)
		if not result then
			return nil
		end

		if result.Success == true then
			if eggRevealView then
				eggRevealView.PlayReveal(result.EggId or eggId, result.RollResults, revealOptions)
			else
				eggPanelView.ShowRollResults(result.RollResults, result.Message)
			end
			return result
		end

		eggPanelView.ShowRollResults(result.RollResults, result.Message)
		return result
	end

	-- 停止自动抽，并按需展示总结。
	local function stopAutoRoll(showSummary, rolledCount)
		isAutoRolling = false
		eggPanelView.SetAutoRolling(false)
		if eggRevealView then
			eggRevealView.Close()
		end

		if showSummary then
			eggPanelView.ShowAutoSummary(rolledCount or 0)
		end
	end

	-- 由开奖层 StopButton 调用，只请求自动抽循环在当前轮结束后停下。
	local function requestAutoStop()
		isAutoRolling = false
		eggPanelView.SetAutoRolling(false)
		if eggRevealView and not isRequestingPetRoll and not isRevealBusy() then
			eggRevealView.Close()
		end
	end

	-- 自动抽循环，每次仍走服务端 RequestPetRoll。
	local function runAutoRoll(eggId)
		local rolledCount = 0
		local cooldown = math.max(0.1, tonumber(PetSystemTheta.RollCooldownSeconds) or 0.5)
		local shouldShowSummary = true

		while isAutoRolling and eggPanelView.IsOpen() and eggPanelView.GetCurrentEggId() == eggId do
			if not eggInteractionController.IsPlayerNearEgg(eggId) then
				break
			end

			local result = requestPetRoll(eggId, 1)
			if not result then
				shouldShowSummary = false
				break
			end

			if result.Success ~= true then
				shouldShowSummary = false
				eggPanelView.ShowRollResults(result.RollResults, result.Message)
				break
			end

			rolledCount += #(result.RollResults or {})
			showPetRollOutcome(eggId, result, {
				KeepOpenAfterContinue = isAutoRolling,
				ShowStopButton = isAutoRolling,
			})

			if not isAutoRolling then
				break
			end

			task.wait(cooldown + 0.05)
		end

		stopAutoRoll(shouldShowSummary and eggPanelView.IsOpen(), rolledCount)
	end

	-- 开始或停止自动抽。
	local function startAutoRoll(eggId)
		if isAutoRolling then
			stopAutoRoll(false, 0)
			return
		end

		if isRevealBusy() then
			return
		end

		isAutoRolling = true
		eggPanelView.SetAutoRolling(true)

		task.spawn(runAutoRoll, eggId)
	end

	-- 处理蛋面板发出的抽奖请求。
	local function handleRollRequest(eggId, rollCount, isAuto)
		if isAuto then
			startAutoRoll(eggId)
			return
		end

		if isAutoRolling then
			return
		end

		if isRevealBusy() then
			return
		end

		if not eggInteractionController.IsPlayerNearEgg(eggId) then
			warn("Player is not near this egg")
			return
		end

		local result = requestPetRoll(eggId, rollCount)
		showPetRollOutcome(eggId, result, {
			KeepOpenAfterContinue = false,
			ShowStopButton = false,
		})
	end

	if eggRevealView then
		eggRevealView.SetStopHandler(requestAutoStop)
	end

	eggPanelView.SetRollHandler(handleRollRequest)
end

return PetRollController
