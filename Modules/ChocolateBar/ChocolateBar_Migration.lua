--migration stub to make WoW load ChocolateBarDB from ChocolateBar.lua under the SavedVariables folder.local loaded, reason = LoadAddOn("MyAddon_Config")
local ArcanaMigrate = LibStub("AceAddon-3.0"):NewAddon("ArcanaMigrate")

-- global DB name migration helpers
local function HasData(tbl)
    return type(tbl) == "table" and next(tbl) ~= nil
end

-- bar name migration helpers
local function barNameIsDeprecated(name)
    if name:match("^ChocolateBar%d+$") then
        return true
    end
end

local function convertDeprecatedBarName(name)
    local n = name:match("^ChocolateBar(%d+)$")
    if n then
        return "Arcana" .. n
    end
end

local function migrateBarNames(db)
    local barSettings = db.barSettings
    local toRename = {}
    -- collect
    for oldName, settings in pairs(barSettings) do
        local newName = convertDeprecatedBarName(oldName)
        if newName and newName ~= oldName then
            toRename[#toRename + 1] = { oldName, newName, settings }
        end
    end
    -- apply
    for _, item in ipairs(toRename) do
        local oldName, newName, settings = item[1], item[2], item[3]
        barSettings[newName] = settings
        barSettings[oldName] = nil
        settings.barName = newName
    end
end

local function migrateArcanaPicesSettings(db)
    local settings = db.objSettings
    local barName = settings.barName
    if barName and barNameIsDeprecated(barName) then
        barName = convertDeprecatedBarName(barName)
        settings.barName = barName --store new bar name in the plugin settings
    end
end


--migrate textures
local pathMap = {
    ["Interface\\AddOns\\Arcana\\pics\\chocolatebar"]          = "Interface\\AddOns\\Arcana\\Media\\ArcanaBar",
    ["Interface\\AddOns\\Arcana\\pics\\chocolatbarGray"]       = "Interface\\AddOns\\Arcana\\Media\\ArcanaBarGray",
    ["Interface\\AddOns\\Arcana\\pics\\Gloss"]                 = "Interface\\AddOns\\Arcana\\Media\\Gloss",
    ["Interface\\AddOns\\Arcana\\pics\\DarkBottom"]            = "Interface\\AddOns\\Arcana\\Media\\DarkBottom",
    ["Interface\\AddOns\\Arcana\\pics\\Titan"]                 = "Interface\\AddOns\\Arcana\\Media\\Titan",
    ["Interface\\AddOns\\Arcana\\pics\\Tribal"]                = "Interface\\AddOns\\Arcana\\Media\\Tribal",
    ["Interface\\AddOns\\ChocloateBar\\pics\\chocolatebar"]    = "Interface\\AddOns\\Arcana\\Media\\ArcanaBar",
    ["Interface\\AddOns\\ChocloateBar\\pics\\chocolatbarGray"] = "Interface\\AddOns\\Arcana\\Media\\ArcanaBarGray",
    ["Interface\\AddOns\\ChocloateBar\\pics\\Gloss"]           = "Interface\\AddOns\\Arcana\\Media\\Gloss",
    ["Interface\\AddOns\\ChocloateBar\\pics\\DarkBottom"]      = "Interface\\AddOns\\Arcana\\Media\\DarkBottom",
    ["Interface\\AddOns\\ChocloateBar\\pics\\Titan"]           = "Interface\\AddOns\\Arcana\\Media\\Titan",
    ["Interface\\AddOns\\ChocloateBar\\pics\\Tribal"]          = "Interface\\AddOns\\Arcana\\Media\\Tribal",
}

local function migrateTexturePaths(tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            migrateTexturePaths(v)
        elseif k == "texture" and type(v) == "string" then
            tbl[k] = pathMap[v] or v
        end
    end
end

--local f = CreateFrame("Frame")
--f:RegisterEvent("ADDON_LOADED")
--f:SetScript("OnEvent", function(_, event, addon)
--    if addon == "ChocolateBar" then
--        print("|cff88ccffArcana Debug|r", "ChocolateBar Migration Loaded")
--    end
--end)

function ArcanaMigrate:MigareDB()
    local oldDB = ChocolateBarDB
    if not HasData(oldDB) then
        print("|cff88ccffArcana|r", "ChocolateBar migration loaded, but oldDB is empty. Creating new ArcanaDB.")
        return nil
    end

    print("|cff88ccffArcana|r ", "Doing profile migration...")

    if not ChocolateBarDB.profiles then
        print("|cff88ccffArcana|r",
            "ChocolateBar migration loaded, but ChocolateBarDB.profiles not found. Creating new ArcanaDB.")
    end

    for _, profile in pairs(ChocolateBarDB.profiles) do
        migrateBarNames(profile)
        migrateArcanaPicesSettings(profile)
        migrateTexturePaths(profile)
    end

    return oldDB
end
