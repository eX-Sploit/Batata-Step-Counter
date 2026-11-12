local addon = {}
assert(loadfile("Counter.lua"))("Batata Step Counter", addon)

local counter = addon.Counter
local database
local passedTests = 0

local function NewCounter(savedState)
    database = savedState or {}
    counter:Initialize(database)
end

local function Movement(positionX, instanceID)
    return {
        speed       = 7,
        x           = positionX,
        y           = positionX and 0,
        z           = positionX and 0,
        instanceID  = instanceID or 1,
    }
end

local function Test(name, callback)
    callback()
    passedTests = passedTests + 1
    print("PASS " .. name)
end

Test("fresh and malformed saved state", function()
    NewCounter()
    assert(database.steps == 0 and database.partialStep == 0 and not database.paused)
    NewCounter({ steps = -3, partialStep = 7, paused = "yes" })
    assert(database.steps == 0 and database.partialStep == 0 and not database.paused)
    NewCounter({ steps = math.huge, partialStep = 0 / 0 })
    assert(database.steps == 0 and database.partialStep == 0)
end)

Test("position movement accumulates whole and partial steps", function()
    NewCounter()
    counter:Sample(0.1, Movement(0))
    for sampleIndex = 1, 10 do
        counter:Sample(0.1, Movement(sampleIndex * 0.7))
    end
    assert(database.steps == 4)
    assert(math.abs(database.partialStep - 2 / 3) < 0.000001)
end)

Test("running into a wall does not count position samples", function()
    NewCounter()
    for sampleIndex = 1, 20 do
        counter:Sample(0.1, Movement(0))
    end
    assert(database.steps == 0 and database.partialStep == 0)
end)

Test("speed fallback works without position API", function()
    NewCounter()
    counter:Sample(0.1, Movement())
    for sampleIndex = 1, 10 do
        counter:Sample(0.1, Movement())
    end
    assert(database.steps == 4)
end)

Test("pause and resume discard previous movement", function()
    NewCounter()
    counter:Sample(0.1, Movement(0))
    counter:SetPaused(true)
    counter:Sample(0.1, Movement(100))
    assert(database.steps == 0)
    counter:SetPaused(false)
    counter:Sample(0.1, Movement(200))
    assert(database.steps == 0 and database.partialStep == 0)
    counter:Sample(0.1, Movement(200.7))
    assert(database.partialStep > 0)
end)

Test("reset clears partial steps and preserves paused state", function()
    NewCounter({ steps = 42, partialStep = 0.8, paused = true })
    counter:Reset()
    assert(database.steps == 0 and database.partialStep == 0 and database.paused)
end)

Test("excluded movement breaks the sampling baseline", function()
    NewCounter()
    counter:Sample(0.1, Movement(0))
    counter:Sample(0.1, nil)
    counter:Sample(0.1, Movement(100))
    assert(database.steps == 0 and database.partialStep == 0)
end)

Test("teleports and instance changes do not count", function()
    NewCounter()
    counter:Sample(0.1, Movement(0))
    counter:Sample(0.1, Movement(1000))
    counter:Sample(0.1, Movement(1000.7, 2))
    assert(database.steps == 0 and database.partialStep == 0)
    counter:Sample(0.1, Movement(1001.4, 2))
    assert(database.partialStep > 0)
end)

Test("long frame gaps and invalid speeds do not count", function()
    NewCounter()
    counter:Sample(0.1, Movement(0))
    counter:Sample(5, Movement(35))
    counter:Sample(0.1, Movement(35.7))
    assert(database.steps == 0 and database.partialStep == 0)
    counter:Sample(0.1, { speed = 0 })
    counter:Sample(0.1, { speed = math.huge })
    counter:Sample(0.1, { speed = 0 / 0 })
    assert(database.steps == 0 and database.partialStep == 0)
end)

Test("saved total partial step and pause restore", function()
    NewCounter({ steps = 123, partialStep = 0.25, paused = true })
    assert(database.steps == 123 and database.partialStep == 0.25 and database.paused)
end)

Test("distance converts existing steps and fractions to kilometers and miles", function()
    -- 1,173 and one third steps at 1.5 yards per step is exactly one mile.
    NewCounter({ steps = 1173, partialStep = 1 / 3 })
    local kilometers, miles = counter:GetDistance()
    assert(math.abs(kilometers - 1.609344) < 0.000001)
    assert(math.abs(miles - 1) < 0.000001)
    counter:Reset()
    kilometers, miles = counter:GetDistance()
    assert(kilometers == 0 and miles == 0)
end)

