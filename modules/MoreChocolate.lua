-- a LDB object that will show/hide the chocolatebar set in the chocolatebar options
local LibStub = LibStub
local counter = 0
local delay = 4
local Timer = CreateFrame("Frame")
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local bar
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")
local wipe, pairs = wipe, pairs
local moreChocolate

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
    bar = ChocolateBar:GetBar(db.moreBar)
    if bar and bar:IsShown() then
        bar:Hide()
    end
    delay = db.moreBarDelay
end


local function GetList()
    wipe(moreChocolate.barNames)
    moreChocolate.barNames.none = L["None"]
    for k, _ in pairs(ChocolateBar:GetBars()) do
        moreChocolate.barNames[k] = k
    end
    return moreChocolate.barNames
end

---@diagnostic disable-next-line: inject-field
function Timer:OnUpdate(elapsed)
    counter = counter + elapsed
    if counter >= delay and bar and not ChocolateBar.dragging then
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
                return ChocolateBar.db.profile.moreBar
            end,
            set = function(_, value)
                if bar then
                    bar:Show()
                end
                ChocolateBar.db.profile.moreBar = value
                moreChocolate:SetBar(ChocolateBar.db.profile)
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
                return ChocolateBar.db.profile.moreBarDelay
            end,
            set = function(_, value)
                delay = value
                ChocolateBar.db.profile.moreBarDelay = value
            end,
        },
    },
}


local Module = ChocolateBar:NewModule("MoreChocolate", {
    description = "A broker plugin that can toggle the visibility of a specific chocolate bar.",
    defaults = {
        enabled = true,
    },
    options = options
})

function Module:DisableModule()
    if bar then
        bar:Show()
    end
    ChocolateBar.db.profile.moreBar = "none"
    setBar(moreChocolate, ChocolateBar.db.profile)
end

function Module:EnableModule()
    if not moreChocolate then
        moreChocolate = LibStub("LibDataBroker-1.1"):NewDataObject("MoreChocolate", {
            type    = "launcher",
            icon    = "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece",
            label   = "MoreChocolate",
            text    = "MoreChocolate",

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
                    InterfaceOptionsFrame_OpenToCategory("ChocolateBar");
                end
            end,
        })

        moreChocolate.barNames = { none = "none" }
        moreChocolate.SetBar = setBar
        moreChocolate.OnEnter = onEnter
    end
end
