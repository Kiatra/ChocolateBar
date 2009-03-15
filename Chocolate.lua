local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local ChocolatePiece = ChocolateBar.ChocolatePiece
local Drag = ChocolateBar.Drag
local Debug = ChocolateBar.Debug
local gap = 7

local function resizeFrame(self)
	local settings = self.settings
	local width = gap
	if self.icon and settings.showIcon then
		width = width + self.icon:GetWidth()
	end
	if settings.showText then
		local textWidth = self.text:GetStringWidth()
		--self.text:SetWidth(textWidth)
		width = width + textWidth	
	end
	self:SetWidth(width)
end

local function TextUpdater(frame, value, name)
	frame.text:SetText(value)
	resizeFrame(frame)
end

local function SettingsUpdater(self, value, name)
	local settings = self.settings
	if not settings.showText then
		self.text:Hide()
	else
		self.text:Show()
	end
	if self.icon then 
		if not settings.showIcon then
			self.icon:Hide()
			self.text:SetPoint("LEFT", self, "LEFT", 0, 0)
		else
			self.icon:Show()
			self.text:SetPoint("LEFT", self.icon, "RIGHT", 0, 0)
		end
	end
	resizeFrame(self)
end

-- updaters code taken with permission from fortress 
local uniqueUpdaters = {
	text = TextUpdater,
	
	icon = function(frame, value, name)
		--if value and self.db.icon then
		if value then
			if frame.icon then
				frame.icon:SetTexture(value)
			end
			--frame:ShowIcon()
		else
			--frame:HideIcon()
		end
	end,
	
	updateSettings = SettingsUpdater,
	-- tooltiptext is no longer in the data spec, but 
	-- I'll continue to support it, as some plugins seem to use it
	tooltiptext = function(frame, value, name)
		local object = dataObjects[name]
		local tt = object.tooltip or GameTooltip
		if tt:GetOwner() == frame then
			tt:SetText(object.tooltiptext)
		end
	end,
	
	OnClick = function(frame, value, name)
		frame:SetScript("OnClick", value)
	end,
}

-- updaters code taken with permission from fortress 
local updaters = {
	label  = TextUpdater,
	value  = TextUpdater,
	suffix = TextUpdater,
}
for k, v in pairs(uniqueUpdaters) do
	updaters[k] = v
end

-- GetAnchors code taken with permission from fortress 
local function GetAnchors(frame)
	local x, y = frame:GetCenter()
	local leftRight
	if x < GetScreenWidth() / 2 then
		leftRight = "LEFT"
	else
		leftRight = "RIGHT"
	end
	if y < GetScreenHeight() / 2 then
		return "BOTTOM", "TOP"
	else
		return "TOP", "BOTTOM"
	end
end

--code taken with permission from fortress 
local function GT_OnLeave(self)
	self:SetScript("OnLeave", self.fortressOnLeave)
	self:Hide()
	GameTooltip:EnableMouse(false)
end

-- PrepareTooltip code taken with permission from fortress 
local function PrepareTooltip(frame, anchorFrame)
	if frame == GameTooltip then
		frame.fortressOnLeave = frame:GetScript("OnLeave")
		frame.fortressBlock = anchorFrame
		frame.fortressName = anchorFrame.name
		
		frame:EnableMouse(true)
		frame:SetScript("OnLeave", GT_OnLeave)
	end
	frame:SetOwner(anchorFrame, "ANCHOR_NONE")
	frame:ClearAllPoints()
	local a1, a2 = GetAnchors(anchorFrame)
	frame:SetPoint(a1, anchorFrame, a2)	
end

local function OnEnter(self)
	local obj  = self.obj
	local name = self.name
		
	if self.bar.autohide then
		local bar = self.bar
		bar:ShowAll()
	end

	if obj.tooltip then
		PrepareTooltip(obj.tooltip, self)
		if obj.tooltiptext then
			obj.tooltip:SetText(obj.tooltiptext)
		end
		obj.tooltip:Show()
	
	elseif obj.OnTooltipShow then
		PrepareTooltip(GameTooltip, self)
		obj.OnTooltipShow(GameTooltip)
		GameTooltip:Show()
	
	elseif obj.tooltiptext then
		PrepareTooltip(GameTooltip, self)
		GameTooltip:SetText(obj.tooltiptext)
		GameTooltip:Show()		
	
	elseif obj.OnEnter then
		obj.OnEnter(self)
	end