print(string.format("%d counter tests passed", passedTests))

local widgetMethods = {}
local runtimeDriver
local playerState
local inaccessibleValue = {}

for methodIndex, methodName in ipairs({
    "SetTitle", "SetTitleOffsets", "SetPortraitToAsset", "SetJustifyH", "SetWordWrap", "SetTextColor",
    "SetMovable", "SetClampedToScreen", "SetFrameStrata", "SetToplevel", "EnableMouse", "RegisterForDrag",
    "StartMoving", "StopMovingOrSizing", "ClearAllPoints", "SetTexture", "SetColorTexture", "SetAtlas",
    "SetHorizTile", "SetVertTile", "RegisterEvent", "UnregisterEvent", "SetFrameLevel", "RegisterForClicks",
    "SetHighlightTexture", "SetTexCoord", "AddLine",
}) do
    widgetMethods[methodName] = function()
    end
end

local function NewWidget()
    return setmetatable({ scripts = {}, shown = true, width = 304, text = "", fontSize = 12 }, { __index = widgetMethods })
end

function widgetMethods:SetScript(scriptName, callback)
    self.scripts[scriptName] = callback
end

function widgetMethods:HookScript(scriptName, callback)
    local inherited = self.scripts[scriptName]
    self.scripts[scriptName] = function(control, ...)
        if inherited then
            inherited(control, ...)
        end
        callback(control, ...)
    end
end

function widgetMethods:SetShown(shown)
    if self.shown ~= shown then
        self.shown = shown
        local callback = self.scripts[shown and "OnShow" or "OnHide"]
        if callback then
            callback(self)
        end
    end
end

function widgetMethods:Show()
    self:SetShown(true)
end

function widgetMethods:Hide()
    self:SetShown(false)
end

function widgetMethods:IsShown()
    return self.shown
end

function widgetMethods:SetSize(width, height)
    self.width   = width
    self.height  = height
end

function widgetMethods:SetHeight(height)
    self.height = height
end

function widgetMethods:GetWidth()
    return self.width
end

function widgetMethods:GetHeight()
    return self.height
end

function widgetMethods:GetCenter()
    return 100, 100
end

function widgetMethods:GetEffectiveScale()
    return self.scale or 1
end

function widgetMethods:SetPoint(...)
    self.anchor = { ... }
end

function widgetMethods:GetPoint()
    return unpack(self.anchor)
end

function widgetMethods:SetText(text)
    self.text = tostring(text)
end

function widgetMethods:SetTexture(texturePath)
    self.texturePath = texturePath
end

function widgetMethods:SetPortraitToAsset(texturePath)
    self.portraitTexturePath = texturePath
end

function widgetMethods:GetFont()
    return "Fonts\\FRIZQT__.TTF", self.fontSize
end

function widgetMethods:SetFont(fontPath, fontSize, fontFlags)
    self.fontSize = fontSize
end

function widgetMethods:GetStringWidth()
    return #self.text * self.fontSize * 0.6
end

function widgetMethods:CreateFontString()
    local fontString = NewWidget()
    fontString.parent = self
    return fontString
end

function widgetMethods:CreateTexture()
    return NewWidget()
end

function widgetMethods:GetTitleText()
    return NewWidget()
end

function widgetMethods:SetOwner(owner, anchor)
    self.owner = owner
end

function widgetMethods:IsOwned(owner)
    return self.owner == owner
end

