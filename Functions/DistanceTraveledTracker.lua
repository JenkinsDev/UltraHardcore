--[[
  Distance Ran System - Tracks yards ran
]]

local distanceTraveledYds = -1

local function SaveStats()
  CharacterStats:UpdateStat('distanceTraveledYds', distanceTraveledYds)
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
local sessionFrame = CreateFrame('Frame')
sessionFrame:RegisterEvent('PLAYER_LOGOUT')
sessionFrame:RegisterEvent('PLAYER_LEAVING_WORLD')
sessionFrame:RegisterEvent('ADDON_LOADED')
sessionFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'PLAYER_LOGOUT' or event == 'PLAYER_LEAVING_WORLD' then
    EndSession()
  elseif event == 'ADDON_LOADED' and select(1, ...) == 'UltraHardcore' then
    -- Initialize session tracking when addon loads
    InitializeSessionTracking()
  end
end)

local lastSaveElapsed = 0.0
sessionFrame:SetScript('OnUpdate', function(_, elapsed)
  -- wait for init to finish
  if distanceTraveledYds == -1 or UnitOnTaxi('Player') then return end

  -- track our estimated distance travelled since the last update
  local traveledYds = GetUnitSpeed('Player') * elapsed
  AddDistanceTraveled(traveledYds)

  -- save every 10 seconds, or so
  lastSaveElapsed = elapsed + lastSaveElapsed
  if lastSaveElapsed >= 2 then
    SaveStats()
    lastSaveElapsed = 0
  end
end)
