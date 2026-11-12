local addonName,
    addon = ...

local Counter = {}
addon.Counter = Counter

local YARDS_PER_STEP       = 1.5
local KILOMETERS_PER_YARD  = 0.0009144
local YARDS_PER_MILE       = 1760
local MAX_SAMPLE_INTERVAL  = 0.5
local MAX_POSITION_SPEED   = 50
local previousMovement

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Counter:Initialize(database)
    self.database         = database
    database.steps        = IsFiniteNumber(database.steps) and math.max(0, math.floor(database.steps)) or 0
    database.partialStep  = IsFiniteNumber(database.partialStep)
        and database.partialStep >= 0
        and database.partialStep < 1
        and database.partialStep
        or 0
    database.paused   = database.paused == true
    previousMovement  = nil
end

function Counter:ClearMovement()
    previousMovement = nil
end

function Counter:SetPaused(paused)
    self.database.paused = paused == true
    self:ClearMovement()
end

function Counter:Reset()
    self.database.steps        = 0
    self.database.partialStep  = 0
    self:ClearMovement()
end

function Counter:GetDistance()
    -- Include the partial step to preserve the original movement distance.
    local distanceYards = (self.database.steps + self.database.partialStep) * YARDS_PER_STEP
    return distanceYards * KILOMETERS_PER_YARD, distanceYards / YARDS_PER_MILE
end

function Counter:Sample(elapsedSeconds, movement)
    local hasPosition = movement
        and IsFiniteNumber(movement.x)
        and IsFiniteNumber(movement.y)
        and IsFiniteNumber(movement.z)
        and IsFiniteNumber(movement.instanceID)
    if self.database.paused
        or not IsFiniteNumber(elapsedSeconds)
        or elapsedSeconds <= 0
        or elapsedSeconds > MAX_SAMPLE_INTERVAL
        or not movement
        or (not hasPosition and not IsFiniteNumber(movement.speed))
        or (IsFiniteNumber(movement.speed) and movement.speed <= 0)
    then
        self:ClearMovement()
        return false
    end

    local lastMovement = previousMovement
    previousMovement = movement
    if not lastMovement then
        return false
    end

    local distanceYards
    if movement.x and lastMovement.x then
        if movement.instanceID ~= lastMovement.instanceID then
            return false
        end
        local deltaX  = movement.x - lastMovement.x
        local deltaY  = movement.y - lastMovement.y
        local deltaZ  = movement.z - lastMovement.z
        distanceYards = math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        local maximumSpeed = math.max(
            movement.speed or MAX_POSITION_SPEED,
            lastMovement.speed or MAX_POSITION_SPEED
        )
        local maximumDistance = maximumSpeed * elapsedSeconds * 1.5 + 0.5
        if distanceYards > maximumDistance then
            return false
        end
    elseif not movement.x and not lastMovement.x then
        distanceYards = math.min(movement.speed, lastMovement.speed) * elapsedSeconds
    else
        return false
    end

    local totalSteps  = self.database.partialStep + distanceYards / YARDS_PER_STEP
    local wholeSteps  = math.floor(totalSteps)
    self.database.steps        = self.database.steps + wholeSteps
    self.database.partialStep  = totalSteps - wholeSteps
    return distanceYards > 0
end