local function LoadAddon(savedState)
    UIParent                = NewWidget()
    Minimap                 = NewWidget()
    GameTooltip             = NewWidget()
    UISpecialFrames         = {}
    SlashCmdList            = {}
    Batata_Step_Counter_DB  = savedState
    runtimeDriver           = nil
    playerState             = { speed = 7, positionX = 0, instanceID = 1 }
    BreakUpLargeNumbers     = nil
    Minimap:SetSize(140, 140)
    GetCursorPosition = function()
        return 200, 200
    end
    canaccessvalue          = function(value)
        return value ~= inaccessibleValue
    end
    issecretvalue = function(value)
        return value == inaccessibleValue
    end
    CreateFrame = function(frameType, frameName, parent, template)
        assert(frameType == "Frame" or frameType == "Button")
        local widget = NewWidget()
        widget.parent    = parent
        widget.template  = template
        if template == "PortraitFrameTemplateMinimizable" then
            widget.CloseButton     = NewWidget()
            widget.TopTileStreaks  = NewWidget()
        elseif template == "InsetFrameTemplate" then
            widget.Bg         = NewWidget()
            widget.NineSlice  = NewWidget()
        elseif not template then
            if frameType == "Frame" and not parent then
                runtimeDriver = widget
            end
        else
            assert(template == "UIPanelButtonTemplate")
        end
        return widget
    end
    GetUnitSpeed = function(unitToken)
        assert(unitToken == "player")
        return playerState.speed
    end
    UnitPosition = function(unitToken)
        assert(unitToken == "player")
        if playerState.noPosition then
            return nil
        end
        return playerState.positionX, 0, 0, playerState.instanceID
    end
    for predicateIndex, predicateName in ipairs({
        "IsMounted", "IsSwimming", "IsFlying", "IsFalling", "UnitOnTaxi", "UnitInVehicle", "UnitIsDeadOrGhost",
    }) do
        local stateKey = predicateName
        _G[predicateName] = function()
            return playerState[stateKey] or false
        end
    end

    local loadedAddon = {}
    for manifestLine in io.lines("Batata Step Counter.toc") do
        local runtimeFile = manifestLine:match("^([^#%s].-%.lua)%s*$")
        if runtimeFile then
            assert(loadfile(runtimeFile))("Batata Step Counter", loadedAddon)
        end
    end
    runtimeDriver.scripts.OnEvent(runtimeDriver, "ADDON_LOADED", "Batata Step Counter")
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_ENTERING_WORLD")
    return loadedAddon
end

local function WalkSamples(sampleCount)
    for sampleIndex = 1, sampleCount do
        playerState.positionX = playerState.positionX + 0.7
        if runtimeDriver.scripts.OnUpdate then
            runtimeDriver.scripts.OnUpdate(runtimeDriver, 0.1)
        end
    end
end

Test("manifest startup and live total binding", function()
    local loadedAddon = LoadAddon()
    assert(loadedAddon.UI.frame:IsShown() and loadedAddon.status == "Tracking")
    assert(loadedAddon.UI.steps.parent.template == "InsetFrameTemplate")
    assert(loadedAddon.UI.distance.parent == loadedAddon.UI.steps.parent)
    assert(loadedAddon.UI.distance.text == "0.00 km / 0.00 mi")
    assert(#UISpecialFrames == 1)
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4 and loadedAddon.UI.steps.text == "4")
end)

Test("distance display updates between whole steps and exposes tracking status on hover", function()
    local loadedAddon = LoadAddon()
    WalkSamples(8)
    assert(loadedAddon.database.steps == 3 and loadedAddon.UI.distance.text == "0.00 km / 0.00 mi")
    WalkSamples(1)
    assert(loadedAddon.database.steps == 3 and loadedAddon.UI.distance.text == "0.01 km / 0.00 mi")
    WalkSamples(5)
    assert(loadedAddon.UI.distance.text == "0.01 km / 0.01 mi")
    loadedAddon.UI.frame.scripts.OnEnter(loadedAddon.UI.frame)
    assert(GameTooltip.text == "Estimated on-foot distance\nTracking")
    playerState.speed = inaccessibleValue
    WalkSamples(1)
    assert(GameTooltip.text == "Estimated on-foot distance\nTracking (estimated)")
    loadedAddon:TogglePaused()
    assert(GameTooltip.text == "Estimated on-foot distance\nPaused")
    local pausedDistance = loadedAddon.UI.distance.text
    WalkSamples(20)
    assert(loadedAddon.UI.distance.text == pausedDistance)
    loadedAddon.UI.frame.scripts.OnLeave(loadedAddon.UI.frame)
    assert(not GameTooltip:IsShown())
end)

Test("window and addon metadata use step-counter artwork", function()
    local loadedAddon      = LoadAddon()
    local expectedTexture  = "Interface\\AddOns\\Batata Step Counter\\Assets\\batata-step-counter.tga"
    assert(loadedAddon.UI.frame.portraitTexturePath == expectedTexture)
    local manifestTexture
    for manifestLine in io.lines("Batata Step Counter.toc") do
        manifestTexture = manifestLine:match("^## IconTexture: (.+)") or manifestTexture
    end
    assert(manifestTexture == expectedTexture)
end)

