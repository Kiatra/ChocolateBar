-- a LDB object that will show/hide the chocolatebar set in the chocolatebar options
local LibStub = LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")
local savedPlayedTime = ChocolateBarDB.savedPlayedTime

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("PlayedTime", {
	type = "data source",
	icon = "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece",
	label = "Played Time",
	text  = "---",
})

function dataobj:OnTooltipShow()
	self:AddLine("PlayedTime")
	for k, v in pairs(savedPlayedTime) do
			self:AddLine(string.format("%s - %s", k, v.total))
	end
end

local function getPlayerIdentifier()
  local _, engClass, _, _, _, name, server = GetPlayerInfoByGUID(UnitGUID("player"))
	return string.format("%s-%s", name, server)
end

local function ADDON_LOADED(self, totalTimeInMinutes, timeAtThisLevel)
	savedPlayedTime[getPlayerIdentifier()].total = totalTimeInMinutes
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", TIME_PLAYED_MSG)
frame:RegisterEvent("TIME_PLAYED_MSG")
