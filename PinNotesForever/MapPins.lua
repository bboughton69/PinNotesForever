local addonName, PNF = ...

PNF = PNF or _G.PinNotesForever or {}
_G.PinNotesForever = PNF

local PIN_TEMPLATE = "PinNotesForeverMapPinTemplate"

PinNotesForeverMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function PinNotesForeverMapPinMixin:OnLoad()
    self:SetSize(26, 26)

    if self.UseFrameLevelType then
        self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    end

    if self.SetScalingLimits then
        self:SetScalingLimits(1, 1.0, 1.2)
    end

    self:SetMouseMotionEnabled(true)
    self:SetMouseClickEnabled(true)

    self.Icon = self.Icon or self:CreateTexture(nil, "ARTWORK")
    self.Icon:SetAllPoints()
    self.Icon:SetTexture("Interface\\MINIMAP\\POIIcons")
    self.Icon:SetTexCoord(
        0.125, 0.25,
        0.125, 0.25
    )
end

function PinNotesForeverMapPinMixin:OnAcquired(waypoint)
    self.waypoint = waypoint

    self:SetPosition(
        waypoint.x,
        waypoint.y
    )
end

function PinNotesForeverMapPinMixin:OnReleased()
    self.waypoint = nil

    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

function PinNotesForeverMapPinMixin:OnMouseEnter()
    local waypoint = self.waypoint

    if not waypoint then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    GameTooltip:SetText(
        waypoint.name or "PinNote",
        1,
        1,
        1
    )

    GameTooltip:AddLine(
        waypoint.category or "General",
        0.35,
        0.8,
        1
    )

    GameTooltip:AddLine(
        string.format(
            "%.1f, %.1f",
            waypoint.x * 100,
            waypoint.y * 100
        ),
        0.8,
        0.8,
        0.8
    )

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(
        "Left-click: Edit",
        0.7,
        0.7,
        0.7
    )

    GameTooltip:AddLine(
        "Shift + Right-click: Delete",
        0.7,
        0.7,
        0.7
    )

    GameTooltip:Show()
end

function PinNotesForeverMapPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

function PinNotesForeverMapPinMixin:OnClick(button)
    local waypoint = self.waypoint

    if not waypoint then
        return
    end

    if button == "LeftButton" then
        if PNF.OpenWaypointEditor then
            PNF:OpenWaypointEditor(waypoint)
        end

        return
    end

    if button == "RightButton" and IsShiftKeyDown() then
        if PNF.ConfirmDeleteWaypoint then
            PNF:ConfirmDeleteWaypoint(waypoint)
        end
    end
end

PinNotesForeverDataProviderMixin =
    CreateFromMixins(MapCanvasDataProviderMixin)

function PinNotesForeverDataProviderMixin:RemoveAllData()
    local map = self:GetMap()

    if map then
        map:RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end
end

function PinNotesForeverDataProviderMixin:RefreshAllData()
    self:RemoveAllData()

    local map = self:GetMap()

    if not map then
        return
    end

    local mapID = map:GetMapID()

    if not mapID then
        return
    end

    if not PNF.db then
        return
    end

    if PNF.db.settings.showPins == false then
        return
    end

    local waypoints = PNF:GetWaypointsForMap(mapID)

    for _, waypoint in ipairs(waypoints) do
        map:AcquirePin(
            PIN_TEMPLATE,
            waypoint
        )
    end
end

function PNF:RefreshMapPins()
    if self.mapDataProvider then
        self.mapDataProvider:RefreshAllData()
    end
end

local function HandleMapClick(button)
    if button ~= "RightButton" then
        return false
    end

    if not IsControlKeyDown() then
        return false
    end

    if not WorldMapFrame then
        return false
    end

    local mapID = WorldMapFrame:GetMapID()

    if not mapID then
        return false
    end

    local x, y = WorldMapFrame:GetNormalizedCursorPosition()

    if not x or not y then
        return false
    end

    if x < 0 or x > 1 or y < 0 or y > 1 then
        return false
    end

    if PNF.OpenWaypointEditor then
        PNF:OpenWaypointEditor(
            nil,
            mapID,
            x,
            y
        )

        return true
    end

    return false
end

function PNF:InitializeMapPins()
    if self.mapPinsInitialized then
        return true
    end

    if not WorldMapFrame then
        return false
    end

    if not WorldMapFrame.AddDataProvider then
        return false
    end

    if not WorldMapFrame.AcquirePin then
        return false
    end

    if WorldMapFrame.SetPinTemplateType then
        WorldMapFrame:SetPinTemplateType(
            PIN_TEMPLATE,
            "FRAME"
        )
    end

    self.mapDataProvider =
        CreateFromMixins(
            PinNotesForeverDataProviderMixin
        )

    WorldMapFrame:AddDataProvider(
        self.mapDataProvider
    )

    if WorldMapFrame.AddCanvasClickHandler then
        WorldMapFrame:AddCanvasClickHandler(
            HandleMapClick,
            50
        )
    end

    self.mapPinsInitialized = true

    return true
end
