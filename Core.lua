
local LibStub = LibStub
local broker = LibStub("LibDataBroker-1.1")
local ChocolateBar = LibStub("AceAddon-3.0"):NewAddon("ChocolateBar", "AceConsole-3.0", "AceEvent-3.0")
ChocolateBar.Bar = {}
ChocolateBar.ChocolatePiece = {}
ChocolateBar.Drag = {}

local Drag = ChocolateBar.Drag
local Chocolate = ChocolateBar.ChocolatePiece
local Bar = ChocolateBar.Bar

local chocolateBars = {}
--ChocolateBar.chocolateBars = chocolateBars
local chocolateObjects = {}
local dataObjects = {}
local db
--------
-- utility functions
--------
local function Debug(...)
	if ChocolateBar.db.char.debug then
	 	local s = "ChocolateBar Debug:"
		for i=1,select("#", ...) do
			local x = select(i, ...)
			s = strjoin(" ",s,tostring(x))
		end
		DEFAULT_CHAT_FRAME:AddMessage(s)
	end
end

function ChocolateBar:Debug(...)
	Debug(self, ...)
end
local Debug = ChocolateBar.Debug

-- RGBToHex code taken with permission from fortress 
local function RGBToHex(r, g, b)
	return ("%02x%02x%02x"):format(r*255, g*255, b*255)	
end

--[[
local function count(t)
	local i = 0
	for k,v in pairs(t) do
		i = i + 1
	end
	return i
end
--]]
--------
-- Ace3 callbacks
--------
function ChocolateBar:OnInitialize()
	self:RegisterOptions()
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	db = self.db.profile
	
	local barSettings = db.barSettings
	for k, v in pairs(barSettings) do
		local name = v.barName
		self:AddBar(k, v, true) --force no anchor update
	end
	self:AnchorBars()
end

function ChocolateBar:OnEnable()
	for name, obj in broker:DataObjectIterator() do
		self:LibDataBroker_DataObjectCreated(nil, name, obj, true) --force noupdate on chocolateBars
	end
	ChocolateBar:UpdateBars() --update chocolateBars here

	broker.RegisterCallback(self, "LibDataBroker_DataObjectCreated")
end

function ChocolateBar:OnDisable()
	for name, obj in broker:DataObjectIterator() do
		chocolateObjects[name]:Hide()
	end
	for k,v in pairs(chocolateBars) do
		v:Hide()
	end
	broker.UnregisterCallback(self, "LibDataBroker_DataObjectCreated")
end

--------
-- LDB callbacks
--------
function ChocolateBar:LibDataBroker_DataObjectCreated(event, name, obj, noupdate)
	local t = obj.type
	if t and (t ~= "data source" and t ~= "launcher") then
		Debug("Unknown type", t, name)
		return
	end
	
	if not dataObjects[name] then
		dataObjects[name] = obj
	end
	
	if db.objSettings[name].enabled then
		self:EnableDataObject(name, noupdate)
	end
	self:AddObjectOptions(name, obj.icon)
end

