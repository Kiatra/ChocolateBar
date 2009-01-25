local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local LSM = LibStub("LibSharedMedia-3.0")
local Bar = ChocolateBar.Bar
local chocolate = ChocolateBar.ChocolatePiece
local Debug = ChocolateBar.Debug

function Bar:New(name, settings)
	local frame = CreateFrame("Frame",name,UIParent)

	-- add class methods to frame object
	for k, v in pairs(Bar) do
		frame[k] = v
	end
	
	frame:SetHeight(settings.height)
	frame:SetPoint("TOPLEFT",-1,1);
	--frame:SetPoint("TOPLEFT", settings.xoff, settings.yoff);
	frame:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
	
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", function() 
		ChocolateBar1:SetAlpha(1)
	end)
	--frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnLeave", function() 
		if ChocolateBar.db.profile.hideonleave then
			ChocolateBar1:SetAlpha(0)
		end
	end)
	
	frame:SetScript("OnMouseUp", function() 
		if arg1 == "RightButton" then
			LibStub("AceConfigDialog-3.0"):Open("ChocolateBar")
		end
	end)
	
	frame.settings = settings
	frame:UpdateTexture()
	frame:UpdateColors()
	frame:UpdateScale()
	
	frame.chocolist = {} --create list of chocolate chocolist in the bar
	return frame
end

function Bar:UpdateScale()
	self.scale = ChocolateBar.db.profile.scale
	self:SetScale(self.scale)
end

function Bar:UpdateColors()
	local bg = ChocolateBar.db.profile.background
	local color = bg.borderColor
	self:SetBackdropBorderColor(color.r,color.g,color.b,color.a)
	color = bg.color
	self:SetBackdropColor(color.r,color.g,color.b,color.a)
end

function Bar:UpdateTexture()
	local background = LSM:Fetch("statusbar", ChocolateBar.db.profile.background.texture)
	local bg = {
		bgFile = background, 
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = false, tileSize = 16, edgeSize = 12, 
		--insets = { left = 4, right = 4, top = 4, bottom = 4}
		insets = { left = 0, right = 0, top = 0, bottom = 0}
	}
	bg.bgFile = background
	self:SetBackdrop(bg);
end

function GetTexture(frame)
	Debug(frame:GetName())
	regions = frame:GetRegions()
end

-- add some chocolate to a bar
function Bar:AddChocolatePiece(choco, name,noupdate)
	local chocolist = self.chocolist
	if chocolist[name] then
		return
	end
	
	chocolist[name] = choco
	
	choco:SetParent(self)
	choco.bar = self

	if not noupdate then
		self:UpdateBar(self)
	end
	--self:UpdateChocolte(name, key, value)
end

-- eat some chocolate from a ChocolateBar
function Bar:EatChocolatePiece(name)
	self.chocolist = self.chocolist or {}
	local choco = self.chocolist[name]
	
	if choco then
		choco:Hide()
		self.chocolist[name] = nil
		self:UpdateBar(self)
	end
end

function Bar:Drop(choco, pos)
	Debug("Bar:Drop", choco.name, pos)
	self.dummy:Hide()
	self.chocolist[choco.obj.name] = choco
	Debug("frame:GetWidth() ", choco:GetWidth())
	choco.settings.index = self.dummy.settings.index
	choco.settings.align = self.dummy.settings.align
	self:UpdateBar(true)
end

function Bar:LoseFocus(name)
	self.dummy:Hide()
	self.chocolist[name] = nil
	self:UpdateBar(true)
end

function Bar:GetChocolateAtCursor()
	local s = self:GetEffectiveScale()
	local x, y = GetCursorPosition()
	x = x/s
	for k, v in pairs(self.chocolist) do
		if x > v:GetLeft() and x < v:GetRight() then
			return v
		end
	end
	return nil
end

function Bar:UpdateDragChocolate()
	local choco = self:GetChocolateAtCursor()
	if not choco then 
		Debug("Bar:UpdateDragChocolate(pos) cursour above: nil")
		self.dummy.settings.index = 500
		self:UpdateBar()
	else
		Debug("cursour above: ",choco.name)
		if self.last ~= choco then
			self.last = choco
			self.dummy.settings.index = choco.settings.index - 0.5
			self.dummy.settings.align = choco.settings.align
			self:UpdateBar()
		end
	end
end

function Bar:Drag(name)
	local choco = self.chocolist[name]
	if not choco then 
		if self.saved.name == name then
			choco = self.saved
		else
			Debug("chocolate ", name, "not found in list")
			return
		end
	end
	
	local dummy = self.dummy
	if not dummy then  
		dummy = CreateFrame("Frame", "ChocolateDummy", self)
		--dummy:SetAllPoints(chocolate.frame)
		dummy.name = "dummy"
		dummy:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = true, tileSize = 16, edgeSize = 6, 
		insets = { left = 0, right = 0, top = 0, bottom = 0}})
		dummy:SetBackdropColor(1,0,0,1)
		dummy:SetBackdropBorderColor(1,0,0,0)
		self.dummy = dummy
	end
	dummy:Show()
	dummy:SetWidth(choco:GetWidth())
	dummy:SetHeight(choco:GetHeight())
	
	local settings = {}
	settings.index = choco.settings.index
	dummy.settings = settings
	dummy.settings.align = choco.settings.align
	templeftchocolate = self.chocolist[name]
	self.saved = choco
	self.chocolist[name] = dummy
	TEST5 = self
	self:UpdateBar()
end

local function SortTab(tab)
	local left = {}
	local right = {}
	for k,v in pairs(tab) do
		local index = v["settings"]["index"]
		if not index then
			index = 500
		end
		if v.settings.align == "left" then
			table.insert(left,{k,index})
		else
			table.insert(right,{k,index})
		end
	end
	table.sort(left, function(a,b)return a[2] < b[2] end)
	table.sort(right, function(a,b)return a[2] < b[2] end)
	return left, right
end

-- rearange all chocolate chocolist in a given bar
-- called when chocolates are added, removed, moved
function Bar:UpdateBar(updateindex)
	local chocolates =  self.chocolist
	local templeft, tempright = SortTab(chocolates)
	
	local yoff = 0
	local relative = nil
	for i, v in ipairs(templeft) do
		k = v[1]
		chocolates[k]:ClearAllPoints()
		if(relative)then
			chocolates[k]:SetPoint("TOPLEFT",relative,"TOPRIGHT", 0,0)
		else
			chocolates[k]:SetPoint("TOPLEFT",self, 6,yoff)
		end
		if updateindex then
			chocolates[k].settings.index = i
		end
		relative = chocolates[k]
	end
	
	local relative = nil
	for i, v in ipairs(tempright) do
		k = v[1]
		chocolates[k]:ClearAllPoints()
		if(relative)then
			chocolates[k]:SetPoint("TOPRIGHT",relative,"TOPLEFT", 0,0)
			--list them downwards
			--chocolates[k]:SetPoint("TOPLEFT",relative,"BOTTOMLEFT", 0,-yoffset)
		else
			chocolates[k]:SetPoint("TOPRIGHT",self, 6,yoff)
		end
		if updateindex then
			chocolates[k].settings.index = i
		end
		relative = chocolates[k]
		--Debug("index=",i,k)
	end
end