end

local function OnLeave(self)
	local obj  = self.obj
	local name = self.name
	
	local bar = self.bar
	if bar.autohide then
		local bar = self.bar
		bar:HideAll()
	end

	if obj.OnLeave then
		obj.OnLeave(self)
	else
		GameTooltip:Hide()
	end
end

-- PrepareTooltip code taken with permission from fortress 
local function PrepareTooltip(frame, anchorFrame)
	if frame == GameTooltip then
		frame.fortressOnLeave = frame:GetScript("OnLeave")
		frame.fortressBlock = anchorFrame
		frame.fortressName = anchorFrame.name
		
		frame:EnableMouse(true)
		frame:SetScript("OnLeave", GT_OnLeave)
	end
	frame:SetOwner(anchorFrame, "ANCHOR_NONE")
	frame:ClearAllPoints()
	local a1, a2 = GetAnchors(anchorFrame)
	frame:SetPoint(a1, anchorFrame, a2)	
end

local function Update(self, f,key, value)
	local update = updaters[key]
	if update then
		update(f, value, name)
	end
end

local function OnDragStart(frame)
	if not ChocolateBar.db.profile.locked or IsAltKeyDown() then 
		local bar = frame.bar	
		Drag:Start(bar, frame.name)
		this:StartMoving()
		this.isMoving = true
		GameTooltip:Hide();
	end
end

local function OnDragStop(frame)
	if not ChocolateBar.db.profile.locked or IsAltKeyDown() then 
		this:StopMovingOrSizing()
		this.isMoving = false
		Drag:Stop(frame)
		frame:SetParent(frame.bar)
	end
end

function ChocolatePiece:New(name, obj, settings, db)
	gap = db.gap
	local height = 15
	local text = obj.text
	local icon = obj.icon
	local chocolate = CreateFrame("Button", "Chocolate" .. name, parent)
	chocolate.Update = Update
	--local frame = chocolate
	--frame:SetWidth(width)
	chocolate:SetHeight(20) --get from bar
	chocolate:EnableMouse(true)
	chocolate:RegisterForDrag("LeftButton")
	chocolate:SetClampedToScreen(true)
	
	chocolate.text = chocolate:CreateFontString(nil, nil, "GameFontHighlight")
	if icon then
		chocolate.icon = chocolate:CreateTexture()
		chocolate.icon:SetHeight(height)
		chocolate.icon:SetWidth(height)
		chocolate.icon:SetPoint("LEFT", chocolate, "LEFT", 0, 0)
		chocolate.text:SetPoint("LEFT", chocolate.icon, "RIGHT", 0, 0)
	else
		chocolate.text:SetPoint("LEFT", chocolate, "LEFT", 0, 0)
	end
	
	chocolate:SetScript("OnEnter", OnEnter)
	
	chocolate:SetScript("OnLeave", OnLeave)
	
	
	chocolate:RegisterForClicks("AnyUp")
	chocolate:SetScript("OnClick", obj.OnClick)
	
	chocolate:Show()
	chocolate.settings = settings
	
	if text then
		chocolate.text:SetText(text)
	else
		obj.text = name
		chocolate.text:SetText(name)
	end

	if icon then
		chocolate.icon:SetTexture(icon)
	end

	SettingsUpdater(chocolate, settings.showText )
	
	chocolate.name = name
	chocolate.obj = obj
	
	chocolate:SetMovable(true)
	chocolate:SetScript("OnDragStart", OnDragStart)
	chocolate:SetScript("OnDragStop", OnDragStop)
	
	return chocolate
end

function ChocolatePiece:UpdateGap(val)
	gap = val
end