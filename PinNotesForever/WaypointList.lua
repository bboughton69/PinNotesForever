local addonName, PNF = ...

PNF = PNF or _G.PinNotesForever or {}
_G.PinNotesForever = PNF

local listFrame
local rows = {}

local function GetMapName(mapID)
    if not mapID or not C_Map or not C_Map.GetMapInfo then
        return "Unknown Map"
    end

    local mapInfo = C_Map.GetMapInfo(mapID)

    if mapInfo and mapInfo.name then
        return mapInfo.name
    end

    return "Map " .. tostring(mapID)
end

local function GetSortedWaypoints()
    local waypoints = {}

    for _, waypoint in pairs(PNF:GetWaypoints()) do
        table.insert(waypoints, waypoint)
    end

    table.sort(waypoints, function(a, b)
        local mapA = GetMapName(a.mapID)
        local mapB = GetMapName(b.mapID)

        if mapA == mapB then
            return string.lower(a.name or "") <
                string.lower(b.name or "")
        end

        return string.lower(mapA) <
            string.lower(mapB)
    end)

    return waypoints
end

local function HideRows()
    for _, row in ipairs(rows) do
        row:Hide()
    end
end

local function CreateRow(parent, index)
    local row = CreateFrame(
        "Frame",
        nil,
        parent
    )

    row:SetHeight(44)

    if index == 1 then
        row:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            0,
            0
        )
    else
        row:SetPoint(
            "TOPLEFT",
            rows[index - 1],
            "BOTTOMLEFT",
            0,
            -4
        )
    end

    row:SetPoint(
        "RIGHT",
        parent,
        "RIGHT",
        0,
        0
    )

    local nameText = row:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    nameText:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        4,
        -4
    )

    nameText:SetWidth(230)
    nameText:SetJustifyH("LEFT")

    row.NameText = nameText

    local detailText = row:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    detailText:SetPoint(
        "TOPLEFT",
        nameText,
        "BOTTOMLEFT",
        0,
        -3
    )

    detailText:SetWidth(270)
    detailText:SetJustifyH("LEFT")

    row.DetailText = detailText

    local editButton = CreateFrame(
        "Button",
        nil,
        row,
        "UIPanelButtonTemplate"
    )

    editButton:SetSize(55, 22)
    editButton:SetPoint(
        "RIGHT",
        row,
        "RIGHT",
        -70,
        0
    )

    editButton:SetText("Edit")

    editButton:SetScript("OnClick", function()
        if row.waypoint and PNF.OpenWaypointEditor then
            PNF:OpenWaypointEditor(row.waypoint)
        end
    end)

    row.EditButton = editButton

    local deleteButton = CreateFrame(
        "Button",
        nil,
        row,
        "UIPanelButtonTemplate"
    )

    deleteButton:SetSize(60, 22)
    deleteButton:SetPoint(
        "LEFT",
        editButton,
        "RIGHT",
        6,
        0
    )

    deleteButton:SetText("Delete")

    deleteButton:SetScript("OnClick", function()
        if row.waypoint and PNF.ConfirmDeleteWaypoint then
            PNF:ConfirmDeleteWaypoint(row.waypoint)
        end
    end)

    row.DeleteButton = deleteButton

    rows[index] = row

    return row
end

local function CreateListFrame()
    if listFrame then
        return listFrame
    end

    listFrame = CreateFrame(
        "Frame",
        "PinNotesForeverWaypointList",
        UIParent,
        "BasicFrameTemplateWithInset"
    )

    listFrame:SetSize(470, 520)
    listFrame:SetPoint("CENTER")
    listFrame:SetFrameStrata("DIALOG")
    listFrame:SetClampedToScreen(true)
    listFrame:SetMovable(true)
    listFrame:EnableMouse(true)
    listFrame:RegisterForDrag("LeftButton")

    listFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    listFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    listFrame.TitleText:SetText("PinNotes Forever")

    local subtitle = listFrame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )

    subtitle:SetPoint(
        "TOPLEFT",
        listFrame,
        "TOPLEFT",
        22,
        -40
    )

    subtitle:SetText(
        "Saved PinNotes - shared across all characters"
    )

    local help = listFrame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    help:SetPoint(
        "TOPLEFT",
        subtitle,
        "BOTTOMLEFT",
        0,
        -6
    )

    help:SetText(
        "Ctrl + Right-click the World Map to create a new PinNote."
    )

    local scrollFrame = CreateFrame(
        "ScrollFrame",
        "PinNotesForeverWaypointScrollFrame",
        listFrame,
        "UIPanelScrollFrameTemplate"
    )

    scrollFrame:SetPoint(
        "TOPLEFT",
        listFrame,
        "TOPLEFT",
        22,
        -82
    )

    scrollFrame:SetPoint(
        "BOTTOMRIGHT",
        listFrame,
        "BOTTOMRIGHT",
        -38,
        24
    )

    local content = CreateFrame(
        "Frame",
        nil,
        scrollFrame
    )

    content:SetSize(400, 1)

    scrollFrame:SetScrollChild(content)

    listFrame.ScrollFrame = scrollFrame
    listFrame.Content = content

    local emptyText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )

    emptyText:SetPoint(
        "TOP",
        content,
        "TOP",
        0,
        -30
    )

    emptyText:SetText(
        "No PinNotes saved yet.\n\n" ..
        "Open the World Map and Ctrl + Right-click\n" ..
        "where you want to save one."
    )

    listFrame.EmptyText = emptyText

    listFrame:Hide()

    return listFrame
end

function PNF:RefreshWaypointList()
    if not listFrame then
        return
    end

    HideRows()

    local waypoints = GetSortedWaypoints()
    local content = listFrame.Content

    if #waypoints == 0 then
        listFrame.EmptyText:Show()
        content:SetHeight(380)
        return
    end

    listFrame.EmptyText:Hide()

    for index, waypoint in ipairs(waypoints) do
        local row = rows[index]

        if not row then
            row = CreateRow(content, index)
        end

        row.waypoint = waypoint

        row.NameText:SetText(
            waypoint.name or "Unnamed PinNote"
        )

        row.DetailText:SetText(
            string.format(
                "%s  |  %.1f, %.1f",
                GetMapName(waypoint.mapID),
                waypoint.x * 100,
                waypoint.y * 100
            )
        )

        row:Show()
    end

    content:SetHeight(
        math.max(
            380,
            (#waypoints * 48) + 10
        )
    )
end

function PNF:ToggleWaypointList()
    local frame = CreateListFrame()

    if frame:IsShown() then
        frame:Hide()
        return
    end

    self:RefreshWaypointList()
    frame:Show()
    frame:Raise()
end

StaticPopupDialogs["PINNOTES_FOREVER_DELETE"] = {
    text = "Delete this PinNote?",
    button1 = DELETE,
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,

    OnAccept = function(self, data)
        if not data or not data.id then
            return
        end

        local name = data.name or "PinNote"

        local success, errorMessage =
            PNF:DeleteWaypoint(data.id)

        if not success then
            if PNF.Print then
                PNF.Print(
                    errorMessage or "Unable to delete PinNote."
                )
            end

            return
        end

        if PNF.RefreshMapPins then
            PNF:RefreshMapPins()
        end

        if PNF.RefreshWaypointList then
            PNF:RefreshWaypointList()
        end

        if PNF.Print then
            PNF.Print("Deleted \"" .. name .. "\".")
        end
    end,
}

function PNF:ConfirmDeleteWaypoint(waypoint)
    if not waypoint then
        return
    end

    StaticPopup_Show(
        "PINNOTES_FOREVER_DELETE",
        nil,
        nil,
        waypoint
    )
end
