local addonName                                    = "CB_Laucher"
local Arcana                                       = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local ldb                                          = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibQTip                                      = LibStub('LibQTip-1.0')
local L                                            = LibStub("AceLocale-3.0"):GetLocale("Arcana")

local _G, floor, string, GetNetStats, GetFramerate = _G, floor, string, GetNetStats, GetFramerate
local delay, counter                               = 1, 0
local dataobj, tooltip, db
local color                                        = true
local path                                         = "Interface\\AddOns\\Broker_MicroMenu\\media\\"
local _

local function RGBToHex(r, g, b)
    return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end

---@diagnostic disable-next-line: undefined-field
local mb = _G.MainMenuMicroButton:GetScript("OnMouseUp")
local function mainmenu(self, ...)
    self.down = 1; mb(self, ...)
end

dataobj = ldb:NewDataObject(addonName, {
    type    = "data source",
    icon    = path .. "green.tga",
    label   = "Launchers",
    text    = "Launchers",
    OnClick = function(self, button, ...)
        if button == "RightButton" then
            if IsModifierKeyDown() then
                mainmenu(self, button, ...)
            elseif dataobj.OpenOptions then
                dataobj:OpenOptions()
            end
        else
            _G.ToggleCharacter("PaperDollFrame")
        end
        LibQTip:Release(tooltip)
        tooltip = nil
    end
})

local myProvider, cellPrototype = LibQTip:CreateCellProvider()

function cellPrototype:InitializeCell()
    self.texture = self:CreateTexture()
    self.texture:SetAllPoints(self)
end

function cellPrototype:SetupCell(tooltip, value, justification, font, iconCoords, unitID, guild)
    local tex = self.texture
    tex:SetWidth(16)
    tex:SetHeight(16)

    tex:SetTexture(value)

    if iconCoords then
        tex:SetTexCoord(_G.unpack(iconCoords))
    end
    return tex:GetWidth(), tex:GetHeight()
end

function cellPrototype:ReleaseCell()
end

local function MouseHandler(event, plugin, button, ...)
    LibQTip:Release(tooltip)
    tooltip = nil

    plugin.obj.OnClick(dataobj.frame, button)
end

function dataobj:OnEnter()
    if tooltip then
        LibQTip:Release(tooltip)
    end

    dataobj.frame = self

    tooltip = LibQTip:Acquire(addonName .. "Tooltip", 2, "LEFT", "LEFT")
    tooltip:Clear()
    self.tooltip = tooltip

    for name, plugin in pairs(Arcana:GetArcanas()) do
        local obj = plugin.obj
        if obj.type == "launcher" then
            local y, x = tooltip:AddLine()
            tooltip:SetCell(y, 1, obj.icon, myProvider)
            tooltip:SetCell(y, 2, name)
            tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, plugin)
        end
    end

    tooltip:SetAutoHideDelay(0.001, self)
    tooltip:SmartAnchorTo(self)
    tooltip:Show()
end
