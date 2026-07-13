local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local PlayerProgressRules = require(script.Parent.Parent.Rules.PlayerProgressRules)

local PlayerPersistenceTransition = {}

local SCHEMA_VERSION = 1
local LIVE_STORE_NAME = "MuscleGrowth_PlayerProgress_v1"
local STUDIO_STORE_NAME = "MuscleGrowth_PlayerProgress_v1_Studio"
local KEY_PREFIX = "Player_"
local AUTOSAVE_INTERVAL_SECONDS = 60
local SESSION_LEASE_SECONDS = 180
local MAX_DATASTORE_ATTEMPTS = 3
local RETRY_DELAYS_SECONDS = { 1, 2 }
local SHUTDOWN_TIMEOUT_SECONDS = 25

local DATA_LOADED_ATTRIBUTE = SceneTheta.Attributes.DataLoaded
local IS_STUDIO = RunService:IsStudio()
local storeName = IS_STUDIO and STUDIO_STORE_NAME or LIVE_STORE_NAME
local playerDataStore = DataStoreService:GetDataStore(storeName)

local serverSessionId = game.JobId
if type(serverSessionId) ~= "string" or serverSessionId == "" then
	serverSessionId = "Studio_" .. HttpService:GenerateGUID(false)
end

local loadedPlayers = setmetatable({}, { __mode = "k" })
local savingPlayers = setmetatable({}, { __mode = "k" })
local releasingPlayers = setmetatable({}, { __mode = "k" })
local releaseFinished = setmetatable({}, { __mode = "k" })
local releaseSucceeded = setmetatable({}, { __mode = "k" })
local releaseReasons = setmetatable({}, { __mode = "k" })

local autosaveStarted = false
local shuttingDown = false

local function getPlayerKey(player)
	return KEY_PREFIX .. tostring(player.UserId)
end

local function isFiniteNumber(value)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function runUpdateAsync(operationName, key, transform)
	local lastError = nil

	for attempt = 1, MAX_DATASTORE_ATTEMPTS do
		local success, result = pcall(function()
			return playerDataStore:UpdateAsync(key, transform)
		end)
		if success then
			return true, result
		end

		lastError = result
		warn(("[PlayerPersistence] %s failed for %s (attempt %d/%d): %s"):format(
			operationName,
			key,
			attempt,
			MAX_DATASTORE_ATTEMPTS,
			tostring(result)
		))

		local retryDelay = RETRY_DELAYS_SECONDS[attempt]
		if retryDelay then
			task.wait(retryDelay)
		end
	end

	return false, tostring(lastError)
end

local function createSession(now)
	return {
		SessionId = serverSessionId,
		ExpiresAt = now + SESSION_LEASE_SECONDS,
	}
end

local function getSessionLoadRejection(record, now)
	local session = record.Session
	if session == nil then
		return nil
	end

	if type(session) ~= "table" then
		return "CorruptSession"
	end

	local sessionId = session.SessionId
	local expiresAt = session.ExpiresAt
	if type(sessionId) ~= "string" or sessionId == "" or not isFiniteNumber(expiresAt) then
		return "CorruptSession"
	end

	-- Studio 的 DataStore 与正式服隔离。停止测试时 Studio 偶尔来不及释放租约，
	-- 新一轮本地测试可以接管旧 Studio 会话；旧会话后续保存时会因失去所有权而停止。
	if IS_STUDIO then
		return nil
	end

	if sessionId ~= serverSessionId and expiresAt > now then
		return "SessionLocked"
	end

	return nil
end

local function buildRecord(state, releaseSession)
	local now = os.time()
	return {
		SchemaVersion = SCHEMA_VERSION,
		State = state,
		Session = releaseSession and nil or createSession(now),
		UpdatedAt = now,
	}
end

function PlayerPersistenceTransition.LoadPlayer(player)
	if shuttingDown then
		return false, "ServerClosing"
	end

	if loadedPlayers[player] then
		return false, "AlreadyLoaded"
	end

	local key = getPlayerKey(player)
	local loadedState = nil
	local rejectionReason = nil

	local callSucceeded, callResult = runUpdateAsync("load", key, function(record)
		loadedState = nil
		rejectionReason = nil

		local state
		if record == nil then
			state = PlayerProgressRules.CreateInitialState()
		elseif type(record) ~= "table" then
			rejectionReason = "CorruptRecord"
			return nil
		elseif record.SchemaVersion ~= SCHEMA_VERSION then
			rejectionReason = "UnsupportedSchema"
			return nil
		elseif type(record.State) ~= "table" then
			rejectionReason = "CorruptState"
			return nil
		else
			local now = os.time()
			local sessionRejection = getSessionLoadRejection(record, now)
			if sessionRejection then
				rejectionReason = sessionRejection
				return nil
			end

			state = PlayerProgressRules.NormalizePersistedState(record.State)
			if not state then
				rejectionReason = "CorruptState"
				return nil
			end
		end

		loadedState = state
		return buildRecord(state, false)
	end)

	if not callSucceeded then
		return false, "DataStoreError: " .. tostring(callResult)
	end

	if not loadedState then
		return false, rejectionReason or "LoadRejected"
	end

	loadedPlayers[player] = true
	releasingPlayers[player] = nil
	releaseFinished[player] = nil
	releaseSucceeded[player] = nil
	releaseReasons[player] = nil

	return true, loadedState