Test("compact window uses icon-only reset and matching controls", function()
    local loadedAddon  = LoadAddon()
    local interface    = loadedAddon.UI
    assert(interface.frame.width == 238 and interface.frame.height == 148)
    assert(interface.playButton.width == 30 and interface.playButton.height == 22)
    assert(interface.resetButton.width == 30 and interface.resetButton.height == 22)
    assert(interface.resetButton.text == "" and interface.resetButton.tooltipText == "Reset steps and distance")
    assert(interface.resetButton.icon.texturePath == "Interface\\Buttons\\UI-RefreshButton")
    assert(interface.steps.height == 32 and interface.distance.width == 206)
    interface.resetButton.scripts.OnEnter(interface.resetButton)
    assert(GameTooltip.text == "Reset steps and distance")
end)

Test("large totals fit the compact count area", function()
    local loadedAddon  = LoadAddon({ steps = 123456789012345 })
    local interface    = loadedAddon.UI
    assert(interface.steps:GetStringWidth() <= interface.frame.width - 32)
    assert(interface.distance:GetStringWidth() <= interface.frame.width - 32)
    loadedAddon:Reset()
    assert(interface.steps.fontSize == 28 and interface.steps.text == "0")
    assert(interface.distance.fontSize == 12 and interface.distance.text == "0.00 km / 0.00 mi")
end)

Test("minimap icon toggles the counter without pausing tracking", function()
    local loadedAddon    = LoadAddon()
    local minimapButton  = loadedAddon.MinimapButton.button
    assert(minimapButton.parent == Minimap and minimapButton.width == 31 and minimapButton.height == 31)
    assert(loadedAddon.MinimapButton.icon.texturePath
        == "Interface\\AddOns\\Batata Step Counter\\Assets\\batata-step-counter.tga")
    minimapButton.scripts.OnClick(minimapButton)
    assert(not loadedAddon.UI.frame:IsShown() and loadedAddon.database.window.hidden)
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4 and not loadedAddon.database.paused)
    minimapButton.scripts.OnClick(minimapButton)
    assert(loadedAddon.UI.frame:IsShown() and loadedAddon.UI.steps.text == "4")
    assert(loadedAddon.UI.distance.text == "0.01 km / 0.00 mi")
    minimapButton.scripts.OnEnter(minimapButton)
    assert(GameTooltip.text == "Batata Step Counter" and GameTooltip:IsOwned(minimapButton))
    minimapButton.scripts.OnLeave(minimapButton)
    assert(not GameTooltip:IsShown())
end)

Test("minimap dragging accounts for scale and saves position", function()
    local loadedAddon    = LoadAddon()
    local minimapButton  = loadedAddon.MinimapButton.button
    Minimap.scale      = 2
    GetCursorPosition  = function()
        return 400, 200
    end
    minimapButton.scripts.OnDragStart(minimapButton)
    assert(minimapButton.scripts.OnUpdate)
    minimapButton.scripts.OnUpdate(minimapButton, 0.1)
    assert(loadedAddon.database.minimap.angle == 0)
    assert(math.abs(minimapButton.anchor[4] - 75) < 0.000001)
    assert(math.abs(minimapButton.anchor[5]) < 0.000001)
    minimapButton.scripts.OnDragStop(minimapButton)
    assert(not minimapButton.scripts.OnUpdate)

    local restoredAddon   = LoadAddon(loadedAddon.database)
    local restoredButton  = restoredAddon.MinimapButton.button
    assert(restoredAddon.database.minimap.angle == 0)
    assert(math.abs(restoredButton.anchor[4] - 75) < 0.000001)
    restoredAddon.MinimapButton:Build()
    assert(restoredAddon.MinimapButton.button == restoredButton)
end)

Test("minimap saved angles are normalized without resetting totals", function()
    local loadedAddon = LoadAddon({ steps = 42, minimap = { angle = math.huge } })
    assert(loadedAddon.database.steps == 42 and loadedAddon.database.minimap.angle == 200)
    loadedAddon = LoadAddon({ minimap = { angle = -90 } })
    assert(loadedAddon.database.minimap.angle == 270)
    loadedAddon = LoadAddon({ minimap = "invalid" })
    assert(loadedAddon.database.minimap.angle == 200)
end)

