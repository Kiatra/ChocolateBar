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
			order = 1,
			--guiHidden = true,
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
				locked = {
					type = 'toggle',
					order = 2,
					name = "Lock Chocolates",
					desc = "Hold alt key to drag a chocolate.",
					get = function(info, value)
							return db.locked
					end,
					set = function(info, value)
							db.locked = value
					end,
				},
				backbround = {
					inline = true,
					name="Dark Chocolate?",
					type="group",
					order = 5,
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
				moveFrames = {
					type = 'toggle',
					--width = "half",
					order = -1,
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
				debug = {
					type = 'toggle',
					--width = "half",
					order = -1,
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
				enableAll = {
					type = 'execute',
		            --width = "half",
					order = 2,
					name = "Enable All",
		            desc = "Get back my chocolate!",
		            func = "NewBar",
				},
				disableAll = {
					type = 'execute',
		            --width = "half",
					order = 3,
					name = "Disable All",
		            desc = "Eat all the chocolate at once, uff...",
		            func = "NewBar",
				},
				disableLauncher = {
					type = 'execute',
		            --width = "half",
					order = 4,
					name = "Disable all Launchers",
		            desc = "Eat all the bad guy's:)",
		            func = "NewBar",
				},
				--]]
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
	local name = info[#info-1]
	if value then
		db.barSettings[name].align = value
		bar = ChocolateBar:GetBar(name)
		if bar then
			bar:UpdateAutoHide()
			ChocolateBar:AnchorBars()
		end
	end
end

local function GetBarAlign(info, value)
	local name = info[#info-1]
	--Debug("GetBarAlign",name, value)
	return db.barSettings[name].align
end

local function EatBar(info, value)
	local name = info[#info-1]
	ChocolateBar:RemoveBar(name)
end

local function MoveUp(info, value)
	local name = info[#info-1]
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
	local name = info[#info-1]
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
	local name = info[#info-1]
	bar = ChocolateBar:GetBar(name)
	if db.barSettings[name].align == "bottom" then
		if bar.settings.index < 1.5 then
			return true
		end
	end
	return false
end

local function isMoveUp(info)
	local name = info[#info-1]
	bar = ChocolateBar:GetBar(name)
	if db.barSettings[name].align == "top" then
		if bar.settings.index < 1.5 then
			return true
		end
	end
	return false
end
	
local function getAutoHide(info, value)
	local name = info[#info-1]
	return db.barSettings[name].autohide
end

local function setAutoHide(info, value)
	local name = info[#info-1]
	db.barSettings[name].autohide = value
	bar = ChocolateBar:GetBar(name)
	bar:UpdateAutoHide()
	--ChocolateBar:UpdateBarOptions("UpdateAutoHide")
end

--return true if RemoveBar is disabled
function isRemoveBar(info)
	local name = info[#info-1]
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
		cleanName = "|TZZ"..cleanName.."|t|T"..icon..":18|t |cFFFF0000"..cleanName.."|r"
	--elseif ChocolateBar:GetChocolate(name).obj.type == "data source" then
	else
		cleanName = "|H"..cleanName.."|h|T"..icon..":18|t "..cleanName
	--else
	--	cleanName = "|H"..cleanName.."|h|T"..icon..":18|t |c00777777"..cleanName.."|r"
	end
	return cleanName
end

local function SetEnabled(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	if value then
		ChocolateBar:EnableDataObject(name)
	else
		ChocolateBar:DisableDataObject(name)
	end
end

local function GetEnabled(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].enabled
end

local function GetIcon(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].showIcon
end

local function SetIcon(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	db.objSettings[name].showIcon = value
	ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end


local function GetText(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	return db.objSettings[name].showText
end

local function SetText(info, value)
	local cleanName = info[#info-1]
	local name = chocolateOptions[cleanName].desc
	db.objSettings[name].showText = value
	ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

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

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChocolateBar", aceoptions)
	aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChocolateBar", "ChocolateBar")
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("ChocolateBar", 500, 400)
	
	self:RegisterChatCommand("cb", "ChatCommand")
    self:RegisterChatCommand("chocolatebar", "ChatCommand")
	
	self.db:RegisterDefaults({
		profile = {
			hideonleave = false,
			scale = 1,
			moveFrames = true,
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
					space = 7,
					index = 10,
				},
				['ChocolateBar1'] = {
					barName = "ChocolateBar1",
					align = "top",
					autohide = false,
					enabled = true,
					showText = true,
					showIcon = true,
					space = 7,
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
					space = 7,
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
        LibStub("AceConfigDialog-3.0"):Open("ChocolateBar")
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
			header = {
				order = 1,
				type = "header",
				name = name,
			},
			--[[
			align = {
				type = 'select',
				values = {top = "top",bottom = "bottom"},
				order = 2,
				name = "Alignment",
				desc = "Stick to...",
				get = GetBarAlign,
				set = SetBarAlign,
			},
			--]]
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
	}
end

function ChocolateBar:RemoveBarOptions(name)
	barOptions[name] = nil
end

function ChocolateBar:AddObjectOptions(name, icon)
	if not icon or icon == "Interface\\AddOns\\" then
		icon = "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece"
	end
	local cleanName = string.gsub(name, "\|c........", "")
	cleanName = string.gsub(cleanName, "\|r", "")
	cleanName = string.gsub(cleanName, "[%c \127]", "")

	--use cleanName of name becaus aceconfig does not linke some characters in the plugin names
	chocolateOptions[cleanName] = {
		name = GetName,
		desc = name,
		icon = icon,
		type = "group",
		args={
			header = {
				order = 1,
				type = "header",
				--name = "|T"..icon..":25|t "..name,
				name = "|T"..icon..":0|t "..name,
			},
			--[[
			label = {
				order = 0,
				type = "description",
				name = "",
				image = icon,
			},
			--]]
			enabled = {
				type = 'toggle',
				--width "half",
				order = 2,
				name = "Enabled",
				desc = "Enabled",
				get = GetEnabled,
				set = SetEnabled,
			},
			text = {
				type = 'toggle',
				--width = "half",
				order = 3,
				name = "Show Text",
				desc = "Show Text",
				get = GetText,
				set = SetText,
			},
			icon = {
				type = 'toggle',
				--width = "half",
				order = 4,
				name = "Show Icon",
				desc = "Show Icon",
				get = GetIcon,
				set = SetIcon,
			},
		},
	}
end
