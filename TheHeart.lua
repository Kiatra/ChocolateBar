-- ✧────────────────────────────────────────────────────✧
--  Arcana
--  TheHeart.lua
--
--  The not-so-dark heart of Arcana.
--  A little bit of logic, a little bit of magic.
--
--  Made with love by Kiatra ♡
--
--  Special thanks to:
-- ✧────────────────────────────────────────────────────✧
--  the WoW addon community
--  for years of shared knowledge and inspiration.
--
-- ✧────────────────────────────────────────────────────✧
--  Rosa for the trust in us making
--      magic happen responsibly.
--
--  Ray for the fun we had creating in school.
--  Alundira/Alexwild for seeing me before I was me.
-- ✧────────────────────────────────────────────────────✧
--  Everyone who submitted a friendly bug report ;)
-- ✧────────────────────────────────────────────────────✧
local LibStub, broker, LSM = LibStub, LibStub("LibDataBroker-1.1"), LibStub("LibSharedMedia-3.0")
local Arcana = LibStub("AceAddon-3.0"):NewAddon("Arcana", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")
local _G, pairs, ipairs, table, string, tostring = _G, pairs, ipairs, table, string, tostring
local select, strjoin, CreateFrame = select, strjoin, CreateFrame

local _, _, _, tocversion = GetBuildInfo()

local addonVersion = C_AddOns.GetAddOnMetadata("Arcana", "Version")

Arcana.Jostle = {}
Arcana.Bar = {}
Arcana.ArcanaPiece = {}
Arcana.Drag = {}
Arcana.modules = {}

local Drag = Arcana.Drag
local ArcanaPiece = Arcana.ArcanaPiece
local Bar = Arcana.Bar

local arcanaBars = {}
local pluginObjects = {}
local db --reference to Arcana.db.profile

--------
-- utility functions
--------
local function debug(...)
    if Arcana.db and Arcana.db.char.debug then
        local s = "CB:"
        for i = 1, select("#", ...) do
            local x = select(i, ...)
            s = strjoin(" ", s, tostring(x))
        end
        print("|cff88ccffArcana Debug|r", s)
    end
end

function Arcana:Debug(...)
    debug(self, ...)
end

function Arcana:Log(...)
    debug(self, ...)
end

local defaults = {
    profile = {
        petBattleHideBars = true,
        combatopacity = 1,
        scale = 1,
        height = 21,
        iconSize = 0.75,
        moveFrames = true,
        adjustCenter = true,
        strata = "BACKGROUND",
        barRightClick = "BLIZZ",
        gap = 7,
        textOffset = 1,
        moreBar = "none",
        moreBarDelay = 4,
        fontPath = " ",
        fontSize = 12,
        labelColor = { r = 1, g = 0.82, b = 0, a = 1 },
        background = {
            textureName = "Arcana Gold",
            texture = "Interface\\AddOns\\Arcana\\Media\\ArcanaBar",
            borderTexture = "Tooltip-Border",
            color = { r = 0.38, g = 0.36, b = 0.4, a = .94, },
            borderColor = { r = 0, g = 0, b = 0, a = 0, },
            tileSize = 130,
            edgeSize = 8,
            barInset = 3,
        },
        moduleSettings = {
            ['*'] = {
                enabled = false,
            }
        },
        barSettings = {
            ['*'] = {
                barName = "Arcana1", align = "top", enabled = true, index = 10, width = 0, opacity = 1, opacityMouseOver = 1,
            },
            ['Arcana1'] = {
                barName = "Arcana1", align = "top", enabled = true, index = 1, width = 0, opacity = 1, opacityMouseOver = 1,
            },
        },
        placeholderNames = {},
        objSettings = {
            ['*'] = {
                barName = "",
                align = "left",
                enabled = true,
                showText = true,
                showLabel = false,
                showIcon = true,
                index = 500,
                width = 0,
                isNew = true
            },
        },
    },
    char = {
        debug = false,
    }
}

-- global DB name migration helpers
local function HasData(tbl)
    return type(tbl) == "table" and next(tbl) ~= nil
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, addon)
    if addon == "ChocolateBar" then
        Arcana:AddonLoaded()
    end
end)

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

--------
-- Ace3 callbacks
--------
--- we want to load after old DB was loead from the old name of the addon for the migration
--[[
function Arcana:OnInitialize()
    print("|cff88ccffArcana Debug|r", "OnInitialize")
end
]]

