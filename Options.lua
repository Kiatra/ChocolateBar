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
						--todo multiple bars
						return ChocolateBar1:GetScale()
					end,
					set = function(info, value)
						--todo multiple bars
						ChocolateBar1:SetScale(value)
						ChocolateBar1.self = value
						db.scale = value
					end,
				},	
				hideonleave = {
					type = 'toggle',
					order = 2,
					name = "Autohide",
					desc = "Autohide",
					get = function(info, value)
							return db.hideonleave
					end,
					set = function(info, value)
							db.hideonleave = value
					end,
				},
				locked = {
					type = 'toggle',
					order = 2,
					name = "Lock Chocolates",
					desc = "Disable drag and drop",
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
								ChocolateBar:UpdateBarOptions()
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
								ChocolateBar:UpdateBarOptions()
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
								ChocolateBar:UpdateBarOptions()
							end,
						},
					},
				},
				debug = {
					type = 'toggle',
					--width = "half",
					order = -1,
					name = "Debug",
					desc = "Debug",
					get = function(info, value)
							return ChocolateBar.db.char.debug
					end,
					set = function(info, value)
							ChocolateBar.db.char.debug = value
					end,
				},
			},
		},
		chocolates={
			name="Chocolates",
			type="group",
			order = -1,
			--childGroups = "select", 
			cmdHidden = true,
			--validate = function(info, value) end,
			--guiHidden = true,
			args={
			},
		},
	},
}
local chocolateOptions = aceoptions.args.chocolates.args

local function GetName(info)
	local cleanName = info[#info]
	local name = chocolateOptions[cleanName].desc
	local icon = chocolateOptions[cleanName].icon
	if(not db.objSettings[name].enabled)then
		cleanName = "|TZZ"..cleanName.."|t|T"..icon..":18|t |cFFFF0000"..cleanName.."|r"
	else
		cleanName = "|H"..cleanName.."|h|T"..icon..":18|t "..cleanName
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
		frame:SetBackdropBorderColor(1,1,1,1) 
end

local function dropDisable(frame, choco)
		choco:Hide()
		ChocolateBar:DisableDataObject(choco.name)
		frame:SetBackdropBorderColor(1,1,1,1) 
end

local function createDropPoint(name, dropfunc, offx, text, texture)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:SetWidth(100)
	frame:SetHeight(100)
	frame:SetPoint("CENTER",offx,220)
	frame:SetBackdrop({bgFile = texture, 
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = false, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }});	
	frame.text = frame:CreateFontString(nil, nil, "GameFontHighlight")
	--frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)
	frame.text:SetPoint("CENTER",0, 30)
	frame.text:SetText(text)
	
	frame:Hide()
	frame.Drop = dropfunc
		
	frame.Drag = function(frame) frame:SetBackdropBorderColor(1,0,0,1) end
	frame.LoseFocus = function(frame) frame:SetBackdropBorderColor(1,1,1,1) end
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
					barName = "",
					enabled = true,
					height = 20,
					xoff = -1,
					yoff = 1,
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
	
	createDropPoint("ChocolateTextDrop", dropText, -100,"Toggle Text","Interface/ICONS/Achievement_BG_winbyten")
	createDropPoint("ChocolateDisableDrop", dropDisable, 100,"Eat Chocolate", "Interface/ICONS/Achievement_Halloween_Smiley_01")
end

function ChocolateBar:ChatCommand(input)
	if not input or input:trim() == "" then
        LibStub("AceConfigDialog-3.0"):Open("ChocolateBar")
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(ChocolateBar, "cb", "ChocolateBar", input)
    end
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
				name = "|T"..icon..":25|t "..name,
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
