local LibStub = LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local Debug = ChocolateBar.Debug
local AceCfgReg = LibStub("AceConfigRegistry-3.0")
local AceCfgDlg = LibStub("AceConfigDialog-3.0")
local Drag = ChocolateBar.Drag

local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")

--local version = GetAddOnMetadata("ChocolateBar","Version") or ""
local version = GetAddOnMetadata("ChocolateBar","X-Curse-Packaged-Version") or ""
local db, moreChocolate
local index = 0
local firstOpen = true


local function GetStats(info)
	local total = 0
	local enabled = 0
	local data = 0
	for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
		total = total + 1
		if obj.type == "data source" then
			data = data + 1
		end
		choco = ChocolateBar:GetChocolate(name)
		if choco and choco.settings.enabled then
			enabled = enabled +1
		end
	end
	
	return strjoin("\n","|cffffd200"..L["Enabled"].."|r  "..enabled, 
						"|cffffd200"..L["Disabled"].."|r  "..total-enabled,
						"|cffffd200"..L["Total"].."|r  "..total,
						"",
						"|cffffd200"..L["Data Source"].."|r  "..data,
						"|cffffd200"..L["Launcher"].."|r  "..total-data
	) 
end

local function EnableAll(info)
	for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
		ChocolateBar:EnableDataObject(name)
	end
end

local function DisableAll(info)
	for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
		ChocolateBar:DisableDataObject(name)
	end
end

local function DisableLauncher(info)
	for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
		if obj.type ~= "data source" then
			ChocolateBar:DisableDataObject(name)
		end
	end
end

