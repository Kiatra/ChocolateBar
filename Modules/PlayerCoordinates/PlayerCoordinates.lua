local LibStub = LibStub
local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")

local addonName = "Coordinates"
local dataobj
local frame
local time = 0
local counter = 0
local volumeText = "Coordinates"


local Module = Arcana:NewModule(addonName, {
    description = L["Shows player coordinates"],
    defaults = {
        enabled = true,
    },
})

function Module:DisableModule()
end

function Module:EnableModule()
    if not dataobj then
        dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
            type  = "data source",
            label = "Player",
            text  = volumeText,
        })
    end
    frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(this, elapsed)
        time = time + elapsed
        if time > 0.2 then
            counter = counter + 0.1
            ---@diagnostic disable: undefined-global
            local map = C_Map.GetBestMapForUnit("player")
            if map then
                local position = C_Map.GetPlayerMapPosition(map, "player")
                if position then
                    local x, y = position:GetXY()
                    dataobj.text = string.format("%.1f X, %.1f Y", x * 100, y * 100)
                else
                    dataobj.text = "Instance"
                end
            else
                dataobj.text = "Instance"
            end

            time = 0
        end
    end)
end
