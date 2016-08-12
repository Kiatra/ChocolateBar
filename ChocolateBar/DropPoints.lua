local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")
local dropPoints
local Drag = ChocolateBar.Drag

local function createDropPoint(name, dropfunc, offx, text, texture)
	if not ChocolateBar.dropFrames then
		local dropFrames = CreateFrame("Frame", nil, _G.UIParent)
		dropFrames:SetWidth(400)
		dropFrames:SetHeight(100)
		ChocolateBar.dropFrames = dropFrames
	end
	local frame = CreateFrame("Frame", name, ChocolateBar.dropFrames)
	frame:SetWidth(100)
	frame:SetHeight(100)
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOPLEFT",offx,0)

	frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = false, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }});
	frame:SetBackdropColor(0,0,0,1)

	local tex = frame:CreateTexture()
	tex:SetWidth(50)
	tex:SetHeight(50)
	tex:SetTexture(texture)
	tex:SetPoint("TOPLEFT",25,-35)

	frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
	frame.text:SetPoint("CENTER",0, 30)
	frame.text:SetText(text)
	frame:Hide()
	frame.Drop = dropfunc
	frame.GetFocus = function(frame, name) frame:SetBackdropColor(1,0,0,1) end

	frame.Drag = function(frame) end
	frame.LoseFocus = function(frame) frame:SetBackdropColor(0,0,0,1) end
	Drag:RegisterFrame(frame)
	return frame
end

--------
-- drop points functions
--------
local function dropText(frame, choco)
		local name = choco.name
		local db = ChocolateBar.db.profile
		db.objSettings[name].showText = not db.objSettings[name].showText
		ChocolateBar:AttributeChanged(nil, name, "updateSettings", db.objSettings[name].showText)
		choco.bar:ResetDrag(choco, name)
		frame:SetBackdropColor(0,0,0,1)
end

local function dropOptions(frame, choco)
		local obj = choco.obj
		local name = obj.name
		local label = obj.label
		local cleanName
		if label then
			cleanName = string.gsub(label, "\|c........", "")
		else
			cleanName = string.gsub(name, "\|c........", "")
		end
		cleanName = string.gsub(cleanName, "\|r", "")
		cleanName = string.gsub(cleanName, "[%c \127]", "")
		ChocolateBar:LoadOptions(cleanName)
		choco.bar:ResetDrag(choco, choco.name)
		frame:SetBackdropColor(0,0,0,1)
end

local function dropDisable(frame, choco)
		choco:Hide()
		ChocolateBar:DisableDataObject(choco.name)
		frame:SetBackdropColor(0,0,0,1)
end


function ChocolateBar:SetDropPoins(parent)
	if not dropPoints then
		createDropPoint("ChocolateTextDrop", dropText, 0,L["Toggle Text"],"Interface/ICONS/INV_Inscription_Tradeskill01")
		createDropPoint("ChocolateCenterDrop", dropOptions,150,L["Options"],"Interface/Icons/Spell_Holy_GreaterBlessingofSalvation")
		createDropPoint("ChocolateCenterDrop", dropOptions,150,L["Options"],"Interface/Icons/INV_Gizmo_02")
		createDropPoint("ChocolateDisableDrop", dropDisable, 300,L["Disable Plugin"], "Interface/ICONS/Spell_ChargeNEgative")
	end

	local frame = ChocolateBar.dropFrames
	frame:ClearAllPoints()
	frame:SetClampedToScreen(true)
	local x,y = parent:GetCenter()
	local vhalf = (y > _G.UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
	local yoff = (y > _G.UIParent:GetHeight() / 2) and -100 or 100
	local xoff = frame:GetWidth() / 2
	frame:SetPoint(vhalf.."LEFT",parent.bar,x-xoff,yoff)
	frame:Show()
end
