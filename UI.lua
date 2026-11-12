local addonName,
    addon = ...

local UI = {}
addon.UI = UI

local ICON_TEXTURE  = "Interface\\AddOns\\" .. addonName .. "\\Assets\\batata-step-counter.tga"
local ANCHORS       = {
    TOPLEFT      = true,
    TOP          = true,
    TOPRIGHT     = true,
    LEFT         = true,
    CENTER       = true,
    RIGHT        = true,
    BOTTOMLEFT   = true,
    BOTTOM       = true,
    BOTTOMRIGHT  = true,
}

local function Tooltip(button)
    button:HookScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetText(control.tooltipText)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:HookScript("OnHide", function(control)
        if GameTooltip:IsOwned(control) then
            GameTooltip:Hide()
        end
    end)
end

local function PauseBar(button, offsetX)
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetColorTexture(1, 0.82, 0)
    texture:SetSize(3, 10)
    texture:SetPoint("CENTER", offsetX, 0)
    return texture
end

function UI:SavePosition()
    local point,
        relativeFrame,
        relativePoint,
        offsetX,
        offsetY = self.frame:GetPoint()
    local window = addon.database.window
    window.point          = point
    window.relativePoint  = relativePoint
    window.x              = offsetX
    window.y              = offsetY
end

function UI:Refresh()
    if not self.frame or not self.frame:IsShown() then
        return
    end
    local database  = addon.database
    local stepText  = BreakUpLargeNumbers and BreakUpLargeNumbers(database.steps)
        or string.format("%.0f", database.steps)
    self.steps:SetText(stepText)
    local fontPath = self.steps:GetFont()
    self.steps:SetFont(fontPath, 28, "OUTLINE")
    local textWidth       = self.steps:GetStringWidth()
    local availableWidth  = self.frame:GetWidth() - 32
    if textWidth > availableWidth then
        self.steps:SetFont(fontPath, math.max(1, math.floor(28 * availableWidth / textWidth)), "OUTLINE")
    end
    local kilometers, miles = addon.Counter:GetDistance()
    self.distance:SetText(string.format("%.2f km / %.2f mi", kilometers, miles))
    local distanceFont = self.distance:GetFont()
    self.distance:SetFont(distanceFont, 12)
    local distanceWidth = self.distance:GetStringWidth()
    if distanceWidth > availableWidth then
        self.distance:SetFont(distanceFont, math.max(1, math.floor(12 * availableWidth / distanceWidth)))
    end
    self.distance:SetTextColor(database.paused and 0.65 or 1, database.paused and 0.65 or 0.82, database.paused and 0.65 or 0)
    self.frame.tooltipText = "Estimated on-foot distance\n" .. (addon.status or (database.paused and "Paused" or "Tracking"))
    if GameTooltip:IsOwned(self.frame) then
        GameTooltip:SetText(self.frame.tooltipText)
    end
    self.playButton.playIcon:SetShown(database.paused)
    self.playButton.pauseLeft:SetShown(not database.paused)
    self.playButton.pauseRight:SetShown(not database.paused)
    self.playButton.tooltipText = database.paused and "Play" or "Pause"
    if GameTooltip:IsOwned(self.playButton) then
        GameTooltip:SetText(self.playButton.tooltipText)
    end
end

function UI:Build()
    if self.frame then
        return
    end
    if type(addon.database.window) ~= "table" then
        addon.database.window = {}
    end
    local window  = addon.database.window
    local frame   = CreateFrame("Frame", "Batata_Step_Counter_Window", UIParent, "PortraitFrameTemplateMinimizable")
    self.frame = frame
    frame:Hide()
    frame:SetSize(238, 148)
    frame:SetTitle("Batata Step Counter")
    frame:SetTitleOffsets(58, -34)
    frame:GetTitleText():SetJustifyH("CENTER")
    frame:SetPortraitToAsset(ICON_TEXTURE)
    frame.TopTileStreaks:Hide()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if type(window.point) == "string"
        and ANCHORS[window.point]
        and type(window.relativePoint) == "string"
        and ANCHORS[window.relativePoint]
        and type(window.x) == "number"
        and window.x == window.x
        and math.abs(window.x) < math.huge
        and type(window.y) == "number"
        and window.y == window.y
        and math.abs(window.y) < math.huge
    then
        frame:ClearAllPoints()
        frame:SetPoint(window.point, UIParent, window.relativePoint, window.x, window.y)
    end
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    Tooltip(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(control)
        control:StopMovingOrSizing()
        self:SavePosition()
    end)
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 4, -56)
    inset:SetPoint("BOTTOMRIGHT", -6, 40)
    inset:EnableMouse(false)
    inset.Bg:SetAtlas("Professions-background-summarylist")
    inset.Bg:SetHorizTile(false)
    inset.Bg:SetVertTile(false)
    inset.NineSlice:Hide()

    self.steps = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.steps:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -61)
    self.steps:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -61)
    self.steps:SetHeight(32)
    self.steps:SetJustifyH("CENTER")
    self.steps:SetWordWrap(false)

    self.distance = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.distance:SetPoint("TOP", frame, "TOP", 0, -96)
    self.distance:SetSize(206, 12)
    self.distance:SetWordWrap(false)

    self.playButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.playButton:SetSize(30, 22)
    self.playButton:SetPoint("BOTTOM", frame, "BOTTOM", -18, 10)
    self.playButton.playIcon = self.playButton:CreateTexture(nil, "ARTWORK")
    self.playButton.playIcon:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    self.playButton.playIcon:SetSize(16, 16)
    self.playButton.playIcon:SetPoint("CENTER", 2, 0)
    self.playButton.pauseLeft   = PauseBar(self.playButton, -3)
    self.playButton.pauseRight  = PauseBar(self.playButton, 3)
    self.playButton:SetScript("OnClick", function()
        addon:TogglePaused()
    end)
    Tooltip(self.playButton)

    self.resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.resetButton:SetSize(30, 22)
    self.resetButton:SetPoint("LEFT", self.playButton, "RIGHT", 6, 0)
    self.resetButton.icon = self.resetButton:CreateTexture(nil, "ARTWORK")
    self.resetButton.icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    self.resetButton.icon:SetSize(16, 16)
    self.resetButton.icon:SetPoint("CENTER")
    self.resetButton.tooltipText = "Reset steps and distance"
    self.resetButton:SetScript("OnClick", function()
        addon:Reset()
    end)
    Tooltip(self.resetButton)

    frame:HookScript("OnShow", function()
        window.hidden = false
        self:Refresh()
    end)
    frame:HookScript("OnHide", function()
        window.hidden = true
    end)
    UISpecialFrames[#UISpecialFrames + 1] = "Batata_Step_Counter_Window"
    frame:SetShown(not window.hidden)
end