local LibStub = LibStub
local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")

local addonName = "Sound Volume"
local dataobj

local volumeText = "Sound: " .. math.floor((_G.GetCVar("Sound_SFXVolume") * 100)) .. "%"

local function OnMouseWheel(self, vector)
    local cVar = "Sound_SFXVolume"
    local vol = GetCVar(cVar) or 1
    local step = IsAltKeyDown() and vector * .01 or vector * .1
    vol = vol + step
    if vol > 1 then vol = 1 end
    if vol < 0 then vol = 0 end
    SetCVar(cVar, vol);
    dataobj.text = "Sound: " .. math.floor((_G.GetCVar(cVar) * 100)) .. "%"
end

local Module = Arcana:NewModule(addonName, {
    description = "Use your scroll wheel over this plugin to adjust the sound volume.",
    defaults = {
        enabled = true,
    },
    --options = options
})

function Module:DisableModule()
end

function Module:EnableModule()
    if not dataobj then
        dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
            type         = "data source",
            icon         = "Interface\\AddOns\\Arcana\\Modules\\Volume\\SoundIcon.tga",
            label        = addonName,
            text         = volumeText,
            OnMouseWheel = OnMouseWheel,
        })
    end
end
