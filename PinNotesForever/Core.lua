local addonName, PNF = ...

PNF = PNF or _G.PinNotesForever or {}
_G.PinNotesForever = PNF

PNF.ADDON_NAME = addonName
PNF.VERSION = "0.1.0-beta"

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff33ccffPinNotes Forever:|r " .. tostring(message)
    )
end

PNF.Print = Print

local function CountWaypoints()
    local count = 0

    for _ in pairs(PNF:GetWaypoints()) do
        count = count + 1
    end

    return count
end

local function ShowHelp()
    Print("Version " .. PNF.VERSION)
    Print("Commands:")
    Print("/pinnotes - Open PinNotes Forever")
    Print("/pinnotes count - Show number of saved waypoints")
    Print("/pinnotes refresh - Refresh saved map pins")
    Print("/pinnotes help - Show this help")
end

SLASH_PINNOTESFOREVER1 = "/pinnotes"
SLASH_PINNOTESFOREVER2 = "/pnf"

SlashCmdList["PINNOTESFOREVER"] = function(message)
    message = strtrim(string.lower(message or ""))

    if message == "count" then
        local count = CountWaypoints()

        if count == 1 then
            Print("1 saved waypoint.")
        else
            Print(count .. " saved waypoints.")
        end

        return
    end

    if message == "refresh" then
        if PNF.RefreshMapPins then
            PNF:RefreshMapPins()
            Print("Map pins refreshed.")
        else
            Print("Map pin system is not available.")
        end

        return
    end

    if message == "help" then
        ShowHelp()
        return
    end

    if PNF.ToggleWaypointList then
        PNF:ToggleWaypointList()
    else
        Print(
            "PinNotes Forever is loaded. " ..
            "The waypoint window is not available yet."
        )
    end
end

local function InitializeMapSystem()
    if not PNF.InitializeMapPins then
        return false
    end

    local success = PNF:InitializeMapPins()

    if success then
        PNF:RefreshMapPins()
    end

    return success
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then
            return
        end

        PNF:InitializeDatabase()

        Print(
            "v" ..
            PNF.VERSION ..
            " loaded. Type /pinnotes to get started."
        )

        InitializeMapSystem()

        return
    end

    if event == "PLAYER_LOGIN" then
        InitializeMapSystem()
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
    end
end)