Test("play pause and reset buttons control real tracking", function()
    local loadedAddon = LoadAddon()
    WalkSamples(11)
    local playButton = loadedAddon.UI.playButton
    playButton.scripts.OnClick(playButton)
    assert(loadedAddon.database.paused and not runtimeDriver.scripts.OnUpdate)
    assert(playButton.playIcon:IsShown() and not playButton.pauseLeft:IsShown())
    WalkSamples(20)
    assert(loadedAddon.database.steps == 4)
    local resetButton = loadedAddon.UI.resetButton
    resetButton.scripts.OnClick(resetButton)
    assert(loadedAddon.database.steps == 0 and loadedAddon.database.paused)
    assert(loadedAddon.UI.distance.text == "0.00 km / 0.00 mi")
    playButton.scripts.OnClick(playButton)
    assert(not loadedAddon.database.paused and runtimeDriver.scripts.OnUpdate)
    assert(not playButton.playIcon:IsShown() and playButton.pauseLeft:IsShown())
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4)
end)

Test("all non-foot movement states are excluded", function()
    for predicateIndex, predicateName in ipairs({
        "IsMounted", "IsSwimming", "IsFlying", "IsFalling", "UnitOnTaxi", "UnitInVehicle", "UnitIsDeadOrGhost",
    }) do
        local loadedAddon = LoadAddon()
        playerState[predicateName] = true
        WalkSamples(20)
        assert(loadedAddon.database.steps == 0, predicateName)
        playerState[predicateName] = false
        WalkSamples(11)
        assert(loadedAddon.database.steps == 4, predicateName)
    end
end)

Test("closing the window does not stop counting and slash reopens", function()
    local loadedAddon = LoadAddon()
    loadedAddon.UI.frame.CloseButton.scripts.OnClick()
    assert(not loadedAddon.UI.frame:IsShown() and loadedAddon.database.window.hidden)
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4)
    SlashCmdList.BATATA_STEP_COUNTER()
    assert(loadedAddon.UI.frame:IsShown() and loadedAddon.UI.steps.text == "4")
    assert(not loadedAddon.database.window.hidden)
end)

Test("loading screens discard movement", function()
    local loadedAddon = LoadAddon()
    WalkSamples(1)
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_LEAVING_WORLD")
    assert(not runtimeDriver.scripts.OnUpdate)
    playerState.positionX = 1000
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_ENTERING_WORLD")
    WalkSamples(1)
    assert(loadedAddon.database.steps == 0 and loadedAddon.database.partialStep == 0)
end)

Test("inaccessible speed waits without reading player positions", function()
    local loadedAddon = LoadAddon()
    playerState.speed  = inaccessibleValue
    UnitPosition       = function()
        error("World-position queries must not be used by step tracking")
    end
    WalkSamples(11)
    assert(loadedAddon.database.steps == 0 and loadedAddon.status == "Waiting for movement data")
end)

Test("walking never invokes a blocked world-position API", function()
    local loadedAddon    = LoadAddon()
    local positionCalls  = 0
    UnitPosition = function()
        positionCalls = positionCalls + 1
        error("Interface action failed because of an AddOn")
    end
    for sampleIndex = 1, 11 do
        runtimeDriver.scripts.OnUpdate(runtimeDriver, 0.1)
    end
    assert(loadedAddon.database.steps == 4 and loadedAddon.status == "Tracking")
    assert(positionCalls == 0)
end)

Test("speed becoming restricted during movement keeps counting at the last readable speed", function()
    local loadedAddon = LoadAddon()
    playerState.speed = 3
    WalkSamples(2)
    playerState.speed = inaccessibleValue
    WalkSamples(15)
    assert(loadedAddon.database.steps == 3 and loadedAddon.status == "Tracking (estimated)")
    playerState.speed = 0
    WalkSamples(20)
    assert(loadedAddon.database.steps == 3 and loadedAddon.status == "Tracking")
    playerState.speed = 7
    WalkSamples(11)
    assert(loadedAddon.database.steps == 7 and loadedAddon.status == "Tracking")
end)

Test("movement events start and stop estimated counting when speed is restricted", function()
    local loadedAddon = LoadAddon()
    playerState.speed = inaccessibleValue
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4 and loadedAddon.status == "Tracking (estimated)")
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STOPPED_MOVING")
    WalkSamples(20)
    assert(loadedAddon.database.steps == 4 and loadedAddon.status == "Tracking")
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
    WalkSamples(11)
    assert(loadedAddon.database.steps == 9)
end)

Test("estimated counting still excludes every non-foot movement state", function()
    for predicateIndex, predicateName in ipairs({
        "IsMounted", "IsSwimming", "IsFlying", "IsFalling", "UnitOnTaxi", "UnitInVehicle", "UnitIsDeadOrGhost",
    }) do
        local loadedAddon = LoadAddon()
        playerState.speed           = inaccessibleValue
        playerState[predicateName]  = true
        runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
        WalkSamples(20)
        assert(loadedAddon.database.steps == 0, predicateName)
        playerState[predicateName] = false
        WalkSamples(11)
        assert(loadedAddon.database.steps == 4, predicateName)
    end
end)

