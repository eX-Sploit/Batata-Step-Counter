local addonName,
    addon = ...

local MinimapButton = {}
addon.MinimapButton = MinimapButton

local function Place(button, angle)
    local radians  = math.rad(angle)
    local radiusX  = Minimap:GetWidth() / 2 + 5
    local radiusY  = Minimap:GetHeight() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radiusX, math.sin(radians) * radiusY)
end

local function FollowCursor(button, elapsedSeconds)
    local centerX,
        centerY = Minimap:GetCenter()
    if not centerX or not centerY then
        return
    end
    local cursorX,
        cursorY = GetCursorPosition()
    local scale  = Minimap:GetEffectiveScale()
    local angle  = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
    addon.database.minimap.angle = math.floor(angle + 0.5) % 360
    Place(button, addon.database.minimap.angle)
end

function MinimapButton:Build()
    if self.button or not Minimap then
        return
    end
    if type(addon.database.minimap) ~= "table" then
        addon.database.minimap = {}
    end
    local settings = addon.database.minimap
    if type(settings.angle) ~= "number" or settings.angle ~= settings.angle or math.abs(settings.angle) == math.huge then
        settings.angle = 200
    end
    settings.angle = settings.angle % 360

    local button = CreateFrame("Button", "Batata_Step_Counter_MinimapButton", Minimap)
    self.button = button
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    self.icon = button:CreateTexture(nil, "ARTWORK")
    self.icon:SetSize(17, 17)
    self.icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Assets\\batata-step-counter.tga")
    self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    self.icon:SetPoint("TOPLEFT", 7, -6)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function()
        addon.UI.frame:SetShown(not addon.UI.frame:IsShown())
    end)
    button:SetScript("OnDragStart", function(control)
        GameTooltip:Hide()
        control:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(control)
        control:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_LEFT")
        GameTooltip:SetText("Batata Step Counter")
        GameTooltip:AddLine("Click to show or hide. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnHide", function(control)
        control:SetScript("OnUpdate", nil)
        if GameTooltip:IsOwned(control) then
            GameTooltip:Hide()
        end
    end)
    Place(button, settings.angle)
end