function ChocolateBar:EnableDataObject(name, noupdate)
	local obj = dataObjects[name]
	local settings = db.objSettings[name]
	
	--get bar from setings
	local barName = settings.barName
	
	local t = obj.type
	-- set default values depending on data source
	if barName == "" then
		barName = "ChocolateBar1"
		if t and t == "data source" then
			settings.align = "left"
			settings.showText = true
		else	
			settings.align = "right"
			settings.showText = false
		end
	end
	obj.name = name
	
	settings.enabled = true
	local choco = Chocolate:New(name, obj, settings)
	chocolateObjects[name] = choco
	
	local bar = chocolateBars[barName]
	if bar then
		bar:AddChocolatePiece(choco, name,noupdate)
	else
		chocolateBars["ChocolateBar1"]:AddChocolatePiece(choco, name,noupdate)
	end
	broker.RegisterCallback(self, "LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
end

function ChocolateBar:DisableDataObject(name)
	--get bar from setings
	db.objSettings[name].enabled = false
	local barName = db.objSettings[name].barName 
	if(not barName or not chocolateBars[barName])then
		--local choco = chocolateObjects[name]
		--if choco and choco.Hide then
		--	choco:Hide()
		--end
	else
		--remove frame from bar
		chocolateBars[barName]:EatChocolatePiece(name)
	end
end

function ChocolateBar:AttributeChanged(event, name, key, value)
	--Debug("ChocolateBar:AttributeChanged ",name," key: ", key, value)
	local settings = db.objSettings[name]
	if not settings.enabled then 
		return 
	end
	local choco = chocolateObjects[name]
	choco:Update(choco, key, value)
end

-- call when general bar options change
-- updatekey: the key of the update function
function ChocolateBar:UpdateBarOptions(updatekey)
	for k,v in pairs(chocolateBars) do
		local func = v[updatekey]
		if func then
			func(v)
		else
			Debug("UpdateBarOptions: invalid updatekey", updatekey)
		end
	end
end

function ChocolateBar:GetChocolate(name)
	return chocolateObjects[name]
end

function ChocolateBar:GetBar(name)
	return chocolateBars[name]
end

function ChocolateBar:OnProfileChanged(event, database, newProfileKey)
	--Debug("OnProfileChanged", event, database, newProfileKey)
	self:UpdateDB(database.profile)
	db = database.profile
	
	for k, v in pairs(chocolateBars) do
		ChocolateBar:RemoveBarOptions(k)
		v:Hide()
		v = nil
	end
	chocolateBars = {}
	local barSettings = db.barSettings
	for k, v in pairs(barSettings) do
		local name = v.barName
		self:AddBar(k, v, true) --force no anchor update
	end
	self:AnchorBars()
	
	self:UpdateBarOptions()
	for name, obj in pairs(dataObjects) do
		if db.objSettings[name].enabled then
			local choco = chocolateObjects[name]
			if choco then
				choco.settings = db.objSettings[name]
			end
			self:DisableDataObject(name)
			self:EnableDataObject(name, true) --no bar update
		else
			self:DisableDataObject(name)
		end
	end
	ChocolateBar:UpdateBars() --update chocolateBars here
end

-- find lowest free bar number
local function getFreeBarName()
	--local i = 1
	local used = false
	local name
	for i=1,100 do
		name = "ChocolateBar"..i
		for k,v in pairs(chocolateBars) do
			Debug("temp / v:GetName():", name, v:GetName())
			if name == v:GetName() then
				used = true
			end
		end
		if not used then
			Debug("free name:", name)
			return name
		end
		used = false
	end
	Debug("no name found ")
end

--------
-- Bars Management
--------
function ChocolateBar:AddBar(name, settings, noupdate)
	if not name then --find free name
		name = getFreeBarName()
		--name = "ChocolateBar"..count(chocolateBars)+1
	end
	if not settings then
		settings = db.barSettings[name]
	end
	local bar = Bar:New(name,settings)
	Drag:RegisterFrame(bar)
	chocolateBars[name] = bar
	ChocolateBar:AddBarOptions(name)
	Debug("AddBar:", name, settings)
	--barSettings[name] = settings
	settings.barName = name
	if not noupdate then
		self:AnchorBars()
	end
end

-- remove a bar and disalbe all plugins in it
function ChocolateBar:RemoveBar(name)
	local bar = chocolateBars[name]
	if bar then
		ChocolateBar:RemoveBarOptions(name)
		bar:Disable()
		for k,v in pairs(chocolateObjects) do
			if v.settings.barName == name then
				self:DisableDataObject(k)
			end
		end
	chocolateBars[name] = nil
	db.barSettings[name] = nil
	self:AnchorBars()
	end
end

function ChocolateBar:UpdateBars()
	for k,v in pairs(chocolateBars) do
		v:UpdateBar()
	end
end

function ChocolateBar:GetNumBars(align)
	local i = 0
	for k,v in pairs(chocolateBars) do
		Debug("k,v.settings.aligin ",k,v.settings.aligin)
		if v.settings.align == align then
			i = i + 1
		end
	end
	return i
end

local temptop = {}
local tempbottom = {}
function ChocolateBar:AnchorBars()
	temptop = {}
	tempbottom = {}
	
	for k,v in pairs(chocolateBars) do
		local settings = v.settings
		local index = settings.index
		if not index then
			index = 500
		end
		if settings.align == "top" then
			table.insert(temptop,{v,index})
		else
			table.insert(tempbottom,{v,index})
		end
	end
	table.sort(temptop, function(a,b)return a[2] < b[2] end)
	table.sort(tempbottom, function(a,b)return a[2] < b[2] end)

	local yoff = 0
	local relative = nil
	for i, v in ipairs(temptop) do
		local bar = v[1]
		bar:ClearAllPoints()
		if(relative)then
			bar:SetPoint("TOPLEFT",relative,"BOTTOMLEFT", 0,-yoff)
			bar:SetPoint("RIGHT", relative ,"RIGHT",0, 0);
		else
			bar:SetPoint("TOPLEFT",-1,1);
			bar:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
		end
		--if updateindex then
			bar.settings.index = i
		--end
		relative = bar
	end
	
	local relative = nil
	for i, v in ipairs(tempbottom) do
		local bar = v[1]
		bar:ClearAllPoints()
		if(relative)then
			bar:SetPoint("BOTTOMLEFT",relative,"TOPLEFT", 0,-yoff)
			bar:SetPoint("RIGHT", relative ,"RIGHT",0, 0);
		else
			bar:SetPoint("BOTTOMLEFT",-1,0);
			bar:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
		end
		--if updateindex then
			bar.settings.index = i
		--end
		relative = bar
	end
end