Test("manual pause still works while estimated combat counting is active", function()
    local loadedAddon = LoadAddon()
    playerState.speed = inaccessibleValue
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
    WalkSamples(11)
    loadedAddon:TogglePaused()
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STOPPED_MOVING")
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
    WalkSamples(20)
    assert(loadedAddon.database.steps == 4 and loadedAddon.database.paused)
    loadedAddon:TogglePaused()
    WalkSamples(11)
    assert(loadedAddon.database.steps == 9 and not loadedAddon.database.paused)
end)

Test("loading transitions clear estimated movement and cached speed", function()
    local loadedAddon = LoadAddon()
    playerState.speed = 14
    WalkSamples(2)
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_LEAVING_WORLD")
    playerState.speed = inaccessibleValue
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_ENTERING_WORLD")
    WalkSamples(20)
    assert(loadedAddon.database.steps == 0 and loadedAddon.status == "Waiting for movement data")
    runtimeDriver.scripts.OnEvent(runtimeDriver, "PLAYER_STARTED_MOVING")
    WalkSamples(11)
    assert(loadedAddon.database.steps == 5 and loadedAddon.status == "Tracking (estimated)")
end)

Test("no readable movement data waits and then recovers", function()
    local loadedAddon = LoadAddon()
    playerState.speed      = inaccessibleValue
    playerState.positionX  = inaccessibleValue
    runtimeDriver.scripts.OnUpdate(runtimeDriver, 0.1)
    assert(loadedAddon.database.steps == 0 and loadedAddon.status == "Waiting for movement data")
    playerState.speed      = 7
    playerState.positionX  = 100
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4 and loadedAddon.status == "Tracking")
end)

Test("inaccessible exclusion states still do not count", function()
    local loadedAddon = LoadAddon()
    playerState.IsMounted = inaccessibleValue
    WalkSamples(11)
    assert(loadedAddon.database.steps == 0)
end)

Test("speed tracking works without position API and waits without speed", function()
    local loadedAddon = LoadAddon()
    UnitPosition = nil
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4)

    loadedAddon   = LoadAddon()
    GetUnitSpeed  = nil
    WalkSamples(11)
    assert(loadedAddon.database.steps == 0 and loadedAddon.status == "Waiting for movement data")

    loadedAddon   = LoadAddon()
    UnitPosition  = nil
    GetUnitSpeed  = nil
    WalkSamples(20)
    assert(loadedAddon.database.steps == 0 and loadedAddon.status == "Waiting for movement data")
end)

Test("stationary speed and coordinate jumps do not add steps", function()
    local loadedAddon = LoadAddon()
    playerState.speed = 0
    for sampleIndex = 1, 11 do
        runtimeDriver.scripts.OnUpdate(runtimeDriver, 0.1)
    end
    assert(loadedAddon.database.steps == 0)
    playerState.positionX = 1000
    runtimeDriver.scripts.OnUpdate(runtimeDriver, 0.1)
    assert(loadedAddon.database.steps == 0)
    playerState.speed = 7
    WalkSamples(11)
    assert(loadedAddon.database.steps == 4)
end)

Test("per-character saved state survives simulated reload", function()
    local loadedAddon = LoadAddon()
    WalkSamples(11)
    loadedAddon:TogglePaused()
    loadedAddon.UI.frame:SetPoint("TOP", UIParent, "TOP", 15, -20)
    loadedAddon.UI:SavePosition()
    loadedAddon.UI.frame:Hide()
    local savedState     = loadedAddon.database
    local savedKilometers, savedMiles = loadedAddon.Counter:GetDistance()
    local restoredAddon  = LoadAddon(savedState)
    local restoredKilometers, restoredMiles = restoredAddon.Counter:GetDistance()
    assert(restoredAddon.database.steps == 4 and restoredAddon.database.paused)
    assert(not restoredAddon.UI.frame:IsShown() and not runtimeDriver.scripts.OnUpdate)
    assert(restoredAddon.UI.frame.anchor[1] == "TOP" and restoredAddon.UI.frame.anchor[4] == 15)
    assert(restoredKilometers == savedKilometers and restoredMiles == savedMiles)
end)

print(string.format("%d total tests passed", passedTests))