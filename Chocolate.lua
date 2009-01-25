
local LibStub = LibStub
local ChocolateBar = LibStub("AceAddon-3.0"):NewAddon("ChocolateBar", "AceConsole-3.0", "AceEvent-3.0")

local broker = LibStub("LibDataBroker-1.1")

ChocolateBar.ChocolatePiece = {}
ChocolateBar.Drag = {}
local Drag = ChocolateBar.Drag
local chocolate = ChocolateBar.ChocolatePiece
ChocolateBar.Bar = {}
local bars = ChocolateBar.Bar
local db
local chocolateObjects = {}
local dataObjects = {}

--------
-- utility functions
--------
local function Debug(...)
	if ChocolateBar.db.char.debug then
	 	local s = "Debug:"
		for i=1,select("#", ...) do
			local x = select(i, ...)
			if(type(x)== "string" or type(x)== "number")then
					s = s.." "..x
			else
				if(x)then
					s = s.." ".."not a string"
				else
					s = s.." ".."nil"
				end
			end
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

--------
-- Ace3 callbacks
--------
function ChocolateBar:OnInitialize()
	self:RegisterOptions()
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	db = self.db.profile
	bars.ChocolateBar1 = bars:New("ChocolateBar1",db.barSettings["ChocolateBar1"])
	--db.barSettings["ChocolateBar2"].yoff = -20
	--bars.ChocolateBar2 = bars:New("ChocolateBar2",db.barSettings["ChocolateBar2"])
	--bars.ChocolateBar2:Hide();
	--bars.ChocolateBar2:SetScript("OnLeave", function(self) self:Hide()end)
	
	Drag:RegisterFrame(bars.ChocolateBar1)
	--Drag:RegisterFrame(bars.ChocolateBar2)
	
	local jostle = LibStub("LibJostle-3.0-mod")
	jostle:RegisterTop(bars.ChocolateBar1)
end


function ChocolateBar:OnEnable()
	for name, obj in broker:DataObjectIterator() do
		self:LibDataBroker_DataObjectCreated(nil, name, obj, true) --force noupdate on bars
	end
	bars.ChocolateBar1:UpdateBar() --update bars here

	broker.RegisterCallback(self, "LibDataBroker_DataObjectCreated")
end

function ChocolateBar:OnDisable()
	for name, obj in broker:DataObjectIterator() do
		self:DisableDataObject(name)
	end
end

--------
-- LDB callbacks
--------
function ChocolateBar:LibDataBroker_DataObjectCreated(event, name, obj, noupdate)
	Debug("Dataobject Registered:", name, obj.text)
	
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
	self:AddObjectOptions(name)
end

function ChocolateBar:EnableDataObject(name, noupdate)
	local obj = dataObjects[name]
	local settings = db.objSettings[name]
	
	--get bar from setings
	local barName = settings.barName
	
	local t = obj.type
	-- set default values depending on data source
	if barName == "" then
		if t and t == "data source" then
			barName = "ChocolateBar1"
			settings.align = "left"
			settings.showText = true
		else	
			--todo bar2
			barName = "ChocolateBar1"
			settings.showText = false
			--settings.align = "left"
			settings.align = "right"
		end
	end
	obj.name = name
	
	settings.barName = barName
	settings.enabled = true
	local choco = chocolate:New(name, obj, settings)
	chocolateObjects[name] = choco
	
	Debug(settings.align)
	bars[barName]:AddChocolatePiece(choco, name,noupdate)
	broker.RegisterCallback(self, "LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
end

function ChocolateBar:DisableDataObject(name)
	--get bar from setings
	db.objSettings[name].enabled = false
	local barName = db.objSettings[name].barName 
	if(not barName or not bars[barName])then
		--local choco = chocolateObjects[name]
		--if choco and choco.Hide then
		--	choco:Hide()
		--end
	else
		--remove frame from bar
		bars[barName]:EatChocolatePiece(name)
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

--call when general bar options change
function ChocolateBar:UpdateBarOptions(val)
	bars.ChocolateBar1:UpdateTexture()
	bars.ChocolateBar1:UpdateColors()
	bars.ChocolateBar1:UpdateScale()
end

function ChocolateBar:OnProfileChanged(event, database, newProfileKey)
	Debug("OnProfileChanged", event, database, newProfileKey)
	self:UpdateDB(database.profile)
	db = database.profile
	self:UpdateBarOptions()
	for name, obj in pairs(dataObjects) do
		if db.objSettings[name].enabled then
			local choco = chocolateObjects[name]
			choco.settings = db.objSettings[name]
			self:DisableDataObject(name)
			self:EnableDataObject(name, true) --no bar update
		else
			self:DisableDataObject(name)
		end
	end
	bars.ChocolateBar1:UpdateBar() --update bars here
end
