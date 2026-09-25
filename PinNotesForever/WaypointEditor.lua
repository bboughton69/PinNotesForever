local addonName, PNF = ...

PNF = PNF or _G.PinNotesForever or {}
_G.PinNotesForever = PNF

local editor

local function RefreshEverything()
    if PNF.RefreshMapPins then
        PNF:RefreshMapPins()
    end

    if PNF.RefreshWaypointList then
        PNF:RefreshWaypointList()
    end
end

local function SetStatus(message, isError)
    if not editor or not editor.StatusText then
        return
    end

    editor.StatusText:SetText(message or "")

    if isError then
        editor.StatusText:SetTextColor(1, 0.25, 0.25)
    else
        editor.StatusText:SetTextColor(0.35, 1, 0.35)
    end
end

local function SaveWaypoint()
    if not editor then
        return
    end

    local name = strtrim(editor.NameEditBox:GetText() or "")

    if name == "" then
        SetStatus("Please enter a name for this PinNote.", true)
        editor.NameEditBox:SetFocus()
        return
    end

    if editor.waypoint then
        local success, errorMessage =
            PNF:RenameWaypoint(
                editor.waypoint.id,
                name
            )

        if not success then
            SetStatus(
                errorMessage or "Unable to rename PinNote.",
                true
            )
            return
        end

        editor.waypoint.name = name

        RefreshEverything()

        if PNF.Print then
            PNF.Print("Updated \"" .. name .. "\".")
        end

        editor:Hide()
        return
    end

    if not editor.mapID or not editor.x or not editor.y then
        SetStatus("Map location is unavailable.", true)
        return
    end

    local waypoint, errorMessage =
        PNF:CreateWaypoint(
            editor.mapID,
            editor.x,
            editor.y,
            name,
            "General"
        )

    if not waypoint then
        SetStatus(
            errorMessage or "Unable to save PinNote.",
            true
        )
        return
    end

    RefreshEverything()

    if PNF.Print then
        PNF.Print(
            string.format(
                "Saved \"%s\" at %.1f, %.1f.",
                waypoint.name,
                waypoint.x * 100,
                waypoint.y * 100
            )
        )
    end

    editor:Hide()
end

local function CreateEditor()
    if editor then
        return editor
    end

    editor = CreateFrame(
        "Frame",
        "PinNotesForeverWaypointEditor",
        UIParent,
        "BasicFrameTemplateWithInset"
    )

    editor:SetSize(360, 220)
    editor:SetPoint("CENTER")
    editor:SetFrameStrata("DIALOG")
    editor:SetClampedToScreen(true)
    editor:EnableMouse(true)
    editor:SetMovable(true)
    editor:RegisterForDrag("LeftButton")

    editor:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    editor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    editor:Hide()

    editor.TitleText:SetText("PinNotes Forever")

    local heading = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )

    heading:SetPoint(
        "TOPLEFT",
        editor,
        "TOPLEFT",
        24,
        -42
    )

    heading:SetText("Name this PinNote")

    local instruction = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    instruction:SetPoint(
        "TOPLEFT",
        heading,
        "BOTTOMLEFT",
        0,
        -8
    )

    instruction:SetText(
        "Give this saved map location a name you'll recognize."
    )

    local nameLabel = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    nameLabel:SetPoint(
        "TOPLEFT",
        instruction,
        "BOTTOMLEFT",
        0,
        -18
    )

    nameLabel:SetText("Name")

    local nameBox = CreateFrame(
        "EditBox",
        nil,
        editor,
        "InputBoxTemplate"
    )

    nameBox:SetSize(300, 30)
    nameBox:SetPoint(
        "TOPLEFT",
        nameLabel,
        "BOTTOMLEFT",
        4,
        -4
    )

    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(80)

    nameBox:SetScript("OnEnterPressed", function()
        SaveWaypoint()
    end)

    nameBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        editor:Hide()
    end)

    editor.NameEditBox = nameBox

    local coords = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    coords:SetPoint(
        "TOPLEFT",
        nameBox,
        "BOTTOMLEFT",
        -4,
        -10
    )

    coords:SetText("")
    editor.CoordinatesText = coords

    local status = editor:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

    status:SetPoint(
        "BOTTOMLEFT",
        editor,
        "BOTTOMLEFT",
        24,
        20
    )

    status:SetWidth(190)
    status:SetJustifyH("LEFT")
    status:SetText("")

    editor.StatusText = status

    local cancelButton = CreateFrame(
        "Button",
        nil,
        editor,
        "UIPanelButtonTemplate"
    )

    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint(
        "BOTTOMRIGHT",
        editor,
        "BOTTOMRIGHT",
        -20,
        16
    )

    cancelButton:SetText("Cancel")

    cancelButton:SetScript("OnClick", function()
        editor:Hide()
    end)

    local saveButton = CreateFrame(
        "Button",
        nil,
        editor,
        "UIPanelButtonTemplate"
    )

    saveButton:SetSize(80, 24)
    saveButton:SetPoint(
        "RIGHT",
        cancelButton,
        "LEFT",
        -8,
        0
    )

    saveButton:SetText("Save")

    saveButton:SetScript("OnClick", function()
        SaveWaypoint()
    end)

    editor.SaveButton = saveButton

    return editor
end

function PNF:OpenWaypointEditor(waypoint, mapID, x, y)
    local frame = CreateEditor()

    frame.waypoint = waypoint
    frame.mapID = mapID
    frame.x = x
    frame.y = y

    SetStatus("")

    if waypoint then
        frame.NameEditBox:SetText(
            waypoint.name or ""
        )

        frame.CoordinatesText:SetText(
            string.format(
                "Coordinates: %.1f, %.1f",
                waypoint.x * 100,
                waypoint.y * 100
            )
        )

        frame.SaveButton:SetText("Update")
    else
        frame.NameEditBox:SetText("")

        frame.CoordinatesText:SetText(
            string.format(
                "Coordinates: %.1f, %.1f",
                (x or 0) * 100,
                (y or 0) * 100
            )
        )

        frame.SaveButton:SetText("Save")
    end

    frame:Show()
    frame:Raise()

    frame.NameEditBox:SetFocus()
    frame.NameEditBox:HighlightText()
end
