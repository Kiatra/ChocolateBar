local LibStub = LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local Debug = ChocolateBar.Debug
local AceCfgReg = LibStub("AceConfigRegistry-3.0")
local AceCfgDlg = LibStub("AceConfigDialog-3.0")
local Drag = ChocolateBar.Drag

--local version = GetAddOnMetadata("ChocolateBar","Version") or ""
local version = GetAddOnMetadata("ChocolateBar","X-Curse-Packaged-Version") or ""
local db
local index = 0
local moreChocolate
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
	return "|cffffd200Enabled|r  "..enabled.."\n|cffffd200Disabled|r  "..total-enabled.."\n|cffffd200Total|r  "..total.."\n\n|cffffd200Data Source|r  "..data.."\n|cffffd200Other|r  "..total-data
end

local function EnableAll(info)
	--[[
	test = {}
	for k, v in pairs(info) do
		Debug(k,v)
		test[k]=v
	end
	Debug(info[#info])
	--]]
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
	--childGroups = "tab",
	type='group',
	desc = "ChocolateBar",
    args = {
		general={
			name="General",
			type="group",
			order = 0,
			--guiHidden = true,
			args={
				general = {
					inline = true,
					name="General",
					type="group",
					order = 0,
					args={
						locked = {
							type = 'toggle',
							order = 1,
							name = "Lock Chocolates",
							desc = "Hold alt key to drag a chocolate.",
							get = function(info, value)
									return db.locked
							end,
							set = function(info, value)
									db.locked = value
							end,
						},
						moveFrames = {
							type = 'toggle',
							width = "double",
							order = 2,
							name = "Adjust Blizzard Frames",
							desc = "Move Blizzard frames above/below bars",
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
				combat = {
					inline = true,
					name="In Combat",
					type="group",
					order = 0,
					args={
						hidetooltip = {
							type = 'toggle',
							order = 1,
							name = "Disable Tooltips",
							desc = "Disable Tooltips",
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
							name = "Hide Bars",
							desc = "Hide Bars",
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
							name = "Disable Clicking",
							desc = "Disable Clicking",
							get = function(info, value)
									return db.combatdisbar
							end,
							set = function(info, value)
									db.combatdisbar = value
							end,
						},
					},
				},
				frameSettings = {
					inline = true,
					name="Frame Settings",
					type="group",
					order = 3,
					args={
						size = {
							type = 'range',
							order = 1,
							name = "Bar Size",
							desc = "Bar Size",
							min = 0.5,
							max = 1.5,
							step = .1,
							get = function(name)
								return db.scale
							end,
							set = function(info, value)
								ChocolateBar:UpdateBarOptions("UpdateScale")
								db.scale = value
							end,
						},
						gap = {
							type = 'range',
							order = 2,
							name = "Gap",
							desc = "Set the gap between the chocolates.",
							min = 0,
							max = 15,
							step = 1,
							get = function(name)
								return db.gap
							end,
							set = function(info, value)
								db.gap = value
								ChocolateBar.ChocolatePiece:UpdateGap(value)
								ChocolateBar:UpdateChoclates(value)
							end,
						},	
						strata = {
							type = 'select',
							values = {FULLSCREEN_DIALOG="Fullscreen_Dialog",FULLSCREEN="Fullscreen", 
										DIALOG="Dialog",HIGH="High",MEDIUM="Medium",LOW="Low",BACKGROUND="Background"},
							order = 3,
							name = "Frame Strata",
							desc = "Frame Strata",
							get = function() 
								return db.strata
							end,
							set = function(info, value)
								db.strata = value
								ChocolateBar:UpdateBarOptions("UpdateStrata")
							end,
						},
					},
				},
				backbround = {
					inline = true,
					name="Dark Chocolate?",
					type="group",
					order = 4,
					args={
						texture = {
							type = 'select',
							dialogControl = 'LSM30_Statusbar', --Select your widget here
							values = AceGUIWidgetLSMlists.statusbar,
							order = 1,
							name = "Background Texture",
							desc = "Background Texture",
							get = function() 
								return db.background.texture
							end,
							set = function(info, value)
								db.background.texture = value 
								ChocolateBar:UpdateBarOptions("UpdateTexture")
							end,
						},
						colour = {
							type = "color",
							order = 1,
							name = "Bar color",
							desc = "Bar color",
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
							name = "Bar border color",
							desc = "Bar border color",
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
			},
		},
		bars={
			name="Bars",
			type="group",
			order = 20,
			args={
				new = {
					type = 'execute',
		            --width = "half",
					order = 0,
					name = "Create Bar",
		            desc = "Create New Bar",
		            func = function()
						ChocolateBar:AddBar()
					end,
				},
			},
		},
		chocolates={
			name="Chocolates",
			type="group",
			order = -1,
			--childGroups = "select", 
			--validate = function(info, value) end,
			--guiHidden = true,
			args={
				--[[
				header = {
					order = 1,
					type = "header",
					name =  "Quick Config",
				},
				--]]
				stats = {
					inline = true,
					name="Chocolate Statistics",
					type="group",
					order = 1,
					args={
						stats = {
							order = 1,
							type = "description",
							name = GetStats,
							--image = icon,
						},
					},
				},
				quickconfig = {
					inline = true,
					name="Quick Config",
					type="group",
					order = 2,
					args={
						enableAll = {
							type = 'execute',
							--width = "half",
							order = 3,
							name = "Enable All",
							desc = "Get back my chocolate!",
							func = EnableAll,
						},
						disableAll = {
							type = 'execute',
							--width = "half",
							order = 4,
							name = "Disable All",
							desc = "Eat all the chocolate at once, uff...",
							func = DisableAll,
						},
						disableLauncher = {
							type = 'execute',
							--width = "half",
							order = 5,
							name = "Disable all Launchers",
							desc = "Eat all the bad guy's:)",
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
	else
		name = name.." (bottom) "
	end
	return name
end

local function GetBarIndex(info)
	local name = info[#info]
	bar = ChocolateBar:GetBar(name)
	local index = bar.settings.index
	if db.barSettings[name].align == "bottom" then
		--reverse order and force below to bars
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
	--Debug("GetBarAlign",name, value)
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
		else --top bar
			index = index -1.5
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
		else --top bar
			index = index +1.5
			if index > (ChocolateBar:GetNumBars("top")+1) then
				index = ChocolateBar:GetNumBars("bottom")+1
				SetBarAlign(info, "bottom")
			end
		end
		bar.settings.index = index
		ChocolateBar:AnchorBars()
	end
end

local function isMoveDown(info)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	if db.barSettings[name].align == "bottom" then
		if bar.settings.index < 1.5 then
			return true
		end
	end
	return false
end

local function isMoveUp(info)
	local name = info[#info-2]
	bar = ChocolateBar:GetBar(name)
	if db.barSettings[name].align == "top" then
		if bar.settings.index < 1.5 then
			return true
		end
	end
	return false
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

--return true if RemoveBar is disabled
function isRemoveBar(info)
	local name = info[#info-2]
	--Debug("valRemoveBar ",name)
	if name == "ChocolateBar1" then
		return true
	else
		return false
	end
end
-----
-- chocolate option functions
-----

local function GetName(info)
	local cleanName = info[#info]
	local name = chocolateOptions[cleanName].desc
	local icon = chocolateOptions[cleanName].icon
	if(not db.objSettings[name].enabled)then
		--cleanName = "|TZZ"..cleanName.."|t|T"..icon..":18|t |cFFFF0000"..cleanName.."|r"
		cleanName = "|cFFFF0000"..cleanName.."|r"
	elseif ChocolateBar:GetChocolate(name).obj.type == "data source" then
	--else
		cleanName = cleanName
	else
		cleanName = "|cFFBBBBBB"..cleanName.."|r"
	end
	return cleanName
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

local function GetIconImage(info, name)
	if info then
		local cleanName = info[#info]
		name = chocolateOptions[cleanName].desc
	end
	choco = ChocolateBar:GetChocolate(name)
	if choco and choco.obj.icon then	
		return choco.obj.icon	
	end
	return "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece"
end

--[[
local function GetIconCoords(info, name)
	Debug("GetIconCoords")
	if info then
		local cleanName = info[#info]
		name = chocolateOptions[cleanName].desc
	end
	choco = ChocolateBar:GetChocolate(name)
	if choco and choco.obj.iconCoords then	
		Debug(name, choco.obj.iconCoords)
		return choco.obj.iconCoords	
	end
	return nil
end
--]]

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
		choco.bar:AddChocolatePiece(choco, name,noupdate)
		frame:SetBackdropColor(1,1,1,1) 
end

local function dropCenter(frame, choco)
		local name = choco.name
		db.objSettings[name].align = "center"
		--ChocolateBar:AttributeChanged(nil, name, "updateSettings", db.objSettings[name].center)
		choco.bar:AddChocolatePiece(choco, name,noupdate)
		frame:SetBackdropColor(1,1,1,1) 
end

local function dropDisable(frame, choco)
		choco:Hide()
		ChocolateBar:DisableDataObject(choco.name)
		frame:SetBackdropColor(1,1,1,1) 
end

local function createDropPoint(name, dropfunc, offx, text, texture)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetWidth(100)
	frame:SetHeight(100)
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("CENTER",offx,320)
	frame:SetBackdrop({bgFile = texture, 
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = false, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }});	
	frame:SetBackdropBorderColor(1,1,1,0)
	frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
	--frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)
	frame.text:SetPoint("CENTER",0, 30)
	frame.text:SetText(text)
	--frame:SetAlpha(0.5)
	
	frame:Hide()
	frame.Drop = dropfunc
	frame.GetFocus = function(frame) frame:SetBackdropColor(1,0,0,1) end
		
	frame.Drag = function(frame) end
	frame.LoseFocus = function(frame) frame:SetBackdropColor(1,1,1,1) end
	Drag:RegisterFrame(frame)
end

function ChocolateBar:UpdateDB(data)
	db = data
end

function ChocolateBar:RegisterOptions()
	self.db = LibStub("AceDB-3.0"):New("ChocolateBarDB", defaults)

	
	-- change to a more modulare way once there is a need for real modules
	moreChocolate = LibStub("LibDataBroker-1.1"):GetDataObjectByName("MoreChocolate")
	if moreChocolate then
		aceoptions.args.morechocolate = moreChocolate:GetOptions()
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChocolateBar", aceoptions)
	aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local optionsFrame = AceCfgDlg:AddToBlizOptions("ChocolateBar", "ChocolateBar")
	AceCfgDlg:SetDefaultSize("ChocolateBar", 600, 600)
	AceCfgDlg:SelectGroup("ChocolateBar", "chocolates")
	
	self:RegisterChatCommand("cb", "ChatCommand")
    self:RegisterChatCommand("chocolatebar", "ChatCommand")
	
	self.db:RegisterDefaults({
		profile = {
			combathidetip = false,
			combathidebar = false,
			combatdisbar = false,
			hideonleave = false,
			scale = 1,
			moveFrames = true,
			strata = "HIGH",
			gap = 7,
			moreBar = "none",
			moreBarDelay = 4,
			background = {
				texture = "Tooltip",
				borderTexture = "Tooltip-Border",
				color = {r = 0, g = 0, b = 0, a = .5,},
				borderColor = {r = 0, g = 0, b = 0, a = 0,},
				tile = false,
				tileSize = 32,
				edgeSize = 8,
				barInset = 3,
			},
			barSettings = {
				['*'] = {
					barName = "ChocolateBar1",
					align = "top",
					autohide = false,
					enabled = true,
					showText = true,
					showIcon = true,
					index = 10,
				},
				['ChocolateBar1'] = {
					barName = "ChocolateBar1",
					align = "top",
					autohide = false,
					enabled = true,
					showText = true,
					showIcon = true,
					index = 1,
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
	LSM:Register("statusbar", "Chocolate","Interface\\AddOns\\ChocolateBar\\pics\\ChocolateBar")
	LSM:Register("statusbar", "Titan","Interface\\AddOns\\ChocolateBar\\pics\\Titan")
	
	createDropPoint("ChocolateTextDrop", dropText, -150,"Toggle Text","Interface/ICONS/Achievement_BG_winbyten")
	createDropPoint("ChocolateCenterDrop", dropCenter,0,"Align Center","Interface/Icons/Spell_Holy_GreaterBlessingofSalvation") 
	createDropPoint("ChocolateDisableDrop", dropDisable, 150,"Eat Chocolate", "Interface/ICONS/Achievement_Halloween_Smiley_01")
end

function ChocolateBar:ChatCommand(input)
	
	if not input or input:trim() == "" then
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
			barSettings = {
				inline = true,
				name=name,
				type="group",
				order = 1,
				args={
					moveup = {
						type = 'execute',
						order = 3,
						name = "Move Up",
						desc = "Move Up",
						func = MoveUp,
						disabled = isMoveUp,
					},
					movedown = {
						type = 'execute',
						order = 4,
						name = "Move Down",
						desc = "Move Down",
						func = MoveDown,
						disabled = isMoveDown,
					},
					autohide = {
						type = 'toggle',
						order = 5,
						name = "Autohide",
						desc = "Autohide",
						get = getAutoHide,
						set = setAutoHide,
					},
					eatBar = {
						type = 'execute',
						order = 6,
						name = "Remove Bar",
						desc = "Eat a whole chocolate bar, oh my..",
						func = EatBar,
						disabled = isRemoveBar,
						confirm = true,
					},
				},
			},
		},
	}
end

function ChocolateBar:RemoveBarOptions(name)
	barOptions[name] = nil
end

function ChocolateBar:AddObjectOptions(name,icon, t)
	
	--local curse = GetAddOnMetadata(name,"X-Curse-Packaged-Version") or ""
	--local version = GetAddOnMetadata(name,"Version") or ""
	
	t = t or "not set"
	local cleanName = string.gsub(name, "\|c........", "")
	cleanName = string.gsub(cleanName, "\|r", "")
	cleanName = string.gsub(cleanName, "[%c \127]", "")

	--use cleanName of name becaus aceconfig does not linke some characters in the plugin names
	chocolateOptions[cleanName] = {
		name = GetName,
		desc = name,
		icon = GetIconImage,
		--iconCoords = GetIconCoords,
		type = "group",
		args={
			--[[
			header = {
				order = 1,
				type = "header",
				--name = "|T"..icon..":25|t "..name,
				name = GetHeaderName,
			},
			--]]
			chocoSettings = {
				inline = true,
				name=GetHeaderName,
				type="group",
				order = 1,
				args={
					label = {
						order = 2,
						type = "description",
						name = "Type: "..t.."\n",
						--image = GetHeaderImage,
					},
					enabled = {
						type = 'toggle',
						--width "half",
						order = 3,
						name = "Enabled",
						desc = "Enabled",
						get = GetEnabled,
						set = SetEnabled,
					},
					text = {
						type = 'toggle',
						--width = "half",
						order = 4,
						name = "Show Text",
						desc = "Show Text",
						get = GetText,
						set = SetText,
					},
					icon = {
						type = 'toggle',
						--width = "half",
						order = 5,
						name = "Show Icon",
						desc = "Show Icon",
						get = GetIcon,
						set = SetIcon,
					},
				},
			},
		},
	}
end
