if true then return end

local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")

local moduleDB
local placeholderNames = {}

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function createPlaceholder()
    local name = "CB_" .. L["Placeholder"] .. tablelength(placeholderNames)
    placeholderNames[name] = true
    Arcana:AddObjectOptions(name, module:NewPlaceholder(name))
end

local function removePlaceholder(info)
    local cleanName = info[#info - 2]
    moduleDB.placeholderNames[cleanName] = nil
    Arcana:DisableDataObject(cleanName)
    Arcana:RemovePluginOptions(cleanName)
end

local placeholderPluginOptions = {
    inline = true,
    name = L["Placeholder Options"],
    type = "group",
    order = 1,
    args = {
        label = {
            order = 1,
            type = "description",
            name = L
                ["Tipp: Set the width behavior to fixed and adjust the the max text width to scale the placeholder."],
        },
        disablePlaceholder = {
            type = 'execute',
            order = 0,
            name = L["Remove Placeholder"],
            desc = L["Remove this Placeholder"],
            func = removePlaceholder,
        },
    },
}

local options = {
    inline = true,
    name = L["Placeholder"],
    type = "group",
    order = 1,
    args = {
        label1 = {
            order = 1,
            type = "description",
            name = L["Creates a new plugin to use as a placeholder."],
        },
        newPlaceholder = {
            type = 'execute',
            order = 2,
            name = L["Create Placeholder"],
            desc = L["Creates a new plugin to use as a placeholder."],
            func = createPlaceholder,
        },
        label2 = {
            order = 3,
            type = "description",
            name = L
                ["Tipp: Set the width behavior to fixed and adjust the the max text width to scale the placeholder."],
        },
    },
}

module = Arcana:NewModule("Placeholder", nil, options)

local function addPlaceholderOptionsToOptions()
    for name, _ in pairs(placeholderNames) do
        Arcana:AddCustomPluginOptions(name, placeholderPluginOptions)
    end
end

function module:OnInitialize(modDB)
    placeholderNames = modDB.placeholderNames or {}
    modDB.placeholderNames = placeholderNames
    moduleDB = modDB
    for name, _ in pairs(placeholderNames) do
        self:NewPlaceholder(name)
    end
end

function module:NewPlaceholder(name)
    local placeholder = LibStub("LibDataBroker-1.1"):NewDataObject(name, {
        type  = "data source",
        label = name,
        text  = "",
    })
    return placeholder
end

function module:OnOpenOptions()
    addPlaceholderOptionsToOptions()
end
