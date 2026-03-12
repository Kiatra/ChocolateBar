local LibStub = LibStub
local addonName = "Arcana-ItemLevel"

local GetAverageItemLevel = GetAverageItemLevel or
    function()
        return 10, 100
    end -- Wow classic subsitute for GetAverageItemLevel


local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type        = "data source",
    description = "A broker plugin to show the characters item level",
    label       = "iLvl",
    text        = "iLevel: ---",
    enabled     = false,
    --options = options,
})

function dataobj:OnTooltipShow()
    local overall, equipped = GetAverageItemLevel()
    self:AddLine(string.format("Item Level %s (Equipped %s)", overall, equipped))
end

local function unitInventoryChange()
    local overall, equipped = GetAverageItemLevel()
    dataobj.text = string.format("%.1f (-%.1f)", overall, overall - equipped)
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", unitInventoryChange)
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
