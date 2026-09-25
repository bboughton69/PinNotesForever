local addonName, PNF = ...

PNF = PNF or {}
_G.PinNotesForever = PNF

PNF.DB_VERSION = 1

local function EnsureDatabase()
    if type(PinNotesForeverDB) ~= "table" then
        PinNotesForeverDB = {}
    end

    PinNotesForeverDB.version = PinNotesForeverDB.version or PNF.DB_VERSION
    PinNotesForeverDB.waypoints = PinNotesForeverDB.waypoints or {}
    PinNotesForeverDB.settings = PinNotesForeverDB.settings or {}

    if PinNotesForeverDB.settings.showPins == nil then
        PinNotesForeverDB.settings.showPins = true
    end

    if PinNotesForeverDB.settings.showLabels == nil then
        PinNotesForeverDB.settings.showLabels = true
    end

    PNF.db = PinNotesForeverDB
end

function PNF:InitializeDatabase()
    EnsureDatabase()
end

function PNF:GetWaypoints()
    EnsureDatabase()
    return self.db.waypoints
end

function PNF:GetWaypoint(id)
    EnsureDatabase()
    return self.db.waypoints[id]
end

function PNF:CreateWaypoint(mapID, x, y, name, category)
    EnsureDatabase()

    if type(mapID) ~= "number" then
        return nil, "Invalid map ID."
    end

    if type(x) ~= "number" or type(y) ~= "number" then
        return nil, "Invalid coordinates."
    end

    name = strtrim(tostring(name or ""))

    if name == "" then
        return nil, "Waypoint name cannot be empty."
    end

    local id = tostring(time()) .. "-" .. tostring(math.random(100000, 999999))

    while self.db.waypoints[id] do
        id = tostring(time()) .. "-" .. tostring(math.random(100000, 999999))
    end

    local waypoint = {
        id = id,
        name = name,
        category = category or "General",
        mapID = mapID,
        x = x,
        y = y,
        created = time(),
    }

    self.db.waypoints[id] = waypoint

    return waypoint
end

function PNF:RenameWaypoint(id, newName)
    EnsureDatabase()

    local waypoint = self.db.waypoints[id]

    if not waypoint then
        return false, "Waypoint not found."
    end

    newName = strtrim(tostring(newName or ""))

    if newName == "" then
        return false, "Waypoint name cannot be empty."
    end

    waypoint.name = newName

    return true
end

function PNF:DeleteWaypoint(id)
    EnsureDatabase()

    if not self.db.waypoints[id] then
        return false, "Waypoint not found."
    end

    self.db.waypoints[id] = nil

    return true
end

function PNF:GetWaypointsForMap(mapID)
    EnsureDatabase()

    local results = {}

    for _, waypoint in pairs(self.db.waypoints) do
        if waypoint.mapID == mapID then
            table.insert(results, waypoint)
        end
    end

    table.sort(results, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    return results
end
