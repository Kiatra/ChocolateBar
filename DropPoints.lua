local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")
local dropPoints
local _G = _G
local Drag = Arcana.Drag

local function createDropPoint(name, dropfunc, offx, text, texture)
    if not Arcana.dropFrames then
        local dropFrames = CreateFrame("Frame", nil, _G.UIParent, BackdropTemplateMixin and "BackdropTemplate")
        dropFrames:SetWidth(420)
        dropFrames:SetHeight(200)
        Arcana.dropFrames = dropFrames
        dropFrames:SetBackdrop({
            bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal-Desaturated",
            edgeFile = "Interface\\LFGFrame\\LFGBorder",
            ---@diagnostic disable-next-line: assign-type-mismatch
            tile = false,
            tileSize = 4,
            edgeSize = 4,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        ---@diagnostic disable-next-line: param-type-mismatch, inject-field
        dropFrames.text = dropFrames:CreateFontString(nil, nil, "GameFontHighlight")
        ---@diagnostic disable-next-line: param-type-mismatch
        dropFrames.text:SetPoint("CENTER", 0, -40)
        ---@diagnostic disable-next-line: undefined-field
        dropFrames.text:SetFormattedText("|T%s:%d|t%s", "Interface\\FriendsFrame\\InformationIcon", 16,
            " " .. L["Drop a Plugin onto any of the icons above."])
    end
    local frame = CreateFrame("Frame", name, Arcana.dropFrames, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetWidth(100)
    frame:SetHeight(100)
    frame:SetFrameStrata("DIALOG")
    ---@diagnostic disable-next-line: param-type-mismatch
    frame:SetPoint("TOPLEFT", offx + 10, -10)

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\LFGFrame\\LFGBorder",
        ---@diagnostic disable-next-line: assign-type-mismatch
        tile = false,
        tileSize = 4,
        edgeSize = 4,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    });

    frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
    frame:SetBackdropColor(0, 0, 0, 0.5)

    local tex = frame:CreateTexture()
    tex:SetWidth(50)
    tex:SetHeight(50)
    tex:SetTexture(texture)
    ---@diagnostic disable-next-line: param-type-mismatch
    tex:SetPoint("TOPLEFT", 25, -35)

    ---@diagnostic disable-next-line: inject-field, param-type-mismatch
    frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
    ---@diagnostic disable-next-line: param-type-mismatch
    frame.text:SetPoint("CENTER", 0, 30)
    frame.text:SetText(text)


    frame:Hide()
    ---@diagnostic disable-next-line: inject-field
    frame.Drop = dropfunc
    ---@diagnostic disable-next-line: inject-field
    frame.GetFocus = function(frame2) frame2:SetBackdropColor(0.5, 0, 0, 0.5) end
    ---@diagnostic disable-next-line: inject-field
    --frame.Drag = function(frame) end
    ---@diagnostic disable-next-line: inject-field
    frame.LoseFocus = function(frame2) frame2:SetBackdropColor(0, 0, 0, 0.5) end
    Drag:RegisterFrame(frame)
    return frame
end

--------
-- drop points functions
--------
local function dropText(_, plugin)
    local name = plugin.name
    local db = Arcana.db.profile
    db.objSettings[name].showText = not db.objSettings[name].showText
    Arcana:AttributeChanged(nil, name, "updateSettings", db.objSettings[name].showText)
    plugin.bar:ResetDrag(plugin, name)
    --frame:SetBackdropColor(0,0,0,1)
end

local function dropOptions(frame, plugin)
    local obj = plugin.obj
    local name = obj.name
    local label = obj.label
    local cleanName
    if label then
        cleanName = string.gsub(label, "|c........", "")
    else
        cleanName = string.gsub(name, "|c........", "")
    end
    cleanName = string.gsub(cleanName, "|r", "")
    cleanName = string.gsub(cleanName, "[%c \127]", "")
    Arcana:LoadOptions(cleanName)
    plugin.bar:ResetDrag(plugin, plugin.name)
    frame:SetBackdropColor(0.5, 0, 0, 0.5)
end

local function dropDisable(frame, plugin)
    plugin:Hide()
    Arcana:DisableDataObject(plugin.name)
    frame:SetBackdropColor(0, 0, 0, 0, 5)
end


function Arcana:SetDropPoins(parent)
    if not dropPoints then
        createDropPoint("ArcanaTextDrop", dropText, 0, L["Toggle Text"],
            "Interface/ICONS/INV_Inscription_Tradeskill01")
        createDropPoint("ArcnaCenterDrop", dropOptions, 150, "CB " .. L["Options"], "Interface/Icons/INV_Gizmo_02")
        createDropPoint("ArcanaDisableDrop", dropDisable, 300, L["Disable Plugin"],
            "Interface/ICONS/Spell_ChargeNEgative")
    end

    local frame = Arcana.dropFrames
    frame:ClearAllPoints()
    ---@diagnostic disable-next-line: param-type-mismatch
    frame:SetClampedToScreen(true)
    local x, y = parent:GetCenter()
    local vhalf = (y > _G.UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
    local yoff = (y > _G.UIParent:GetHeight() / 2) and -70 or 70
    local xoff = frame:GetWidth() / 2
    frame:SetPoint(vhalf .. "LEFT", parent.bar, x - xoff, yoff)
    frame:Show()
end
