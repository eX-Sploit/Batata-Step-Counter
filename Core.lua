local addonName,
    addon = ...

local counter               = addon.Counter
local driver                = CreateFrame("Frame")
local worldReady            = false
local accumulatedTime       = 0
local SAMPLE_INTERVAL       = 0.1
local DEFAULT_RUN_SPEED     = 7
local lastKnownOnFootSpeed  = DEFAULT_RUN_SPEED
local playerMoving

local function Readable(value)
    return not (issecretvalue and issecretvalue(value)) and not (canaccessvalue and not canaccessvalue(value))
end

local function ReadableNumber(value)
    return Readable(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function ExcludedBy(predicate, unitToken)
    if type(predicate) ~= "function" then
        return false
    end
    local result
    if unitToken then
        result = predicate(unitToken)
    else
        result = predicate()
    end
    return not Readable(result) or not not result
end

local function ReadMovement()
    if ExcludedBy(IsMounted)
        or ExcludedBy(IsSwimming)
        or ExcludedBy(IsFlying)
        or ExcludedBy(IsFalling)
        or ExcludedBy(UnitOnTaxi, "player")
        or ExcludedBy(UnitInVehicle, "player")
        or ExcludedBy(UnitIsDeadOrGhost, "player")
    then
        return nil, "Tracking"
    end

    local movement = {}
    if type(GetUnitSpeed) == "function" then
        local speed = GetUnitSpeed("player")
        if ReadableNumber(speed) then
            playerMoving = speed > 0
            if speed <= 0 then
                return nil, "Tracking"
            end
            lastKnownOnFootSpeed  = speed
            movement.speed        = speed
        end
    end

    if not movement.speed then
        if playerMoving then
            movement.speed = lastKnownOnFootSpeed
            return movement, "Tracking (estimated)"
        elseif playerMoving == false then
            return nil, "Tracking"
        end
        return nil, "Waiting for movement data"
    end
    return movement, "Tracking"
end

local function OnUpdate(eventFrame, elapsedSeconds)
    accumulatedTime = accumulatedTime + elapsedSeconds
    if accumulatedTime < SAMPLE_INTERVAL then
        return
    end
    local sampleElapsed = accumulatedTime
    accumulatedTime = 0
    local movement,
        status = ReadMovement()
    local stepsChanged   = counter:Sample(sampleElapsed, movement)
    local statusChanged  = addon.status ~= status
    addon.status = status
    if stepsChanged or statusChanged then
        addon.UI:Refresh()
    end
end

function addon:UpdateTracking()
    accumulatedTime = 0
    counter:ClearMovement()
    driver:SetScript("OnUpdate", nil)
    if self.database.paused then
        self.status = "Paused"
    elseif worldReady then
        self.status = "Tracking"
        driver:SetScript("OnUpdate", OnUpdate)
    else
        self.status = "Loading"
    end
    self.UI:Refresh()
end

function addon:TogglePaused()
    counter:SetPaused(not self.database.paused)
    self:UpdateTracking()
end

function addon:Reset()
    counter:Reset()
    accumulatedTime = 0
    self.UI:Refresh()
end

driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_LEAVING_WORLD")
driver:RegisterEvent("PLAYER_STARTED_MOVING")
driver:RegisterEvent("PLAYER_STOPPED_MOVING")
driver:SetScript("OnEvent", function(eventFrame, eventName, loadedAddon)
    if eventName == "ADDON_LOADED" then
        if loadedAddon ~= addonName then
            return
        end
        if type(Batata_Step_Counter_DB) ~= "table" then
            Batata_Step_Counter_DB = {}
        end
        addon.database = Batata_Step_Counter_DB
        counter:Initialize(addon.database)
        addon.UI:Build()
        addon.MinimapButton:Build()
        addon:UpdateTracking()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif eventName == "PLAYER_STARTED_MOVING" or eventName == "PLAYER_STOPPED_MOVING" then
        playerMoving     = eventName == "PLAYER_STARTED_MOVING"
        accumulatedTime  = 0
        counter:ClearMovement()
    elseif eventName == "PLAYER_ENTERING_WORLD" or eventName == "PLAYER_LEAVING_WORLD" then
        worldReady            = eventName == "PLAYER_ENTERING_WORLD"
        playerMoving          = nil
        lastKnownOnFootSpeed  = DEFAULT_RUN_SPEED
        if addon.database then
            if worldReady then
                addon.MinimapButton:Build()
            end
            addon:UpdateTracking()
        end
    end
end)

SLASH_BATATA_STEP_COUNTER1        = "/batatasteps"
SLASH_BATATA_STEP_COUNTER2        = "/steps"
SlashCmdList.BATATA_STEP_COUNTER  = function()
    if addon.UI.frame then
        addon.UI.frame:SetShown(not addon.UI.frame:IsShown())
    end
end