--OnInitialize
function Arcana:AddonLoaded()
    local oldDB = ChocolateBarDB
    if oldDB then
        if HasData(oldDB) then
            if not oldDB.arcanaMigrated then
                ArcanaDB = oldDB
                oldDB.arcanaMigrated = true
                print("|cff88ccffArcana|r ", "Doing profile migration...")
            end
        end
    end

    self.db = LibStub("AceDB-3.0"):New("ArcanaDB", defaults, "Default")
    self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

    migrateTexturePaths(ArcanaDB)

    self:RegisterChatCommand("Arcana", "ChatCommand")
    db = self.db.profile

    local AceCfgDlg = LibStub("AceConfigDialog-3.0")
    local _, categoryID = AceCfgDlg:AddToBlizOptions("Arcana", "Arcana")
    self.BlizzardOptionsCategoryID = categoryID

    LSM:Register("statusbar", "Arcana Gold", "Interface\\AddOns\\Arcana\\Media\\ArcanaBar")
    LSM:Register("statusbar", "Arcana Gray", "Interface\\AddOns\\Arcana\\Meida\\ArcanaBarGray")
    LSM:Register("statusbar", "Tooltip", "Interface\\Tooltips\\UI-Tooltip-Background")
    LSM:Register("statusbar", "Solid", "Interface\\Buttons\\WHITE8X8")
    LSM:Register("statusbar", "Gloss", "Interface\\AddOns\\Arcana\\Media\\Gloss")
    LSM:Register("statusbar", "DarkBottom", "Interface\\AddOns\\Arcana\\Media\\DarkBottom")
    LSM:Register("background", "Titan", "Interface\\AddOns\\Arcana\\Media\\Titan")
    LSM:Register("background", "Tribal", "Interface\\AddOns\\Arcana\\Media\\Tribal")

    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEnterCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnLeaveCombat")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    ---@diagnostic disable: undefined-field
    if _G.LE_EXPANSION_LEVEL_CURRENT >= _G.LE_EXPANSION_MISTS_OF_PANDARIA then
        self:RegisterEvent("PET_BATTLE_OPENING_START", "OnPetBattleOpen")
        self:RegisterEvent("PET_BATTLE_CLOSE", "OnPetBattleOver")
    end

    self:RegisterEvent("ADDON_LOADED", function(event, addonName)
        if self[addonName] then self[addonName](self) end
    end)

    --fix frame strata for 8.0
    if not self.db.profile.fixedStrata then
        self.db.profile.strata = "BACKGROUND"
        self.db.profile.fixedStrata = true
    end

    migrateBarNames(db)
    --now creating stored bars
    local barSettings = db.barSettings
    for k, v in pairs(barSettings) do
        local name = v.barName
        self:AddBar(k, v, true) --force no anchor update
    end
    self:AnchorBars()

    Arcana:RegisterOptions(db, arcanaBars, self.modules)
    Arcana:EnableModules()
    Arcana:CreateSavePlaceholdes()
end

function Arcana:OnEnable()
    for name, obj in broker:DataObjectIterator() do
        self:LibDataBroker_DataObjectCreated(nil, name, obj, true) --force noupdate on arcanaBars
    end
    self:UpdateBars()                                              --update arcanaBars here
    broker.RegisterCallback(self, "LibDataBroker_DataObjectCreated")

    local moreArcana = LibStub("LibDataBroker-1.1"):GetDataObjectByName("MoreArcana")
    if moreArcana then
        moreArcana:SetBar(db)
    end
end

function Arcana:OnDatabaseShutdown()
    ArcanaDB.addonVersion = addonVersion
end

function Arcana:EnableModules()
    -- itaret modules list and call each enable fuction
    for name, module in pairs(Arcana.modules) do
        if db.moduleSettings[name].enabled then
            Arcana:EnableModule(name)
        end
    end
end

function Arcana:EnableModule(name)
    Arcana.modules[name]:EnableModule()

    local subModuleOptions = Arcana:GetAceOptions().args.moduleOptions.args[name].args
    subModuleOptions.Options = Arcana.modules[name].optionsExtended

    -- in case the module was enabled in this seesion before but was disabled we need to enable it again
    local obj = broker:GetDataObjectByName(name)
    if obj then
        Arcana:EnableDataObject(name, obj)
    end
end

