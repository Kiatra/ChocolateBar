-- a LDB object that will show/hide the Arcana set in the Arcana options
local LibStub = LibStub
local counter = 0
local delay = 4
local Timer = CreateFrame("Frame")
local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local bar
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")
local wipe, pairs = wipe, pairs
local moreArcana

local function onEnter()
    counter = 0
    if delay > 0 then
        Timer:SetScript("OnUpdate", Timer.OnUpdate)
    end
    if bar then
        bar:Show()
    end
end

local function setBar(_, db)
    bar = Arcana:GetBar(db.moreBar)
    if bar and bar:IsShown() then
        bar:Hide()
    end
    delay = db.moreBarDelay
end


local function GetList()
    wipe(moreArcana.barNames)
    moreArcana.barNames.none = L["None"]
    for k, _ in pairs(Arcana:GetBars()) do
        moreArcana.barNames[k] = k
    end
    return moreArcana.barNames
end

---@diagnostic disable-next-line: inject-field
function Timer:OnUpdate(elapsed)
    counter = counter + elapsed
    if counter >= delay and bar and not Arcana.dragging then
        bar:Hide()
        counter = 0
        Timer:SetScript("OnUpdate", nil)
    end
end

local options = {
    inline = true,
    name = "Module Options",
    type = "group",
    order = 1,
    args = {
        label = {
            order = 2,
            type = "description",
            name = L["A broker plugin to toggle a bar."],
        },
        selectBar = {
            type = 'select',
            values = GetList,
            order = 3,
            name = L["Select Bar"],
            desc = L["Select Bar"],
            get = function()
                return Arcana.db.profile.moreBar
            end,
            set = function(_, value)
                if bar then
                    bar:Show()
                end
                Arcana.db.profile.moreBar = value
                moreArcana:SetBar(Arcana.db.profile)
            end,
        },
        delay = {
            type = 'range',
            order = 4,
            name = L["Delay"],
            desc = L["Set seconds until bar will hide."],
            min = 0,
            max = 15,
            step = 1,
            get = function()
                return Arcana.db.profile.moreBarDelay
            end,
            set = function(_, value)
                delay = value
                Arcana.db.profile.moreBarDelay = value
            end,
        },
    },
}


local Module = Arcana:NewModule("MoreArcana", {
    description = "A plugin that can toggle the visibility of a specific Arcana bar.",
    defaults = {
        enabled = true,
    },
    options = options
})

function Module:DisableModule()
    if bar then
        bar:Show()
    end
    Arcana.db.profile.moreBar = "none"
    setBar(moreArcana, Arcana.db.profile)
end

function Module:EnableModule()
    if not moreArcana then
        moreArcana = LibStub("LibDataBroker-1.1"):NewDataObject("MoreArcana", {
            type    = "launcher",
            icon    = "Interface\\AddOns\\Arcana\\Media\\Icons\\ArcanaKnowledge",
            label   = "MoreArcana",
            text    = "MoreArcana",

            OnClick = function(_, btn)
                if btn == "LeftButton" then
                    if bar then
                        if bar:IsShown() then
                            bar:Hide()
                            Timer:SetScript("OnUpdate", nil)
                        else
                            bar:Show()
                            if delay > 0 then
                                Timer:SetScript("OnUpdate", Timer.OnUpdate)
                            end
                        end
                    end
                else
                    InterfaceOptionsFrame_OpenToCategory("Arcana");
                end
            end,
        })

        moreArcana.barNames = { none = "none" }
        moreArcana.SetBar = setBar
        moreArcana.OnEnter = onEnter
    end
end
