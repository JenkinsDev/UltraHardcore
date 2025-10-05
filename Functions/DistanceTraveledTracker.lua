--[[
  Distance Ran System - Tracks yards ran
]]

local distanceTraveledYds = -1
local isTaxiing = false
local currentSpeed = 0

local function SaveStats()
	CharacterStats:UpdateStat("distanceTraveledYds", distanceTraveledYds)
end

-- Function to initialize session tracking
local function InitializeSessionTracking()
	local stats = CharacterStats:GetCurrentCharacterStats()
	if stats.distanceTraveledYds ~= nil then
		distanceTraveledYds = stats.distanceTraveledYds
	else
		distanceTraveledYds = 0
	end
end

-- Function to end session and save data
local function EndSession()
	SaveStats()
end

local function AddDistanceTraveled(yards)
	distanceTraveledYds = yards + distanceTraveledYds
end

-- Register events for automatic session tracking
local sessionFrame = CreateFrame("Frame")
sessionFrame:RegisterEvent("PLAYER_LOGOUT")
sessionFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
sessionFrame:RegisterEvent("ADDON_LOADED")
sessionFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
		EndSession()
	elseif event == "ADDON_LOADED" and select(1, ...) == "UltraHardcore" then
		-- Initialize session tracking when addon loads
		InitializeSessionTracking()
	end
end)

local lastSaveElapsed = 0.0
local lastTaxiSampleElapsed = nil
local lastSpeedSampleElapsed = nil

sessionFrame:SetScript("OnUpdate", function(_, elapsed)
	-- we don't want to poll for taxiing every tick. 1 seconds should be fine
	if lastTaxiSampleElapsed == nil or lastTaxiSampleElapsed >= 1 then
		isTaxiing = UnitOnTaxi("Player")
		lastTaxiSampleElapsed = 0.0
	else
		lastTaxiSampleElapsed = elapsed + lastTaxiSampleElapsed
	end

	-- ^ same as above, but polling for speed. We'll do this every .5 seconds however
	if lastSpeedSampleElapsed == nil or lastSpeedSampleElapsed >= 0.5 then
		currentSpeed = GetUnitSpeed("Player")
		lastSpeedSampleElapsed = 0.0
	else
		lastSpeedSampleElapsed = elapsed + lastSpeedSampleElapsed
	end

	-- wait for tavel distance init so we don't overwrite data, but also skip any
	-- actions if we're taxiing
	if distanceTraveledYds == -1 or isTaxiing then
		return
	end

	-- track our estimated distance travelled since the last update
	AddDistanceTraveled(currentSpeed * elapsed)

	-- save every 2 seconds, or so
	if lastSaveElapsed >= 2 then
		SaveStats()
		lastSaveElapsed = 0
	else
		lastSaveElapsed = elapsed + lastSaveElapsed
	end
end)