aceoptions = { 
    name = "ChocolateBar".." "..version,
    handler = ChocolateBar,
	type='group',
	desc = "ChocolateBar",
    args = {
		general={
			name = L["Look and Feel"],
			type="group",
			order = 0,
			args={
				general = {
					inline = true,
					name = L["General"],
					type="group",
					order = 0,
					args={
						locked = {
							type = 'toggle',
							order = 1,
							name = L["Lock Plugins"],
							desc = L["Hold alt key to drag a plugin."],
							get = function(info, value)
									return db.locked
							end,
							set = function(info, value)
									db.locked = value
							end,
						},
						gap = {
							type = 'range',
							order = 2,
							name = L["Gap"],
							desc = L["Set the gap between the plugins."],
							min = 0,
							max = 15,
							step = 1,
							get = function(name)
								return db.gap
							end,
							set = function(info, value)
								db.gap = value
								ChocolateBar.ChocolatePiece:UpdateGap(value)
								ChocolateBar:UpdateChoclates("updateSettings")
							end,
						},
						size = {
							type = 'range',
							order = 3,
							name = L["Bar Size"],
							desc = L["Bar Size"],
							min = 12,
							max = 30,
							step = 1,
							get = function(name)
								--return db.scale
								return db.height
							end,
							set = function(info, value)
								--db.scale = value
								--ChocolateBar:UpdateBarOptions("UpdateScale")
								db.height = value
								ChocolateBar:UpdateBarOptions("UpdateHeight")
							end,
						},
						strata = {
							type = 'select',
							values = {FULLSCREEN_DIALOG="Fullscreen_Dialog",FULLSCREEN="Fullscreen", 
										DIALOG="Dialog",HIGH="High",MEDIUM="Medium",LOW="Low",BACKGROUND="Background"},
							order = 6,
							name = L["Bar Strata"],
							desc = L["Bar Strata"],
							get = function() 
								return db.strata
							end,
							set = function(info, value)
								db.strata = value
								ChocolateBar:UpdateBarOptions("UpdateStrata")
							end,
						},
						moveFrames = {
							type = 'toggle',
							width = "double",
							order = 7,
							name = L["Adjust Blizzard Frames"],
							desc = L["Move Blizzard frames above/below bars"],
							get = function(info, value)
									return db.moveFrames
							end,
							set = function(info, value)
									db.moveFrames = value
									ChocolateBar:UpdateBarOptions("UpdateAutoHide")
							end,
						},
					},
				},
				defaults = {
					inline = true,
					name= L["Defaults"],
					type="group",
					order = 2,
					args={
						label = {
							order = 0,
							type = "description",
							name = L["Automatically disable new plugins of type:"],
						},
						dataobjects = {
							type = 'toggle',
							order = 1,
							name = L["Data Source"],
							desc = L["If enabled new plugins of type data source will automatically be disabled."],
							get = function()
									return db.autodissource
							end,
							set = function(info, value)
									db.autodissource = value
							end,
						},
						launchers = {
							type = 'toggle',
							order = 2,
							name = L["Launcher"],
							desc = L["If enabled new plugins of type launcher will automatically be disabled."],
							get = function()
									return db.autodislauncher
							end,
							set = function(info, value)
									db.autodislauncher = value
							end,
						},
					},
				},
				combat = {
					--inline = true,
					name= L["In Combat"],
					type="group",
					order = 0,
					args={
						combat = {
							inline = true,
							name= L["In Combat"],
							type="group",
							order = 0,
							args={
								hidetooltip = {
									type = 'toggle',
									order = 1,
									name = L["Disable Tooltips"],
									desc = L["Disable Tooltips"],
									get = function(info, value)
											return db.combathidetip
									end,
									set = function(info, value)
											db.combathidetip = value
									end,
								},
								hidebar = {
									type = 'toggle',
									order = 2,
									name = L["Hide Bars"],
									desc = L["Hide Bars"],
									get = function(info, value)
											return db.combathidebar
									end,
									set = function(info, value)
											db.combathidebar = value
									end,
								},
								disablebar = {
									type = 'toggle',
									order = 2,
									name = L["Disable Clicking"],
									desc = L["Disable Clicking"],
									get = function(info, value)
											return db.combatdisbar
									end,
									set = function(info, value)
											db.combatdisbar = value
									end,
								},
							},
						},
					},
				},
				backbround = {
					--inline = true,
					name = L["Fonts and Textures"],
					type = "group",
					order = 4,
					args ={
						backbround = {
							inline = true,
							name = L["Textures"],
							type = "group",
							order = 1,
							args ={
								texture = {
									type = 'select',
									dialogControl = 'LSM30_Statusbar', --Select your widget here
									values = AceGUIWidgetLSMlists.statusbar,
									order = 1,
									name = L["Background Texture"],
									desc = L["Some of the textures may depend on other addons."],
									get = function() 
										return db.background.textureName
									end,
									set = function(info, value)
										db.background.texture = LSM:Fetch("statusbar", value)
										db.background.textureName = value
										ChocolateBar:UpdateBarOptions("UpdateTexture")
									end,
								},
								colour = {
									type = "color",
									order = 1,
									name = L["Bar color"],
									desc = L["Bar color"],
									hasAlpha = true,
									get = function(info)
										local t = db.background.color
										return t.r, t.g, t.b, t.a
									end,
									set = function(info, r, g, b, a)
										local t = db.background.color
										t.r, t.g, t.b, t.a = r, g, b, a
										ChocolateBar:UpdateBarOptions("UpdateColors")
									end,
								},
								bordercolour = {
									type = "color",
									order = 2,
									name = L["Bar border color"],
									desc = L["Bar border color"],
									hasAlpha = true,
									get = function(info)
										local t = db.background.borderColor
										return t.r, t.g, t.b, t.a
									end,
									set = function(info, r, g, b, a)
										local t = db.background.borderColor
										t.r, t.g, t.b, t.a = r, g, b, a
										ChocolateBar:UpdateBarOptions("UpdateColors")
									end,
								},
							},
						},
						fonts = {
							inline = true,
							name = L["Font"],
							type = "group",
							order = 2,
							args ={
								font = {
								type = 'select',
								dialogControl = 'LSM30_Font',
								values = AceGUIWidgetLSMlists.font,
								order = 1,
								name = L["Font"],
								desc = L["Some of the fonts may depend on other addons."],
								get = function() 
									return db.fontName
								end,
								set = function(info, value)
									db.fontPath = LSM:Fetch("font", value)
									db.fontName = value
									ChocolateBar:UpdateChoclates("updatefont")
								end,
								},
								fontSize = {
									type = 'range',
									order = 2,
									name = L["Font Size"],
									desc = L["Font Size"],
									min = 8,
									max = 20,
									step = .5,
									get = function(name)
										return db.fontSize
									end,
									set = function(info, value)
										db.fontSize = value
										ChocolateBar:UpdateChoclates("updatefont")
									end,
								},
								textcolour = {
									type = "color",
									order = 3,
									name = L["Text color"],
									desc = L["Default text color of a plugin. This will not overwrite plugins that use own colors."],
									hasAlpha = true,
									get = function(info)
										local t = db.textColor or {r = 1, g = 1, b = 1, a = 1}
										return t.r, t.g, t.b, t.a
									end,
									set = function(info, r, g, b, a)
										db.textColor = db.textColor or {r = 1, g = 1, b = 1, a = 1}
										local t = db.textColor
										t.r, t.g, t.b, t.a = r, g, b, a
										ChocolateBar:UpdateChoclates("updateSettings")
									end,
								},
							},
						},
					},
				},
				--@debug@
				debug = {
					type = 'toggle',
					--width = "half",
					order = 20,
					name = "Debug",
					desc = "This one is for me, not for you :P",
					get = function(info, value)
							return ChocolateBar.db.char.debug
					end,
					set = function(info, value)
							ChocolateBar.db.char.debug = value
					end,
				},
				--@end-debug@
			},
		},
		bars={
			name = L["Bars"],
			type ="group",
			order = 20,
			args ={
				new = {
					type = 'execute',
		            --width = "half",
					order = 0,
					name = L["Create Bar"],
		            desc = L["Create New Bar"],
		            func = function()
						ChocolateBar:AddBar()
					end,
				},
			},
		},
		chocolates={
			name = L["Plugins"],
			type="group",
			order = -1,
			args={
				stats = {
					inline = true,
					name = L["Plugin Statistics"],
					type="group",
					order = 1,
					args={
						stats = {
							order = 1,
							type = "description",
							name = GetStats,
						},
					},
				},
				quickconfig = {
					inline = true,
					name = L["Quick Config"],
					type = "group",
					order = 2,
					args ={
						enableAll = {
							type = 'execute',
							order = 3,
							name = L["Enable All"],
							desc = L["Get back my plugins!"],
							func = EnableAll,
						},
						disableAll = {
							type = 'execute',
							order = 4,
							name = L["Disable All"],
							desc = L["Eat all the chocolate at once, uff..."],
							func = DisableAll,
						},
						disableLauncher = {
							type = 'execute',
							order = 5,
							name = L["Disable all Launchers"],
							desc = L["Disable all the bad guy's:)"],
							func = DisableLauncher,
						},
					},
				},
			},
		},
	},
}
local chocolateOptions = aceoptions.args.chocolates.args
local barOptions = aceoptions.args.bars.args