end

local function waitForRelease(player)
	while releasingPlayers[player] and releaseFinished[player] ~= true do
		task.wait()
	end

	return releaseSucceeded[player] == true, releaseReasons[player]
end

local function finishRelease(player, success, reason)
	loadedPlayers[player] = nil
	savingPlayers[player] = nil
	releaseSucceeded[player] = success == true
	releaseReasons[player] = reason
	releaseFinished[player] = true
end

function PlayerPersistenceTransition.SavePlayer(player, releaseSession)
	local shouldRelease = releaseSession == true

	if shouldRelease and releasingPlayers[player] then
		return waitForRelease(player)
	end

	if not loadedPlayers[player] then
		return false, "NotLoaded"
	end

	if shouldRelease then
		releasingPlayers[player] = true
		releaseFinished[player] = false
		while savingPlayers[player] do
			task.wait()
		end
	elseif releasingPlayers[player] or savingPlayers[player] then
		return false, "Busy"
	end

	if not loadedPlayers[player] then
		if shouldRelease then
			finishRelease(player, false, "NotLoaded")
		end
		return false, "NotLoaded"
	end

	savingPlayers[player] = true

	local state = PlayerProgressRules.NormalizePersistedState(PlayerProgressState.Get(player))
	if not state then
		local reason = "MissingPlayerState"
		if shouldRelease then
			finishRelease(player, false, reason)
		else
			savingPlayers[player] = nil
		end
		return false, reason
	end

	local key = getPlayerKey(player)
	local saveOutcome = nil
	local callSucceeded, callResult = runUpdateAsync("save", key, function(record)
		saveOutcome = nil

		if type(record) ~= "table"
			or record.SchemaVersion ~= SCHEMA_VERSION
			or type(record.State) ~= "table"
		then
			saveOutcome = "RecordChanged"
			return nil
		end

		local session = record.Session
		if type(session) ~= "table" or session.SessionId ~= serverSessionId then
			saveOutcome = "SessionLost"
			return nil
		end

		saveOutcome = "Saved"
		return buildRecord(state, shouldRelease)
	end)

	local success = callSucceeded and saveOutcome == "Saved"
	local reason
	if not callSucceeded then
		reason = "DataStoreError: " .. tostring(callResult)
	else
		reason = saveOutcome or "SaveRejected"
	end

	if shouldRelease then
		finishRelease(player, success, reason)
	else
		savingPlayers[player] = nil
		if reason == "SessionLost" or reason == "RecordChanged" then
			loadedPlayers[player] = nil
			player:SetAttribute(DATA_LOADED_ATTRIBUTE, false)
			warn(("[PlayerPersistence] player %s lost ownership of persistent data: %s"):format(
				player.Name,
				reason
			))
			if player.Parent then
				player:Kick("玩家数据会话已失效，请重新进入游戏。")
			end
		elseif not success and reason ~= "Busy" then
			warn(("[PlayerPersistence] autosave failed for player %s: %s"):format(player.Name, tostring(reason)))
		end
	end

	return success, reason
end

function PlayerPersistenceTransition.StartAutosave()
	if autosaveStarted then
		return
	end

	autosaveStarted = true
	task.spawn(function()
		while not shuttingDown do
			task.wait(AUTOSAVE_INTERVAL_SECONDS)
			if shuttingDown then
				break
			end

			for player in pairs(loadedPlayers) do
				local targetPlayer = player
				task.spawn(function()
					PlayerPersistenceTransition.SavePlayer(targetPlayer, false)
				end)
			end
		end
	end)
end

function PlayerPersistenceTransition.Shutdown()
	if shuttingDown then
		return
	end

	shuttingDown = true
	local pendingSaves = 0

	for player in pairs(loadedPlayers) do
		local targetPlayer = player
		pendingSaves += 1
		targetPlayer:SetAttribute(DATA_LOADED_ATTRIBUTE, false)
		task.spawn(function()
			PlayerPersistenceTransition.SavePlayer(targetPlayer, true)
			pendingSaves -= 1
		end)
	end

	local deadline = os.clock() + SHUTDOWN_TIMEOUT_SECONDS
	while pendingSaves > 0 and os.clock() < deadline do
		task.wait(0.1)
	end

	if pendingSaves > 0 then
		warn(("[PlayerPersistence] shutdown timed out with %d pending save(s)"):format(pendingSaves))
	end
end

return PlayerPersistenceTransition
