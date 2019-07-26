-- a LDB object that will show/hide the chocolatebar set in the chocolatebar options
local LibStub = LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("CB_ItemLevel", {
	type = "data source",
	icon = "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece",
	label = "Item Level",
	text  = "iLevel: ---",
})

function dataobj:OnTooltipShow()
	self:AddLine(dataobj.text)
end

local function unitInventoryChange()
  local overall, equipped = GetAverageItemLevel()
	dataobj.text = string.format ("iLvl %s/%s" , overall, equipped)
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", unitInventoryChange)
frame:RegisterEvent("UNIT_INVENTORY_CHANGE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