-----
-- bar option functions
-----
local function GetBarName(info)
	local name = info[#info]
	bar = ChocolateBar:GetBar(name)
	if bar and bar.settings.align == "top" then
		name = name.." (top) "
	elseif bar and bar.settings.align == "bottom" then
		name = name.." (bottom) "
	else
		name = name.." (custom) "
	end
	return name
end

local function GetBarIndex(info)
	local name = info[#info]
	bar = ChocolateBar:GetBar(name)
	local index = bar.settings.index
	if db.barSettings[name].align == "bottom" then
		--reverse order and force below top bars
		index = index *-1 + 100
	end
	return index
end

local function SetBarAlign(info, value)
	local name = info[#info-2]
	if value then
		db.barSettings[name].align = value
		bar = ChocolateBar:GetBar(name)
		if bar then
			bar:UpdateAutoHide(db)
			ChocolateBar:AnchorBars()
		end
	end
end

local function GetBarAlign(info, value)
	local name = info[#info-2]
	return db.barSettings[name].align
end

local function EatBar(info, value)
	local name = info[#info-2]
	ChocolateBar:RemoveBar(name)
end

local function MoveUp(info, value)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	local index = bar.settings.index
	if bar then
		if db.barSettings[name].align == "bottom" then
			index = index +1.5
			if index > (ChocolateBar:GetNumBars("bottom")+1) then
				index = ChocolateBar:GetNumBars("top")+1
				SetBarAlign(info, "top")
			end
		elseif db.barSettings[name].align == "top" then
			index = index -1.5
		else
			db.barSettings[name].align = "top"
			index = 0
			SetBarAlign(info, "top")
		end
		bar.settings.index = index
		ChocolateBar:AnchorBars()
	end
end

local function MoveDown(info, value)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	local index = bar.settings.index
	if bar then
		if db.barSettings[name].align == "bottom" then
			index = index -1.5
		elseif db.barSettings[name].align == "top" then
			index = index +1.5
			if index > (ChocolateBar:GetNumBars("top")+1) then
				index = ChocolateBar:GetNumBars("bottom")+1
				SetBarAlign(info, "bottom")
			end
		else
			db.barSettings[name].align = "top"
			index = 0
			SetBarAlign(info, "top")
		end
		bar.settings.index = index
		ChocolateBar:AnchorBars()
	end
end
	
local function getAutoHide(info, value)
	local name = info[#info-2]
	return db.barSettings[name].autohide
end

local function setAutoHide(info, value)
	local name = info[#info-2]
	db.barSettings[name].autohide = value
	bar = ChocolateBar:GetBar(name)
	bar:UpdateAutoHide(db)
	--ChocolateBar:UpdateBarOptions("UpdateAutoHide")
end

local function GetBarWidth(info)
	Debug(GetScreenWidth(),UIParent:GetEffectiveScale(),UIParent:GetWidth(),math.floor(GetScreenWidth()))
	local name = info[#info-2]
	local maxBarWidth = math.floor(GetScreenWidth())
	
	return db.barSettings[name].width
end

local function SetBarWidth(info, value)
	Debug("SetBarWidht", value)
	local name = info[#info-2]
	local settings = db.barSettings[name]
	settings.width = value
	bar = ChocolateBar:GetBar(name)
	if value > GetScreenWidth() or value == 0 then
		bar:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
	else	
		local relative, relativePoint
		settings.barPoint ,relative ,relativePoint,settings.barOffx ,settings.barOffy = bar:GetPoint()
		bar:ClearAllPoints()
		bar:SetPoint(settings.barPoint, "UIParent",settings.barOffx ,settings.barOffy)	
		bar:SetWidth(value)
	end
end

local moveBarDummy
function OnDragStart(self)
	self:StartMoving()
	self.isMoving = true
end

function OnDragStop(self)
	self:StopMovingOrSizing()
	self.isMoving = false
end

local function SetLockedBar(info, value)
	Debug("SetLockedBar", value)
	local name = info[#info-2]
	local settings = db.barSettings[name]
	bar = ChocolateBar:GetBar(name)
	bar.locked = not value
	if not value then
		--unlock
		if not moveBarDummy then
			moveBarDummy = CreateFrame("Frame",bar)
			moveBarDummy:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												nil, 
												tile = true, tileSize = 16, edgeSize = 16, 
												nil});
			moveBarDummy:SetBackdropColor(1,0,0,1);
			moveBarDummy:RegisterForDrag("LeftButton")
			moveBarDummy:SetFrameStrata("FULLSCREEN_DIALOG")
			moveBarDummy:SetFrameLevel(20)
			moveBarDummy:SetScript("OnMouseUp", function() 
				if arg1 == "RightButton" then
					ChocolateBar:ChatCommand()
				end
			end)
		end
		moveBarDummy.bar = bar
		moveBarDummy:SetAllPoints(bar)
		moveBarDummy:Show()
		
		bar:RegisterForDrag("LeftButton")
		bar:EnableMouse(true)
		bar:SetMovable(true)
		bar:SetScript("OnDragStart",OnDragStart)
		bar:SetScript("OnDragStop",OnDragStop)
		for k, v in pairs(bar.chocolist) do
			v:Hide()
		end
	else
		for k, v in pairs(bar.chocolist) do
			v:Show()
		end
		bar:SetScript("OnDragStart", nil)
		settings.barPoint ,relative ,relativePoint,settings.barOffx ,settings.barOffy = bar:GetPoint()
		settings.align = "custom"
		if moveBarDummy then moveBarDummy:Hide() end 
	end
end

local function GetFreeBar(info)
	local name = info[#info-2]
	Debug("GetManageBar", db.barSettings[name].align)
	return db.barSettings[name].align == "custom"
end

local function SetFreeBar(info, value)
	local name = info[#info-2]
	--db.barSettings[name].align = value and "custom" or "top"
	Debug("SetFreeBar", db.barSettings[name].align,value,name)
	bar = ChocolateBar:GetBar(name)
	if not value then
		SetLockedBar(info, true)
		db.barSettings[name].align = "top"
		bar:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
		ChocolateBar:AnchorBars()
	else
		db.barSettings[name].align = "custom"
	end
	bar:UpdateJostle(db)
	Debug("SetFreeBar", db.barSettings[name].align,value,name)
end

local function GetBarOffX(info, value)
	--Debug(info[#info-1],info[#info-2],info[#info-3],info[#info])
	local name = info[#info-2]
	return db.barSettings[name].barOffx
end

local function GetBarOffY(info, value)
	local name = info[#info-2]
	return db.barSettings[name].barOffy
end

local function SetBarOff(info, value)
	local name = info[#info-2]
	local offtype = info[#info]
	bar = ChocolateBar:GetBar(name)
	local settings = db.barSettings[name]
	bar = ChocolateBar:GetBar(name)	
	local relative, relativePoint
	settings.barPoint ,relative ,relativePoint,settings.barOffx ,settings.barOffy = bar:GetPoint()
	if offtype == "xoff" then
		settings.barOffx = value
	else
		settings.barOffy = value
	end
	bar:ClearAllPoints()
	bar:SetPoint(settings.barPoint, "UIParent",settings.barOffx ,settings.barOffy)	
end

local function GetLockedBar(info, value)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	return not bar.locked
end


-------------
-- bar options disabled/enabled
--------------------
local function IsDisabledFreeMove(info)
	local name = info[#info-2]
	Debug("IsDisabledFreeMove", not (db.barSettings[name].align == "custom"),db.barSettings[name].align,name)
	return not (db.barSettings[name].align == "custom")
end

--return true if RemoveBar is disabled
function IsDisabledRemoveBar(info)
	local name = info[#info-2]
	return name == "ChocolateBar1"
end

local function IsDisabledMoveDown(info)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	local settings = db.barSettings[name]
	return settings.align == "custom" or (settings.align == "bottom" and  bar.settings.index < 1.5)
end

local function IsDisabledMoveUp(info)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	local settings = db.barSettings[name]
	return settings.align == "custom" or (settings.align == "top" and  bar.settings.index < 1.5)
end

-----
-- chocolate option functions
-----
local function GetName(info)
	local cleanName = info[#info]
	local name = chocolateOptions[cleanName].desc
	--local icon = chocolateOptions[cleanName].icon
	if(not db.objSettings[name].enabled)then
		--cleanName = "|TZZ"..cleanName.."|t|T"..icon..":18|t |cFFFF0000"..cleanName.."|r"
		cleanName = "|H"..cleanName.."|h|cFFFF0000"..cleanName.."|r"
	elseif ChocolateBar:GetChocolate(name).obj.type == "data source" then
	--else
		cleanName = "|H"..cleanName.."|h"..cleanName
	else
		cleanName = "|H"..cleanName.."|h|cFFBBBBBB"..cleanName.."|r"
	end
	return cleanName
end

local function GetType(info)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].type == "data source" and L["Type"]..": "..L["Data Source"].."\n" or L["Type"]..": "..L["Launcher"].."\n"
end

local function SetEnabled(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	if value then
		ChocolateBar:EnableDataObject(name)
	else
		ChocolateBar:DisableDataObject(name)
	end
end

local function GetEnabled(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].enabled
end

local function GetIcon(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].showIcon
end

local function SetIcon(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	db.objSettings[name].showIcon = value
	ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetText(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].showText
end

local function SetText(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	db.objSettings[name].showText = value
	ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetWidth(info)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].width
end

local function SetWidth(info, value)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	db.objSettings[name].width = value
	ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetIconImage(info, name)
	if info then
		local cleanName = info[#info]
		name = chocolateOptions[cleanName].desc
	end
	local obj = ChocolateBar:GetDataObject(name)
	if obj and obj.icon then	
		return obj.icon	
	end
	return "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece"
end

local function IsDisabledIcon(info)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	local obj = ChocolateBar:GetDataObject(name)
	return not (obj and obj.icon) --return true if there is no icon
end

local function GetHeaderName(info)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	return "|T"..GetIconImage(nil, name)..":18|t "..name
end

local function GetHeaderImage(info)
	local cleanName = info[#info-2]
	local name = chocolateOptions[cleanName].desc
	return GetIconImage(nil, name), 20 ,20
end

-- drop points
local function dropText(frame, choco)
		local name = choco.name
		db.objSettings[name].showText = not db.objSettings[name].showText
		ChocolateBar:AttributeChanged(nil, name, "updateSettings", db.objSettings[name].showText)
		choco.bar:ResetDrag(choco, name)
		frame:SetBackdropColor(0,0,0,1)
end

local function dropCenter(frame, choco)
		local name = choco.name
		db.objSettings[name].align = "center"
		db.objSettings[name].stickcenter = true
		choco.bar:ResetDrag(choco, name)
		frame:SetBackdropColor(0,0,0,1)
end

local function dropDisable(frame, choco)
		choco:Hide()
		ChocolateBar:DisableDataObject(choco.name)
		frame:SetBackdropColor(0,0,0,1) 
end

local function createDropPoint(name, dropfunc, offx, text, texture)
	if not ChocolateBar.dropFrames then
		dropFrames = CreateFrame("Frame", nil, UIParent)
		dropFrames:SetWidth(400)
		dropFrames:SetHeight(100)
		ChocolateBar.dropFrames = dropFrames
	end
	local frame = CreateFrame("Frame", name, ChocolateBar.dropFrames)
	frame:SetWidth(100)
	frame:SetHeight(100)
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOPLEFT",offx,0)
	--ChocolateBar:Debug(UIParent:GetScale())
	--frame:SetPoint("CENTER",offx,250*UIParent:GetEffectiveScale() )
	
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
	--frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)
	frame.text:SetPoint("CENTER",0, 30)
	frame.text:SetText(text)
	--frame:SetAlpha(0.5)
	
	frame:Hide()
	frame.Drop = dropfunc
	frame.GetFocus = function(frame, name) frame:SetBackdropColor(1,0,0,1) end
		
	frame.Drag = function(frame) end
	frame.LoseFocus = function(frame) frame:SetBackdropColor(0,0,0,1) end
	Drag:RegisterFrame(frame)
	return frame
end

function ChocolateBar:SetDropPoins(parent)
	local frame = ChocolateBar.dropFrames
	frame:ClearAllPoints()
	frame:SetClampedToScreen(true)
	local x,y = parent:GetCenter()
	local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
	local yoff = (y > UIParent:GetHeight() / 2) and -100 or 100
	local xoff = frame:GetWidth() / 2
	frame:SetPoint(vhalf.."LEFT",parent.bar,x-xoff,yoff)
	frame:Show()
end

function ChocolateBar:UpdateDB(data)
	db = data
end

function ChocolateBar:RegisterOptions()
	self.db = LibStub("AceDB-3.0"):New("ChocolateBarDB", defaults, "Default")
	
	moreChocolate = LibStub("LibDataBroker-1.1"):GetDataObjectByName("MoreChocolate")
	if moreChocolate then
		aceoptions.args.morechocolate = moreChocolate:GetOptions()
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChocolateBar", aceoptions)
	aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local optionsFrame = AceCfgDlg:AddToBlizOptions("ChocolateBar", "ChocolateBar")
	AceCfgDlg:SetDefaultSize("ChocolateBar", 600, 600)
	
	self:RegisterChatCommand("cb", "ChatCommand")
    self:RegisterChatCommand("chocolatebar", "ChatCommand")
	
	self.db:RegisterDefaults({
		profile = {
			combathidetip = false,
			combathidebar = false,
			combatdisbar = false,
			hideonleave = false,
			scale = 1,
			height = 21,
			moveFrames = true,
			strata = "DIALOG",
			gap = 7,
			moreBar = "none",
			moreBarDelay = 4,
			fontPath = " ",
			fontSize = 12,
			background = {
				textureName = "DarkBottom",
				texture = "Interface\\AddOns\\ChocolateBar\\pics\\DarkBottom",
				borderTexture = "Tooltip-Border",
				color = {r = 0.38, g = 0.36, b = 0.4, a = .94,},
				borderColor = {r = 0, g = 0, b = 0, a = 0,},
				tile = false,
				tileSize = 32,
				edgeSize = 8,
				barInset = 3,
			},
			textColor = nil,
			barSettings = {
				['*'] = {
					barName = "ChocolateBar1",
					align = "top",
					autohide = false,
					enabled = true,
					showText = true,
					showIcon = true,
					index = 10,
					width = 0,
				},
				['ChocolateBar1'] = {
					barName = "ChocolateBar1",
					align = "top",
					autohide = false,
					enabled = true,
					showText = true,
					showIcon = true,
					index = 1,
					width = 0,
				},
			},
			objSettings = {
				['*'] = {
					barName = "",
					align = "left",
					enabled = true,
					showText = true,
					showIcon = true,
					index = 1,
					width = 0,
				},
			},
		},
		char = {
			debug = false,
		}
	})
	
	db = self.db.profile
	LSM:Register("statusbar", "Tooltip", "Interface\\Tooltips\\UI-Tooltip-Background")
	LSM:Register("statusbar", "Solid", "Interface\\Buttons\\WHITE8X8")
	LSM:Register("statusbar", "Blizzard Parchment","Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
	LSM:Register("statusbar", "Titan","Interface\\AddOns\\ChocolateBar\\pics\\Titan")
	LSM:Register("statusbar", "Gloss","Interface\\AddOns\\ChocolateBar\\pics\\Gloss")
	LSM:Register("statusbar", "DarkBottom","Interface\\AddOns\\ChocolateBar\\pics\\DarkBottom")

	createDropPoint("ChocolateTextDrop", dropText, 0,L["Toggle Text"],"Interface/ICONS/INV_Inscription_Tradeskill01")
	createDropPoint("ChocolateCenterDrop", dropCenter,150,L["Align Center"],"Interface/Icons/Spell_Holy_GreaterBlessingofSalvation") 
	createDropPoint("ChocolateDisableDrop", dropDisable, 300,L["Disable Plugin"], "Interface/ICONS/Spell_ChargeNEgative")
end

function ChocolateBar:ChatCommand(input)
	if not input or input:trim() == "" then
		AceCfgDlg:SelectGroup("ChocolateBar", "chocolates")
		AceCfgDlg:Open("ChocolateBar")
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(ChocolateBar, "cb", "ChocolateBar", input)
    end
end

function ChocolateBar:AddBarOptions(name)
	barOptions[name] = {
		name = GetBarName,
		desc = name,
		icon = icon,
		type = "group",
		order = GetBarIndex,
		args={
			general = {
				inline = true,
				name=name,
				type="group",
				order = 0,
				args={
					autohide = {
						type = 'toggle',
						order = 5,
						name = L["Autohide"],
						desc = L["Autohide"],
						get = getAutoHide,
						set = setAutoHide,
					},
					eatBar = {
						type = 'execute',
						order = 6,
						name = L["Remove Bar"],
						desc = L["Eat a whole chocolate bar, oh my.."],
						func = EatBar,
						disabled = IsDisabledRemoveBar,
						confirm = true,
					},
					free = {
						type = 'toggle',
						order = -1,
						name = L["Free Placement"],
						desc = L["Enable free placement for this bar"],
						get = GetFreeBar,
						set = SetFreeBar,
					},
				},
			},
			move = {
				inline = true,
				name=L["Managed Placement"],
				type="group",
				order = 2,
				args={
					moveup = {
						type = 'execute',
						order = 3,
						name = L["Move Up"],
						desc = L["Move Up"],
						func = MoveUp,
						disabled = IsDisabledMoveUp,
					},
					movedown = {
						type = 'execute',
						order = 4,
						name = L["Move Down"],
						desc = L["Move Down"],
						func = MoveDown,
						disabled = IsDisabledMoveDown,
					},
				},
			},
			free = {
				inline = true,
				name=L["Free Placement"],
				type="group",
				order = -1,
				args={
					locked = {
						type = 'toggle',
						order = 7,
						name = L["Locked"],
						desc = L["Unlock to to move the bar anywhere you want."],
						get = GetLockedBar,
						set = SetLockedBar,
						disabled = IsDisabledFreeMove,
					},
					width = {
						type = 'range',
						order = 8,
						name = L["Bar Width"],
						desc = L["Set a width for the bar."],
						min = 0,
						--max = maxBarWidth,
						max = 3000,
						step = 1,
						get = GetBarWidth,
						set = SetBarWidth,
						disabled = IsDisabledFreeMove,
					},
					xoff = {
						type = 'range',
						order = 9,
						name = L["Horizontal Offset"],
						desc = L["Horizontal Offset"],
						min = -2000,
						max = 2000,
						step = 1,
						get = GetBarOffX,
						set = SetBarOff,
						disabled = IsDisabledFreeMove,
					},
					yoff = {
						type = 'range',
						order = 10,
						name = L["Vertical Offset"],
						desc = L["Vertical Offset"],
						min = -2000,
						max = 2000,
						step = 1,
						get = GetBarOffY,
						set = SetBarOff,
						disabled = IsDisabledFreeMove,
					},
				},
			},
		},
	}
end

function ChocolateBar:RemoveBarOptions(name)
	barOptions[name] = nil
end

function ChocolateBar:AddObjectOptions(name,icon, t, label)
	
	--local curse = GetAddOnMetadata(name,"X-Curse-Packaged-Version") or ""
	--local version = GetAddOnMetadata(name,"Version") or ""
	
	t = t or "not set"
	local cleanName
	if label then 
		cleanName = string.gsub(label, "\|c........", "")
	else
		cleanName = string.gsub(name, "\|c........", "")
	end
	cleanName = string.gsub(cleanName, "\|r", "")
	cleanName = string.gsub(cleanName, "[%c \127]", "")

	--use cleanName of name becaus aceconfig does not like some characters in the plugin names
	chocolateOptions[cleanName] = {
		name = GetName,
		desc = name,
		icon = GetIconImage,
		--iconCoords = GetIconCoords,
		type = "group",
		args={
			chocoSettings = {
				inline = true,
				name=GetHeaderName,
				type="group",
				order = 1,
				args={
					label = {
						order = 2,
						type = "description",
						name = GetType,
						--image = GetHeaderImage,
					},
					enabled = {
						type = 'toggle',
						--width "half",
						order = 3,
						name = L["Enabled"],
						desc = L["Enabled"],
						get = GetEnabled,
						set = SetEnabled,
					},
					text = {
						type = 'toggle',
						--width = "half",
						order = 4,
						name = L["Show Text"],
						desc = L["Show Text"],
						get = GetText,
						set = SetText,
					},
					icon = {
						type = 'toggle',
						--width = "half",
						order = 5,
						name = L["Show Icon"],
						desc = L["Show Icon"],
						get = GetIcon,
						set = SetIcon,
						disabled = IsDisabledIcon,
					},
					width = {
						type = 'range',
						order = 6,
						name = L["Fixed Text Width"],
						desc = L["Set a width for the text. Set 0 to disable fixed text width."],
						min = 0,
						max = 500,
						step = 1,
						get = GetWidth,
						set = SetWidth,
					},
				},
			},
		},
	}
end