function Arcana:DisableModule(name)
    Arcana.modules[name]:DisableModule()
    Arcana:DisableDataObject(name)
    local subModuleOptions = Arcana:GetAceOptions().args.moduleOptions.args[name].args
    subModuleOptions.Options = {}
end

function Arcana:GetModule(name)
    local module = Arcana.modules[name]
    return module
end

local function GetModuleEnabled(info)
    local name = info[#info - 1]
    return Arcana.db.profile.moduleSettings[name].enabled
end

local function SetModuleEnabled(info, value)
    local name = info[#info - 1]
    Arcana.db.profile.moduleSettings[name].enabled = value

    if value then
        Arcana:EnableModule(name)
    else
        Arcana:DisableModule(name)
    end
end


function Arcana:NewModule(name, values)
    local module = self.modules[name] or {}
    module.defaults = values.moduleDefaults

    local moduleName = name
    local baseOptions = {
        inline = true,
        name = moduleName,
        type = "group",
        order = 2,
        args = {
            label = {
                order = 1,
                type = "description",
                name = values.description,
            },
            enabled = {
                type = 'toggle',
                order = 1,
                name = L["Enabled"],
                desc = "Toggle enable/disable this Module.",
                get = GetModuleEnabled,
                set = SetModuleEnabled,
            },
        },
    }

    module.options = baseOptions
    module.optionsExtended = values.options
    module.name = moduleName
    defaults.profile.moduleSettings[name] = {}
    self.modules[name] = module
    return module
end

-- called on ADDON_LOADED of Blizzard_OrderHallUI
function Arcana:Blizzard_OrderHallUI()
    --hookOrderHallCommandBar(self)
    if not self.hookedOrderHallCommandBar and db.hideOrderHallCommandBar then
        ---@diagnostic disable-next-line: undefined-field
        local orderHallCommandBar = _G.OrderHallCommandBar

        if orderHallCommandBar then
            orderHallCommandBar:HookScript("OnShow", function() Arcana:ToggleOrderHallCommandBar() end)
            orderHallCommandBar:Hide()
            self.hookedOrderHallCommandBar = true
        end
    end
end

function Arcana:UpdateJostle()
    for name, bar in pairs(arcanaBars) do
        bar:UpdateJostle(db)
    end
end

function Arcana:isNewInstall()
    local lastversion = ArcanaDB.addonVersion or ""
    return lastversion < C_AddOns.GetAddOnMetadata("Arcana", "Version") and true or false
end

function Arcana:ToggleOrderHallCommandBar()
    ---@diagnostic disable-next-line: undefined-field
    local orderHallCommandBar = _G.OrderHallCommandBar
    if orderHallCommandBar then
        if db.hideOrderHallCommandBar then
            orderHallCommandBar:Hide()
        else
            orderHallCommandBar:Show()
        end
    end
    Arcana:UpdateJostle()
end

function Arcana:OnDisable()
    for name, obj in broker:DataObjectIterator() do
        if pluginObjects[name] then pluginObjects[name]:Hide() end
    end
    for k, v in pairs(arcanaBars) do
        v:Hide()
    end
    broker.UnregisterCallback(self, "LibDataBroker_DataObjectCreated")
end

function Arcana:OnEnterWorld()
    self:UpdatePlugins("resizeFrame")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    Arcana:UpdateOptions(arcanaBars)
end

function Arcana:OnPetBattleOpen(...)
    self.InCombat = true
    if db.petBattleHideBars then
        for name, bar in pairs(arcanaBars) do
            bar.petHide = bar:IsShown()
            bar:Hide()
        end
    end
end

function Arcana:OnPetBattleOver(...)
    self.InCombat = false
    if db.petBattleHideBars then
        for name, bar in pairs(arcanaBars) do
            if bar.petHide then
                bar:Show()
                bar:UpdateJostle(db)
            end
        end
    end
end

function Arcana:OnEnterCombat()
    self.InCombat = true
    local combatHideAllBars = db.combathidebar
    local combatOpacityAllBars = db.combatopacity
    for name, bar in pairs(arcanaBars) do
        local settings = bar.settings
        if combatHideAllBars or settings.hideBarInCombat then
            bar.tempHide = bar:IsShown()
            bar:Hide()
        elseif combatOpacityAllBars < 1 then
            bar.tempHide = bar:GetAlpha()
            bar:SetAlpha(db.combatopacity)
        end
    end
end

function Arcana:OnLeaveCombat()
    self.InCombat = false
    local combatHideAllBars = db.combathidebar
    local combatOpacityAllBars = db.combatopacity
    for name, bar in pairs(arcanaBars) do
        local settings = bar.settings
        if combatHideAllBars or settings.hideBarInCombat then
            if bar.tempHide then
                bar:Show()
            end
        elseif combatOpacityAllBars < 1 then
            if bar.tempHide then
                bar:SetAlpha(bar.settings.opacity or 1)
            end
        end
    end
end

--------
-- LDB callbacks
--------
function Arcana:LibDataBroker_DataObjectCreated(event, name, obj, noupdate)
    if not db then return end

    local t = obj.type

    if t == "data source" or t == "launcher" then
        if db.objSettings[name].isNew then
            db.objSettings[name].isNew = false
            if obj.defauldDisabled then db.objSettings[name].enabled = false end
        end

        if db.objSettings[name].enabled then
            self:EnableDataObject(name, obj, noupdate)
        end
    else
        Arcana:Log("Unknown type", t, name)
    end
end

function Arcana:EnableDataObject(name, obj, noupdate)
    local t = obj.type
    if t ~= "data source" and t ~= "launcher" then
        Arcana:Log("Unknown type", t, name)
        return 0
    end

    local settings = db.objSettings[name]
    settings.enabled = true

    local barName = settings.barName

    -- set default values depending on data source
    if barName == "" then
        settings.barName = "Arcana1"
        if t and t == "data source" then
            settings.align = "left"
            settings.showText = true
            if db.autodissource then
                settings.enabled = false
                return
            end
            if name == "ArcanaClock" or name == "Broker_uClock" then
                settings.align = "right"
                settings.index = -1
            end
        else
            settings.align = "right"
            settings.showText = false
            if db.autodislauncher then
                settings.enabled = false
                return
            end
        end
    end
    obj.name = name

    local plugin = pluginObjects[name] or ArcanaPiece:New(name, obj, settings, db)
    pluginObjects[name] = plugin

    plugin:Show()

    --addon name migration
    if barNameIsDeprecated(barName) then
        barName = convertDeprecatedBarName(barName)
        settings.barName = barName --store new bar name in the plugin settings
    end

    local bar = arcanaBars[barName]
    if bar then
        bar:AddArcanaPiece(plugin, name, noupdate)
    else
        arcanaBars["Arcana1"]:AddArcanaPiece(plugin, name, noupdate)
    end
    broker.RegisterCallback(self, "LibDataBroker_AttributeChanged_" .. name, "AttributeChanged")

    Arcana:AddObjectOptions(name, obj)
end

function Arcana:DisableDataObject(name)
    broker.UnregisterCallback(self, "LibDataBroker_AttributeChanged_" .. name)
    --get bar from setings
    if db.objSettings[name] then
        db.objSettings[name].enabled = false
        local barName = db.objSettings[name].barName
        if (barName and arcanaBars[barName]) then
            arcanaBars[barName]:RemoveArcanaPiece(name)
        end
    end
end

function Arcana:AttributeChanged(event, name, key, value)
    local settings = db.objSettings[name]
    if not settings.enabled then
        return
    end
    local plugin = pluginObjects[name]
    plugin:Update(plugin, key, value, name)
end

-- disable autohide for all bars during drag and drop
function Arcana:TempDisAutohide(value)
    for name, bar in pairs(arcanaBars) do
        if value then
            bar.tempHide = bar.autohide
            bar.autohide = false
            bar:ShowAll()
        else
            if bar.tempHide then
                bar.autohide = true
                bar:HideAll()
            end
        end
    end
end

-- returns nil if the plugin is disabled
function Arcana:GetPlugin(name)
    return pluginObjects[name]
end

function Arcana:GetArcanas()
    return pluginObjects
end

function Arcana:GetBar(name)
    return arcanaBars[name]
end

function Arcana:GetBars()
    return arcanaBars
end

function Arcana:SetBars(tab)
    arcanaBars = tab or {}
end

local function getFreeBarName()
    local used = false
    local name
    for i = 1, 100 do
        name = "Arcana" .. i
        for k, v in pairs(arcanaBars) do
            if name == v:GetName() then
                used = true
            end
        end
        if not used then
            return name
        end
        used = false
    end
end

function Arcana:UpdatePlugins(key, val)
    for name, plugin in pairs(pluginObjects) do
        plugin:Update(plugin, key, val)
    end
end

function Arcana:ExecuteforAllPlugins(func, ...)
    for name, plugin in pairs(pluginObjects) do
        func(plugin, ...)
    end
end

--------
-- Bars Management
--------
function Arcana:AddBar(name, settings, noupdate)
    if not name then --find free name
        name = getFreeBarName()
    end
    if not settings then
        settings = db.barSettings[name]
    end
    local bar = Bar:New(name, settings, db)
    Drag:RegisterFrame(bar)
    arcanaBars[name] = bar
    settings.barName = name
    if not noupdate then
        self:AnchorBars()
    end
    return name, bar
end

function Arcana:UpdateBars(updateindex)
    for k, v in pairs(arcanaBars) do
        v:UpdateBar(updateindex)
        v:UpdateAutoHide(db)
    end
end

-- sort and anchor all bars
function Arcana:AnchorBars()
    local temptop = {}
    local tempbottom = {}

    for k, v in pairs(arcanaBars) do
        local settings = v.settings
        local index = settings.index or 500
        if settings.align == "top" then
            table.insert(temptop, { v, index })
        elseif settings.align == "bottom" then
            table.insert(tempbottom, { v, index })
        else
            v:ClearAllPoints()
            if settings.barPoint and settings.barOffx and settings.barOffy then
                v:SetPoint(settings.barPoint, "UIParent", settings.barOffx, settings.barOffy)
                v:SetWidth(settings.width)
            else
                settings.align = "top"
                table.insert(temptop, { v, index })
            end
        end
    end
    table.sort(temptop, function(a, b) return a[2] < b[2] end)
    table.sort(tempbottom, function(a, b) return a[2] < b[2] end)

    local yoff = 0
    local relative = nil
    for i, v in ipairs(temptop) do
        local bar = v[1]
        bar:ClearAllPoints()
        if (relative) then
            bar:SetPoint("TOPLEFT", relative, "BOTTOMLEFT", 0, -yoff)
            bar:SetPoint("RIGHT", relative, "RIGHT", 0, 0);
        else
            bar:SetPoint("TOPLEFT", -1, 1);
            bar:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
        end
        --if updateindex then
        bar.settings.index = i
        --end
        relative = bar
    end

    local relative = nil
    for i, v in ipairs(tempbottom) do
        local bar = v[1]
        bar:ClearAllPoints()
        if (relative) then
            bar:SetPoint("BOTTOMLEFT", relative, "TOPLEFT", 0, -yoff)
            bar:SetPoint("RIGHT", relative, "RIGHT", 0, 0);
        else
            bar:SetPoint("BOTTOMLEFT", -1, 0);
            bar:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
        end
        --if updateindex then
        bar.settings.index = i
        --end
        relative = bar
    end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function onRightClick(self)
    self:GetParent():OnMouseUp("RightButton")
end

function Arcana:CreateSavePlaceholdes()
    for name, v in pairs(db.placeholderNames) do
        Arcana:NewPlaceholder(name)
    end
end

function Arcana:NewPlaceholder(name)
    local obj = broker:GetDataObjectByName(name) or broker:NewDataObject(name, {
        type    = "data source",
        label   = name,
        text    = "",
        OnClick = onRightClick,
    })

    return obj
end

local function createPointer()
    local pointer = CreateFrame("Frame", "ArcanaPointer")
    pointer:SetFrameStrata("FULLSCREEN_DIALOG")
    pointer:SetFrameLevel(20)
    pointer:SetWidth(15)

    local arrow = pointer:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    arrow:SetPoint("CENTER", pointer, "LEFT", 0, 0)
    arrow:SetTexture("Interface\\AddOns\\Arcana\\Media\\pointer")
    return pointer
end

function Arcana:GetPointer(parent)
    local pointer = self.pointer or createPointer()
    pointer:SetHeight(parent:GetHeight())
    pointer:SetParent(parent)
    return pointer
end

--------
-- option functions
--------
function Arcana:ChatCommand(input)
    Arcana:LoadOptions(nil, input)
end

function Arcana:LoadOptions(pluginName, input, blizzard)
    Arcana:OpenOptions(arcanaBars, db, input, pluginName, nil, blizzard)
end

function Arcana:UpdateDB(data)
    db = data
    ArcanaPiece:UpdateDB(db)
end

--helper API
function Arcana:GetLabelColor()
    return db and db.labelColor or { r = 1, g = 0.82, b = 0, a = 1 }
end
