local LibStub = LibStub
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local debug = ChocolateBar and ChocolateBar.Debug or function() end
local AceCfgDlg = LibStub("AceConfigDialog-3.0")
local Drag = ChocolateBar.Drag
local broker = LibStub("LibDataBroker-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")
local LSM = LibStub("LibSharedMedia-3.0")
local _G, pairs, string = _G, pairs, string
local db, moreChocolate
local addonName = ... or "LALALA"
---@diagnostic disable-next-line: undefined-field
local GetAddOnMetadata = _G.GetAddOnMetadata or _G.C_AddOns.GetAddOnMetadata;
local version = GetAddOnMetadata(addonName, "Version") or "unknown";

local function GetStats()
    local total = 0
    local enabled = 0
    local data = 0
    for name, obj in broker:DataObjectIterator() do
        local t = obj.type
        if t == "data source" or t == "launcher" then
            total = total + 1
            if t == "data source" then
                data = data + 1
            end
            local settings = db.objSettings[name]
            if settings and settings.enabled then
                enabled = enabled + 1
            end
        end
    end


    return strjoin("\n", "|cffffd200" .. L["Enabled"] .. "|r  " .. enabled,
        "|cffffd200" .. L["Disabled"] .. "|r  " .. total - enabled,
        "|cffffd200" .. L["Total"] .. "|r  " .. total,
        "",
        "|cffffd200" .. L["Data Source"] .. "|r  " .. data,
        "|cffffd200" .. L["Launcher"] .. "|r  " .. total - data
    )
end

local function EnableAll()
    for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
        ChocolateBar:EnableDataObject(name, obj)
    end
end

local function DisableAll()
    for name, _ in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
        ChocolateBar:DisableDataObject(name)
    end
end

local function DisableLauncher()
    for name, obj in LibStub("LibDataBroker-1.1"):DataObjectIterator() do
        if obj.type ~= "data source" then
            ChocolateBar:DisableDataObject(name)
        end
    end
end

local function createPlaceholder()
    local placeholderNames = db.placeholderNames
    local name = L["Placeholder"] .. tablelength(placeholderNames)
    placeholderNames[name] = true
    ChocolateBar:Debug("createPlaceholder", name, tablelength(placeholderNames))
    ChocolateBar:AddObjectOptions(name, ChocolateBar:NewPlaceholder(name))
end

StaticPopupDialogs["ArcanaURLDialog"] = {
    text = L["CTRL-C to copy"],
    button1 = CLOSE,
    OnShow = function(dialog, data)
        local function HidePopup()
            dialog:Hide();
        end
        local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox;
        editBox:SetScript('OnEscapePressed', HidePopup);
        editBox:SetScript('OnEnterPressed', HidePopup);
        editBox:SetScript('OnKeyUp', function(_, key)
            if IsControlKeyDown() and (key == 'C' or key == 'X') then
                HidePopup();
            end
        end);
        editBox:SetMaxLetters(0);
        editBox:SetText(data);
        editBox:HighlightText();
    end,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function showURLPopup(url)
    ---@diagnostic disable-next-line: discard-returns
    StaticPopup_Show("ArcanaURLDialog", _, _, url);
end
---@diagnostic disable-next-line: undefined-global
local increment = CreateCounter();
local opacityTimer = nil

local aceoptions = {
    name = "Arcana - Quel'dorei Observatory",
    handler = ChocolateBar,
    type = 'group',
    --childGroups = "tab",
    desc = "Arcana - Quel'dorei Observatory",
    args = {
        text1 = {
            order = 1,
            type = "description",
            name = version,
        },
        news = {
            name = L["Whats New & Info"],
            type = "group",
            order = 0,
            args = {
                info = {
                    order = increment(),
                    type = "header",
                    name = L["Info"],
                },
                infoText = {
                    order = increment(),
                    type = "description",
                    name = L
                        ["The Quel'dorei became scattered across the world. To preserve the fragments of arcana they gathered from many sources, they maintain observatories where this knowledge is kept in careful order."]
                },
                infoTextPlugins = {
                    order = increment(),
                    type = "description",
                    name = L
                        ["You can add plugins to Arcana via the data-broker category in the curseforge app or the link below."],
                },
                plugins = {
                    order = increment(),
                    type = "execute",
                    name = L["Search for plugins here"],
                    func = function()
                        showURLPopup(
                            "https://www.curseforge.com/wow/search?sortBy=popularity&class=addons&categories=data-broker&search=plugin");
                    end,
                    width = 1.5,
                },
                header26March7 = {
                    order = increment(),
                    type = "header",
                    name = L["2026 March 7"],
                },
                text26March7 = {
                    order = increment(),
                    type = "description",
                    name =
                        L["Added option to set the opacity of the bars."],
                },
                header26March7_2 = {
                    order = increment(),
                    type = "header",
                    name = L["2026 March 7"],
                },
                text26March7_2 = {
                    order = increment(),
                    type = "description",
                    name =
                        L
                        ["Added module to automatically migrate ChocolateBar profiles to Arcana."],
                },
                header26March6 = {
                    order = increment(),
                    type = "header",
                    name = L["2026 March 6"],
                },
                text26March6 = {
                    order = increment(),
                    type = "description",
                    name =
                        L["2026 March 6 - News"],
                },
                header26March5 = {
                    order = increment(),
                    type = "header",
                    name = L["2026 March 5"],
                },
                text26March5 = {
                    order = increment(),
                    type = "description",
                    name = L
                        ["TBC Anniversary:\nThe upper row action bars will now also be moved up. Reset them in edit mode and reload the UI."]
                },
            }
        },
        lookAndFeel = {
            name = L["Look and Feel"],
            type = "group",
            order = 1,
            args = {
                general = {
                    inline = true,
                    name = L["General"],
                    type = "group",
                    order = 3,
                    args = {
                        locked = {
                            type = 'toggle',
                            order = 1,
                            name = L["Lock Plugins"],
                            desc = L["Hold alt key to drag a plugin."],
                            get = function()
                                return db.locked
                            end,
                            set = function(_, value)
                                db.locked = value
                            end,
                        },
                        allBarsOpacity = {
                            type = 'range',
                            order = 2,
                            name = L["Opacity"],
                            desc = L["Set the opacity of the all the bars."],
                            min = 0,
                            max = 1,
                            step = 0.001,
                            bigStep = 0.05,
                            isPercent = true,
                            get = function()
                                return db.allBarsOpacity
                            end,
                            set = function(_, value)
                                if value > 1 then
                                    value = 1
                                elseif value < 0.01 then
                                    value = 0.001
                                end
                                db.allBarsOpacity = value
                                for _, bar in pairs(ChocolateBar:GetBars()) do
                                    bar.tempHide = bar:GetAlpha()
                                    bar:SetAlpha(db.allBarsOpacity)
                                end
                            end,
                        },
                        adjustBlizzardFrames = {
                            type = 'toggle',
                            order = 2,
                            name = L["Move Minimap, Bags and other Frames"],
                            desc = L
                                ["Moves Minimap, Bags and other frames above/below visible Bars. \n\nDisable this if you have issues and use WoW's \"Edit Mode\" instead to place the frames away from the Bars."],
                            get = function()
                                return db.moveFrames
                            end,
                            set = function(_, value)
                                db.moveFrames = value
                                ChocolateBar:UpdateBarOptions("UpdateAutoHide")
                            end,
                        },
                        hideBarsPetBattle = {
                            type = 'toggle',
                            order = 3,
                            name = L["Hide Bars in Pet Battle"],
                            desc = L["Hide Bars during a Pet Battle."],
                            get = function()
                                return db.petBattleHideBars
                            end,
                            set = function(_, value)
                                db.petBattleHideBars = value
                            end,
                        },
                        hideOrderHallCommandBar = {
                            type = 'toggle',
                            order = 4,
                            name = L["Hide Order Hall Bar"],
                            desc = L["Hides the command bar displayed at the Class/Order Hall."],
                            get = function()
                                return db.hideOrderHallCommandBar
                            end,
                            set = function(_, value)
                                db.hideOrderHallCommandBar = value
                                ChocolateBar:ToggleOrderHallCommandBar()
                            end,
                        },
                        --[[
							adjustCenter = {
								type = 'toggle',
								order = 5,
								width = "double",
								name = L["Update Center Position"],
								desc = L["Always adjust the center group based on the current width of the plugins. Disable this to align the center group based only on the number of plugins."],
								get = function(info, value)
										return db.adjustCenter
								end,
								set = function(info, value)
										db.adjustCenter = value
										ChocolateBar:UpdateBarOptions("UpdateBar")
								end,
							},]] --
                        gap = {
                            type = 'range',
                            order = 10,
                            name = L["Gap"],
                            desc = L["Set the gap between the plugins."],
                            min = 0,
                            max = 50,
                            step = 1,
                            get = function()
                                return db.gap
                            end,
                            set = function(_, value)
                                db.gap = value
                                ChocolateBar.ChocolatePiece:UpdateGap(value)
                                ChocolateBar:UpdateChoclates("updateSettings")
                            end,
                        },
                        textOffset = {
                            type = 'range',
                            order = 11,
                            name = L["Text Offset"],
                            desc = L["Set the distance between the icon and the text."],
                            min = -5,
                            max = 15,
                            step = 1,
                            get = function()
                                return db.textOffset
                            end,
                            set = function(_, value)
                                db.textOffset = value
                                ChocolateBar:UpdateChoclates("updateSettings")
                            end,
                        },
                        size = {
                            type = 'range',
                            order = 12,
                            name = L["Bar Size"],
                            desc = L["Bar Size"],
                            min = 12,
                            max = 30,
                            step = 1,
                            get = function()
                                return db.height
                            end,
                            set = function(_, value)
                                db.height = value
                                ChocolateBar:UpdateBarOptions("UpdateHeight")
                            end,
                        },
                        iconSize = {
                            type = 'range',
                            order = 13,
                            name = L["Icon Size"],
                            desc = L["Icon size in relation to the bar height."],
                            min = 0,
                            max = 1,
                            step = 0.001,
                            bigStep = 0.05,
                            isPercent = true,
                            get = function()
                                return db.iconSize
                            end,
                            set = function(_, value)
                                if value > 1 then
                                    value = 1
                                elseif value < 0.01 then
                                    value = 0.001
                                end
                                db.iconSize = value
                                ChocolateBar:UpdateBarOptions("UpdateHeight")
                            end,
                        },
                        strata = {
                            type = 'select',
                            values = {
                                FULLSCREEN_DIALOG = "Fullscreen_Dialog",
                                FULLSCREEN = "Fullscreen",
                                DIALOG = "Dialog",
                                HIGH = "High",
                                MEDIUM = "Medium",
                                LOW = "Low",
                                BACKGROUND = "Background"
                            },
                            order = 14,
                            name = L["Bar Strata"],
                            desc = L["Bar Strata"],
                            get = function()
                                return db.strata
                            end,
                            set = function(_, value)
                                db.strata = value
                                ChocolateBar:UpdateBarOptions("UpdateStrata")
                            end,
                        },
                        barRightClick = {
                            type = 'select',
                            values = {
                                NONE = L["none"],
                                OPTIONS = L["Arcana Options"],
                                BLIZZ = L["Blizzard Options"]
                            },
                            order = 16,
                            name = L["Bar Right Click"],
                            desc = L["Select the action when right clicking on a bar."],
                            get = function()
                                return db.barRightClick
                            end,
                            set = function(_, value)
                                db.barRightClick = value
                            end,
                        },
                        --colorizedDragging = {
                        --	type = 'toggle',
                        --	order = 12,
                        --	name = L["Colorized Dragging"],
                        --	desc = L["Colorize frames during drag & drop."],
                        --	get = function(info, value)
                        --			return db.colorizedDragging
                        --	end,
                        --	set = function(info, value)
                        --	-		db.colorizedDragging = value
                        --	end,
                        --},
                    },
                },
                defaults = {
                    inline = true,
                    name = L["Defaults"],
                    type = "group",
                    order = 4,
                    args = {
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
                            set = function(_, value)
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
                            set = function(_, value)
                                db.autodislauncher = value
                            end,
                        },
                    },
                },
                combat = {
                    --inline = true,
                    name = L["In Combat"],
                    type = "group",
                    order = 0,
                    args = {
                        combat = {
                            inline = true,
                            name = L["In Combat"],
                            type = "group",
                            order = 0,
                            args = {
                                hidetooltip = {
                                    type = 'toggle',
                                    order = 1,
                                    name = L["Disable Tooltips"],
                                    desc = L["Disable Tooltips"],
                                    get = function()
                                        return db.combathidetip
                                    end,
                                    set = function(_, value)
                                        db.combathidetip = value
                                    end,
                                },
                                hidebars = {
                                    type = 'toggle',
                                    order = 2,
                                    name = L["Hide Bars"],
                                    desc = L["Hide Bars"],
                                    get = function()
                                        return db.combathidebar
                                    end,
                                    set = function(_, value)
                                        db.combathidebar = value
                                    end,
                                },
                                disablebar = {
                                    type = 'toggle',
                                    order = 2,
                                    name = L["Disable Clicking"],
                                    desc = L["Disable Clicking"],
                                    get = function()
                                        return db.combatdisbar
                                    end,
                                    set = function(_, value)
                                        db.combatdisbar = value
                                    end,
                                },
                                disableoptons = {
                                    type = 'toggle',
                                    order = 2,
                                    name = L["Disable Options"],
                                    desc = L["Disable options dialog on right click"],
                                    get = function()
                                        return db.disableoptons
                                    end,
                                    set = function(_, value)
                                        db.disableoptons = value
                                    end,
                                },
                                combatopacity = {
                                    type = 'range',
                                    order = 3,
                                    name = L["Opacity"],
                                    desc = L["Set the opacity of the bars during combat. Set to 100% to disable."],
                                    min = 0,
                                    max = 1,
                                    step = 0.001,
                                    bigStep = 0.05,
                                    isPercent = true,
                                    get = function()
                                        return db.combatopacity
                                    end,
                                    set = function(_, value)
                                        if value > 1 then
                                            value = 1
                                        elseif value < 0.01 then
                                            value = 0.001
                                        end
                                        db.combatopacity = value
                                        for _, bar in pairs(ChocolateBar:GetBars()) do
                                            bar.tempHide = bar:GetAlpha()
                                            bar:SetAlpha(db.combatopacity)
                                        end
                                        ChocolateBar:CancelTimer(opacityTimer)
                                        opacityTimer = ChocolateBar:ScheduleTimer(function(plugin)
                                            for _, bar in pairs(ChocolateBar:GetBars()) do
                                                bar:SetAlpha(db.allBarsOpacity)
                                            end
                                        end, 2)
                                    end,
                                },
                            },
                        },
                    },
                },
                fontAndTextures = {
                    name = L["Fonts and Textures"],
                    type = "group",
                    order = 4,
                    args = {
                        textures = {
                            inline = true,
                            name = L["Textures"],
                            type = "group",
                            order = 2,
                            args = {
                                colour = {
                                    type = "color",
                                    order = 5,
                                    name = L["Texture Color/Alpha"],
                                    desc = L["Texture Color/Alpha"],
                                    hasAlpha = true,
                                    get = function(_)
                                        local t = db.background.color
                                        return t.r, t.g, t.b, t.a
                                    end,
                                    set = function(_, r, g, b, a)
                                        local t = db.background.color
                                        t.r, t.g, t.b, t.a = r, g, b, a
                                        ChocolateBar:UpdateBarOptions("UpdateColors")
                                    end,
                                },
                                bordercolour = {
                                    type = "color",
                                    order = 6,
                                    name = L["Border Color/Alpha"],
                                    desc = L["Border Color/Alpha"],
                                    hasAlpha = true,
                                    get = function()
                                        local t = db.background.borderColor
                                        return t.r, t.g, t.b, t.a
                                    end,
                                    set = function(_, r, g, b, a)
                                        local t = db.background.borderColor
                                        t.r, t.g, t.b, t.a = r, g, b, a
                                        ChocolateBar:UpdateBarOptions("UpdateColors")
                                    end,
                                },
                                textureTile = {
                                    type = 'toggle',
                                    order = 3,
                                    name = L["Tile"],
                                    desc = L["Tile the Texture. Disable to stretch the Texture."],
                                    get = function()
                                        return db.background.tile
                                    end,
                                    set = function(_, value)
                                        db.background.tile = value
                                        ChocolateBar:UpdateBarOptions("UpdateTexture")
                                    end,
                                },
                                textureTileSize = {
                                    type = 'range',
                                    order = 4,
                                    name = L["Tile Size"],
                                    desc = L["Adjust the size of the tiles."],
                                    min = 1,
                                    max = 256,
                                    step = 1,
                                    bigStep = 5,
                                    isPercent = false,
                                    get = function()
                                        return db.background.tileSize
                                    end,
                                    set = function(_, value)
                                        if value > 256 then
                                            value = 256
                                        elseif value < 1 then
                                            value = 1
                                        end
                                        db.background.tileSize = value
                                        ChocolateBar:UpdateBarOptions("UpdateTexture")
                                    end,
                                },
                            },
                        },
                        font = {
                            inline = true,
                            name = L["Font"],
                            type = "group",
                            order = 1,
                            args = {
                                fontSize = {
                                    type = 'range',
                                    order = 2,
                                    name = L["Font Size"],
                                    desc = L["Font Size"],
                                    min = 8,
                                    max = 20,
                                    step = .5,
                                    get = function()
                                        return db.fontSize
                                    end,
                                    set = function(_, value)
                                        db.fontSize = value
                                        ChocolateBar:UpdateChoclates("updatefont")
                                    end,
                                },
                                textcolour = {
                                    type = "color",
                                    order = 3,
                                    name = L["Text color"],
                                    desc = L
                                        ["Default text color of a plugin. This will not overwrite plugins that use own colors."],
                                    hasAlpha = true,
                                    get = function()
                                        local t = db.textColor or { r = 1, g = 1, b = 1, a = 1 }
                                        return t.r, t.g, t.b, t.a
                                    end,
                                    set = function(_, r, g, b, a)
                                        db.textColor = db.textColor or { r = 1, g = 1, b = 1, a = 1 }
                                        local t = db.textColor
                                        t.r, t.g, t.b, t.a = r, g, b, a
                                        ChocolateBar:UpdateChoclates("updateSettings")
                                    end,
                                },
                                labelColor = {
                                    type = "color",
                                    order = 3,
                                    name = L["Label color"],
                                    desc = L["Default label color of a plugin."],
                                    hasAlpha = true,
                                    get = function()
                                        local t = db.labelColor or { r = 1, g = 0.82, b = 0, a = 1 }
                                        return t.r, t.g, t.b, t.a
                                    end,
                                    set = function(_, r, g, b, a)
                                        db.labelColor = db.labelColor or { r = 1, g = 0.82, b = 0, a = 1 }
                                        local t = db.labelColor
                                        t.r, t.g, t.b, t.a = r, g, b, a
                                        ChocolateBar:UpdateChoclates("updateSettings")
                                    end,
                                },
                                iconcolour = {
                                    type = "toggle",
                                    order = 4,
                                    name = L["Desaturated Icons"],
                                    desc = L
                                        ["Show icons in gray scale mode (This will not affect icons embedded in the text of a plugin)."],
                                    get = function()
                                        return db.desaturated
                                    end,
                                    set = function(_, vale)
                                        db.desaturated = vale
                                        for name, _ in broker:DataObjectIterator() do
                                            if db.objSettings[name] then
                                                if db.objSettings[name].enabled then
                                                    local choco = ChocolateBar:GetChocolate(name)
                                                    if choco then
                                                        choco:Update(choco, "iconR", nil)
                                                    end
                                                end
                                            end
                                        end
                                    end,
                                },
                                forceColor = {
                                    type = 'toggle',
                                    width = "double",
                                    order = 9,
                                    name = L["Force Text Color"],
                                    desc = L["Remove custom colors from plugins."],
                                    get = function()
                                        return db.forceColor
                                    end,
                                    set = function(_, value)
                                        db.forceColor = value
                                        for name, obj in broker:DataObjectIterator() do
                                            if db.objSettings[name] then
                                                if db.objSettings[name].enabled then
                                                    local choco = ChocolateBar:GetChocolate(name)
                                                    if choco then
                                                        choco:Update(choco, "text", obj.text)
                                                    end
                                                end
                                            end
                                        end
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
                    order = 30,
                    name = "Debug",
                    desc = "This one is for me, not for you :P",
                    get = function()
                        return ChocolateBar.db.char.debug
                    end,
                    set = function(_, value)
                        ChocolateBar.db.char.debug = value
                    end,
                },
                --@end-debug@
            },
        },
        bars = {
            name = L["Bars"],
            type = "group",
            order = 2,
            args = {
                new = {
                    type = 'execute',
                    --width = "half",
                    order = 0,
                    name = L["Create Bar"],
                    desc = L["Create New Bar"],
                    func = function()
                        local name = ChocolateBar:AddBar()
                        ChocolateBar:AddBarOptions(name)
                    end,
                },
                newPlaceholder = {
                    type = 'execute',
                    order = 0,
                    name = L["Create Placeholder"],
                    desc = L["Create New Placeholder"],
                    func = createPlaceholder,
                },
            },
        },
        moduleOptions = {
            name = L["Modules"],
            type = "group",
            order = 20,
            args = {
                label = {
                    type = 'description',
                    order = 1,
                    name = L
                        ["Modules are buildin plugins that can be enabled or disabled here. Disabled plugins will not be loaded."]
                },
            },
        },
        chocolates = {
            name = L["Plugins"],
            type = "group",
            order = -1,
            args = {
                stats = {
                    inline = true,
                    name = L["Plugin Statistics"],
                    type = "group",
                    order = 1,
                    args = {
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
                    args = {
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
                            desc = L["Disable all plugins."],
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

aceoptions.args.lookAndFeel.args.fontAndTextures.args.textures.args.textureStatusbar = {
    type = 'select',
    dialogControl = 'LSM30_Statusbar',
    values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.statusbar or {},
    order = 1,
    name = L["Background Texture"],
    desc = L["Some of the textures may depend on other addons."],
    get = function()
        return db.background.textureName
    end,
    set = function(_, value)
        db.background.texture = LSM:Fetch("statusbar", value)
        db.background.textureName = value
        db.background.tile = false
        ChocolateBar:UpdateBarOptions("UpdateTexture")
    end,
}

aceoptions.args.lookAndFeel.args.fontAndTextures.args.textures.args.background1 = {
    inline = true,
    name = L["Advanced Textures"],
    type = "group",
    order = 3,
    args = {
        textureBackground = {
            type = 'select',
            dialogControl = 'LSM30_Background',
            values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.background or {},
            order = 2,
            name = L["Background Texture"],
            desc = L["Some of the textures may depend on other addons."],
            get = function()
                return db.background.textureName
            end,
            set = function(_, value)
                db.background.texture = LSM:Fetch("background", value)
                db.background.textureName = value
                db.background.tile = true
                local t = db.background.color
                t.r, t.g, t.b, t.a = 1, 1, 1, 1
                ChocolateBar:UpdateBarOptions("UpdateTexture")
            end,
        }
    }
}

aceoptions.args.lookAndFeel.args.fontAndTextures.args.font.args.font = {
    type = 'select',
    dialogControl = 'LSM30_Font',
    values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {},
    order = 1,
    name = L["Font"],
    desc = L["Some of the fonts may depend on other addons."],
    get = function()
        return db.fontName
    end,
    set = function(_, value)
        db.fontPath = LSM:Fetch("font", value)
        db.fontName = value
        ChocolateBar:UpdateChoclates("updatefont")
    end,
}

local chocolateOptions = aceoptions.args.chocolates.args
local barOptions = aceoptions.args.bars.args
local moduleOptions = aceoptions.args.moduleOptions.args
ChocolateBar.optionsTable = aceoptions
---
-- placeholder options
local function removePlaceholder(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.placeholderNames[cleanName] = nil
    print(db.placeholderNames)
    ChocolateBar:DisableDataObject(name)
    chocolateOptions[cleanName] = nil
end

local placeholderOptions = {
    inline = true,
    name = L["Placeholder Options"],
    type = "group",
    order = 1,
    args = {
        label = {
            order = 1,
            type = "description",
            name = L
                ["Tipp: Set the width behavior to fixed and adjust the the max text width to scale the placeholder."],
        },
        disablePlaceholder = {
            type = 'execute',
            order = 0,
            name = L["Remove Placeholder"],
            desc = L["Remove this Placeholder"],
            func = removePlaceholder,
        },
    },
}

local function addPlaceholderOption(cleanName)
    for k, _ in pairs(db.placeholderNames) do
        if cleanName == k then
            ChocolateBar:Debug("addPlaceholderOption", k)
            table.insert(chocolateOptions[cleanName].args, placeholderOptions)
        end
    end
end
-----
-- bar option functions
-----

function ChocolateBar:GetAceOptions()
    return aceoptions
end

-- return the number of bars aligend to align (top or bottom)
function ChocolateBar:GetNumBars(align)
    local i = 0
    for _, v in pairs(ChocolateBar:GetBars()) do
        if v.settings.align == align then
            i = i + 1
        end
    end
    return i
end

local function GetBarName(info)
    local name = info[#info]
    local bar = ChocolateBar:GetBar(name)
    if bar and bar.settings.align == "top" then
        name = name .. " (top) "
    elseif bar and bar.settings.align == "bottom" then
        name = name .. " (bottom) "
    else
        name = name .. " (custom) "
    end
    return name
end

local function GetBarIndex(info)
    local name = info[#info]
    local bar = ChocolateBar:GetBar(name)
    local index = bar.settings.index
    if db.barSettings[name].align == "bottom" then
        --reverse order and force below top bars
        index = index * -1 + 100
    end
    return index
end

local function SetBarAlign(info, value)
    local name = info[#info - 2]
    if value then
        db.barSettings[name].align = value
        local bar = ChocolateBar:GetBar(name)
        if bar then
            bar:UpdateAutoHide(db)
            ChocolateBar:AnchorBars()
        end
    end
end

local function EatBar(info)
    local name = info[#info - 2]
    ChocolateBar:RemoveBar(name)
end

local function MoveUp(info)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    local index = bar.settings.index
    if bar then
        if db.barSettings[name].align == "bottom" then
            index = index + 1.5
            if index > (ChocolateBar:GetNumBars("bottom") + 1) then
                index = ChocolateBar:GetNumBars("top") + 1
                SetBarAlign(info, "top")
            end
        elseif db.barSettings[name].align == "top" then
            index = index - 1.5
        else
            db.barSettings[name].align = "top"
            index = 0
            SetBarAlign(info, "top")
        end
        bar.settings.index = index
        ChocolateBar:AnchorBars()
    end
end

local function MoveDown(info)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    local index = bar.settings.index
    if bar then
        if db.barSettings[name].align == "bottom" then
            index = index - 1.5
        elseif db.barSettings[name].align == "top" then
            index = index + 1.5
            if index > (ChocolateBar:GetNumBars("top") + 1) then
                index = ChocolateBar:GetNumBars("bottom") + 1
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

local function getAutoHide(info)
    local name = info[#info - 2]
    return db.barSettings[name].autohide
end

local function setAutoHide(info, value)
    local name = info[#info - 2]
    db.barSettings[name].autohide = value
    local bar = ChocolateBar:GetBar(name)
    bar:UpdateAutoHide(db)
end

--hide bar during combat
local function gethideBarInCombat(info)
    local name = info[#info - 2]
    return db.barSettings[name].hideBarInCombat
end

local function sethideBarInCombat(info, value)
    local name = info[#info - 2]
    db.barSettings[name].hideBarInCombat = value
end

local function GetBarWidth(info)
    local name = info[#info - 2]
    return db.barSettings[name].width
end

local function SetBarWidth(info, value)
    local name = info[#info - 2]
    local settings = db.barSettings[name]
    settings.width = value
    local bar = ChocolateBar:GetBar(name)
    if value > _G.GetScreenWidth() or value == 0 then
        bar:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
    else
        settings.barPoint, _, _, settings.barOffx, settings.barOffy = bar:GetPoint()
        if settings.barOffy == 0 then settings.barOffy = 1 end
        bar:ClearAllPoints()
        bar:SetPoint(settings.barPoint, "UIParent", settings.barOffx, settings.barOffy)
        bar:SetWidth(value)
    end
end

local moveBarDummy
local function OnDragStart(self)
    self:StartMoving()
    self.isMoving = true
end

local function OnDragStop(self)
    self:StopMovingOrSizing()
    self.isMoving = false
end

local function SetLockedBar(info, value)
    local name = info[#info - 2]
    local settings = db.barSettings[name]
    local bar = ChocolateBar:GetBar(name)
    bar.locked = not value
    if not value then
        --unlock
        if not moveBarDummy then
            moveBarDummy = _G.CreateFrame("Frame", bar, _G.UIParent, BackdropTemplateMixin and "BackdropTemplate")
            moveBarDummy:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                nil,
                ---@diagnostic disable-next-line: assign-type-mismatch
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                nil
            });
            moveBarDummy:SetBackdropColor(1, 0, 0, 1);
            moveBarDummy:RegisterForDrag("LeftButton")
            moveBarDummy:SetFrameStrata("FULLSCREEN_DIALOG")
            moveBarDummy:SetFrameLevel(10)
            moveBarDummy:SetScript("OnMouseUp", function(_, btn)
                if btn == "RightButton" then
                    ChocolateBar:ChatCommand()
                end
            end)
        end
        moveBarDummy.bar = bar
        moveBarDummy:SetAllPoints(bar)
        moveBarDummy:Show()

        bar:RegisterForDrag("LeftButton")
        bar:EnableMouse(true)
        bar:SetFrameStrata("FULLSCREEN_DIALOG")
        bar:SetFrameLevel(20)
        bar:SetMovable(true)
        bar:SetScript("OnDragStart", OnDragStart)
        bar:SetScript("OnDragStop", OnDragStop)
        bar:SetClampedToScreen(true)
        for _, v in pairs(bar.chocolist) do
            v:Hide()
        end
    else
        bar:SetClampedToScreen(false)
        for _, v in pairs(bar.chocolist) do
            v:Show()
        end
        bar:SetScript("OnDragStart", nil)
        settings.barPoint, _, _, settings.barOffx, settings.barOffy = bar:GetPoint()
        if settings.barOffy == 0 then settings.barOffy = 1 end
        bar:SetPoint(settings.barPoint, "UIParent", settings.barOffx, settings.barOffy)
        settings.align = "custom"
        settings.width = bar:GetWidth()
        bar:SetFrameStrata(db.strata)
        bar:SetFrameLevel(1)
        if moveBarDummy then moveBarDummy:Hide() end
    end
end

local function GetFreeBar(info)
    local name = info[#info - 2]
    return db.barSettings[name].align == "custom"
end

local function SetFreeBar(info, value)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    if not value then
        SetLockedBar(info, true)
        db.barSettings[name].align = "top"
        bar:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
        ChocolateBar:AnchorBars()
    else
        db.barSettings[name].align = "custom"
    end
    bar:UpdateJostle(db)
end

local function GetLockedBar(info)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    return not bar.locked
end

-------------
-- bar options disabled/enabled
--------------------
local function IsDisabledFreeMove(info)
    local name = info[#info - 2]
    return not (db.barSettings[name].align == "custom")
end

--return true if RemoveBar is disabled
local function IsDisabledRemoveBar(info)
    local name = info[#info - 2]
    return name == "Arcana1"
end

local function IsDisabledMoveDown(info)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    local settings = bar.settings
    return settings.align == "custom" or (settings.align == "bottom" and settings.index < 1.5)
end

local function IsDisabledMoveUp(info)
    local name = info[#info - 2]
    local bar = ChocolateBar:GetBar(name)
    local settings = db.barSettings[name]
    return settings.align == "custom" or (settings.align == "top" and bar.settings.index < 1.5)
end

-----
-- chocolate option functions
-----
local function GetName(info)
    local cleanName = info[#info]
    local name = chocolateOptions[cleanName].desc
    --local icon = chocolateOptions[cleanName].icon
    local dataobj = broker:GetDataObjectByName(name)
    if (not db.objSettings[name].enabled) then
        -- disabled
        --cleanName = "|TZZ"..cleanName.."|t|T"..icon..":18|t |cFFFF0000"..cleanName.."|r"
        cleanName = "|H" .. cleanName .. "|h|cFFFF0000" .. cleanName .. "|r"
    elseif dataobj and dataobj.type == "data source" then
        --enabled data scurce
        cleanName = "|H" .. cleanName .. "|h" .. cleanName
    else
        --enabled launcher
        cleanName = "|H" .. cleanName .. "|h|cFFBBBBBB" .. cleanName .. "|r"
    end
    return cleanName
end

local function GetType(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return (broker:GetDataObjectByName(name).type == "data source" and L["Type"] .. ": " .. L["Data Source"] .. "\n") or
        L["Type"] .. ": " .. L["Launcher"] .. "\n"
end

local function GetAlignment(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].align
end

local function SetAlignment(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].align = value
    local choco = ChocolateBar:GetChocolate(name)
    db.objSettings[name].index = 500
    if choco and choco.bar then
        choco.bar:UpdateBar(true)
        --choco.bar:UpdateBar()
    end
end

local function SetEnabled(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    if value then
        local obj = broker:GetDataObjectByName(name)
        ChocolateBar:EnableDataObject(name, obj)
    else
        ChocolateBar:DisableDataObject(name)
    end
end

local function GetEnabled(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].enabled
end

local function GetDisabled(info)
    return not GetEnabled(info)
end

local function GetIcon(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].showIcon
end

local function SetIcon(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].showIcon = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetCustomLabel(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].customLabel
end

local function SetCustomLabel(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].customLabel = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetDisableTooltip(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].disableTooltip
end

local function SetDisableTooltip(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].disableTooltip = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetLabel(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].showLabel
end

local function SetLabel(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].showLabel = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetText(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].showText
end

local function SetText(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].showText = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].textOffset or db.textOffset
end

local function SetTextOffset(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].textOffset = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetWidth(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].width
end

local function SetWidth(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].width = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetWidthBehavior(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    if not db.objSettings[name].widthBehavior and db.objSettings[name].width == 0 then
        return "free"
    else
        return db.objSettings[name].widthBehavior or "fixed"
    end
end

local function SetWidthBehavior(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    db.objSettings[name].widthBehavior = value
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function IsDisabledTextWidth(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return true and (db.objSettings[name].widthBehavior == "free" or not db.objSettings[name].widthBehavior) or false
end

local function GetIconImage(info, name)
    if info then
        local cleanName = info[#info]
        name = chocolateOptions[cleanName].desc
    end
    local obj = broker:GetDataObjectByName(name)
    if obj and obj.icon then
        return obj.icon
    end
    return "Interface\\AddOns\\Arcana\\pics\\ChocolatePiece"
end

local function GetIconCoords(info)
    local cleanName = info[#info]
    local name = chocolateOptions[cleanName].desc
    local obj = broker:GetDataObjectByName(name)
    if obj and obj.iconCoords then
        return obj.iconCoords
    end
end

local function IsDisabledIcon(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    local obj = broker:GetDataObjectByName(name)
    return not (obj and obj.icon) --return true if there is no icon
end

local function IsDisabledSetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return not db.objSettings[name].textOffset
end

local function IsEnabledSetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].textOffset
end

local function SetEnabledSetTextOffset(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    local settings = db.objSettings[name]
    if settings.textOffset then
        settings.textOffset = nil
    else
        settings.textOffset = db.textOffset
    end
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function SetEnabledOverwriteIconSize(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    local settings = db.objSettings[name]
    if settings.iconSize then
        settings.iconSize = nil
    else
        settings.iconSize = db.iconSize
    end
    ChocolateBar:AttributeChanged(nil, name, "updateSettings", value)
end

local function SetCustomIconSize(info, value)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    if value > 1 then
        value = 1
    elseif value < 0.01 then
        value = 0.001
    end
    db.objSettings[name].iconSize = value
    ChocolateBar:UpdateBarOptions("UpdateHeight")
end

local function GetCustomIconSize(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].iconSize or db.iconSize
end

local function IsEnabledOvwerwriteIconSize(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return db.objSettings[name].iconSize
end

local function IsDisabledOvwerwriteIconSize(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    return not db.objSettings[name].iconSize
end


local function GetHeaderName(info)
    local cleanName = info[#info - 1]
    local name = chocolateOptions[cleanName].desc
    return "|T" .. GetIconImage(nil, name) .. ":18|t " .. name
end

local function ShowPluginOnBar(info)
    local cleanName = info[#info - 2]
    local name = chocolateOptions[cleanName].desc
    local choco = ChocolateBar:GetChocolate(name)
    if choco then
        choco.blinkTimerCount = 0

        local pointer = ChocolateBar:GetPointer(choco)
        pointer:ClearAllPoints()
        pointer:SetPoint("CENTER", choco, "CENTER", pointer:GetWidth() / 2, 0)
        pointer:SetAlpha(0)
        pointer:Hide()
        pointer:Show()
        choco.timer = ChocolateBar:ScheduleRepeatingTimer(function(plugin)
            local c = plugin.blinkTimerCount
            c = c + 1
            plugin:highlight(1, 0, 0, c % 2)
            pointer:SetAlpha(c % 2)
            if c >= 10 then
                ChocolateBar:CancelTimer(plugin.timer)
                plugin:highlight(1, 0, 0, 0)
                pointer:SetAlpha(0)
                pointer:Hide()
            end
            plugin.blinkTimerCount = c
        end, 0.1, choco)
    end
end

function ChocolateBar:UpdateOptions(chocolateBars)
    for name, obj in broker:DataObjectIterator() do
        ChocolateBar:AddObjectOptions(name, obj)
    end

    for name, _ in pairs(chocolateBars) do
        ChocolateBar:AddBarOptions(name)
    end
end

function ChocolateBar:RegisterOptions(data, _, modules)
    db = data

    LibStub("AceConfig-3.0"):RegisterOptionsTable("Arcana", aceoptions)
    aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    AceCfgDlg:SetDefaultSize("Arcana", 700, 600)

    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    AceCfgDlg:SelectGroup("Arcana", "chocolates")
    AceCfgDlg:SelectGroup("Arcana", "bars")
    AceCfgDlg:SelectGroup("Arcana", "general")
    AceCfgDlg:SelectGroup("Arcana", "lookAndFeel")
    AceCfgDlg:SelectGroup("Arcana", "news")

    for name, module in pairs(modules) do
        self:AddModuleOptions(name, module.options)
        if module.OnOpenOptions then module:OnOpenOptions() end
    end
end

function ChocolateBar:OpenOptions(_, _, input, pluginName, _, blizzard)
    --local AceCfgDlg = LibStub("AceConfigDialog-3.0")

    if pluginName then
        AceCfgDlg:SelectGroup("Arcana", "chocolates", pluginName)
    end

    if blizzard then
        Settings.OpenToCategory(self.BlizzardOptionsCategoryID)
    elseif not input or input:trim() == "" then
        AceCfgDlg:Open("Arcana")
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(ChocolateBar, "Arcana", "Arcana", input)
    end
end

function ChocolateBar:AddModuleOptions(name, options)
    moduleOptions[name] = options
end

function ChocolateBar:AddBarOptions(name)
    barOptions[name] = {
        name = GetBarName,
        desc = name,
        type = "group",
        order = GetBarIndex,
        args = {
            general = {
                inline = true,
                name = name,
                type = "group",
                order = 0,
                args = {
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
                        desc = L["Removes the selected Bar."],
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
                    hidebar = {
                        type = 'toggle',
                        order = 2,
                        name = L["Hide In Combat"],
                        desc = L["Hide this bar during combat."],
                        get = gethideBarInCombat,
                        set = sethideBarInCombat,
                    },
                },
            },
            move = {
                inline = true,
                name = L["Managed Placement"],
                type = "group",
                order = 2,
                args = {
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
                name = L["Free Placement"],
                type = "group",
                order = -1,
                args = {
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
                },
            },
        },
    }
end

function ChocolateBar:RemoveBarOptions(name)
    barOptions[name] = nil
end

function ChocolateBar:RemovePluginOptions(cleanName)
    chocolateOptions[cleanName] = nil
end

local alignments         = { left = L["Left"], center = L["Center"], right = L["Right"] }
local widthBehaviorTypes = { free = L["Free"], fixed = L["Fixed"], max = L["Max"] }

function ChocolateBar:AddObjectOptions(name, obj)
    if not obj or not obj.type or (obj.type ~= "data source" and obj.type ~= "launcher") then
        ChocolateBar:Debug("Not adding plugin object: ", obj)
        return
    end
    --local curse = C_AddOns.GetAddOnMetadata(name,"X-Curse-Packaged-Version") or ""
    --local version = C_AddOns.GetAddOnMetadata(name,"Version") or ""

    local cleanName
    local label = obj.label
    if label then
        cleanName = string.gsub(label, "|c........", "")
    else
        cleanName = string.gsub(name, "|c........", "")
    end
    cleanName = string.gsub(cleanName, "|r", "")
    cleanName = string.gsub(cleanName, "[%c \127]", "")

    --use cleanName of name because aceconfig does not like some characters in the plugin names
    chocolateOptions[cleanName] = {
        --name = GetObjectText,
        name = GetName,
        desc = name,
        icon = GetIconImage,
        --iconTexCoords = obj.iconCoords,
        iconCoords = GetIconCoords,
        type = "group",
        args = {
            chocoSettings = {
                inline = true,
                name = GetHeaderName,
                type = "group",
                order = 1,
                args = {
                    label1 = {
                        order = 2,
                        type = "description",
                        name = GetType,
                        --image = GetHeaderImage,
                    },
                    showPluginOnBar = {
                        type = 'execute',
                        order = 3,
                        name = L["Highlight"],
                        desc = L["Temporarily highlights the position of the plugin on the bar."],
                        func = ShowPluginOnBar,
                        disabled = GetDisabled,
                    },
                    enabled = {
                        type = 'toggle',
                        --width = "double",
                        order = 0,
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
                    label = {
                        type = 'toggle',
                        --width = "half",
                        order = 4,
                        name = L["Show Label"],
                        desc = L["Show Label"],
                        get = GetLabel,
                        set = SetLabel,
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
                    alignment = {
                        type = 'select',
                        order = 6,
                        values = alignments,
                        name = L["Alignment"],
                        desc = L["Alignment"],
                        get = GetAlignment,
                        set = SetAlignment,
                    },
                    widthBehavior = {
                        type = 'select',
                        order = 7,
                        values = widthBehaviorTypes,
                        name = L["Width Behavior"],
                        desc = L["How should the plugin width adapt to the text?"],
                        get = GetWidthBehavior,
                        set = SetWidthBehavior,
                    },
                    width = {
                        type = 'range',
                        order = 8,
                        name = L["Fixed/Max Text Width"],
                        desc = L["Set fixed or max width for the text."],
                        min = 0,
                        max = 500,
                        step = 1,
                        get = GetWidth,
                        set = SetWidth,
                        disabled = IsDisabledTextWidth,
                    },
                    customLabel = {
                        type = 'input',
                        order = 2,
                        name = L["Custom Label"],
                        desc = L["Change the label of this plugin."],
                        width = "full",
                        get = GetCustomLabel,
                        set = SetCustomLabel,
                    },
                    disableTooltip = {
                        type = 'toggle',
                        order = 2,
                        name = L["Disable Tooltip"],
                        desc = L["Only show tooltip of this plugin when a modifier (shift, alt, ctrl) is held."],
                        width = "full",
                        get = GetDisableTooltip,
                        set = SetDisableTooltip,
                    },
                },
            },
            textOffset = {
                inline = true,
                name = L["Overwrite Text Offset"],
                type = "group",
                order = 2,
                args = {
                    enabled = {
                        type = 'toggle',
                        order = 2,
                        name = L["Overwrite Text Offset"],
                        desc = L["Overwrite Text Offset"],
                        get = IsEnabledSetTextOffset,
                        set = SetEnabledSetTextOffset,
                    },
                    textOffset = {
                        type = 'range',
                        order = 3,
                        name = L["Text Offset"],
                        desc = L["Set the distance between the icon and the text."],
                        min = -5,
                        max = 15,
                        step = 1,
                        get = GetTextOffset,
                        set = SetTextOffset,
                        disabled = IsDisabledSetTextOffset,
                    },
                },
            },
            iconSize = {
                inline = true,
                name = L["Overwrite Icon Size"],
                type = "group",
                order = 2,
                args = {
                    enabled = {
                        type = 'toggle',
                        order = 2,
                        name = L["Overwrite Icon Size"],
                        desc = L["Overwrite Icon Size"],
                        get = IsEnabledOvwerwriteIconSize,
                        set = SetEnabledOverwriteIconSize,
                    },
                    iconSize = {
                        type = 'range',
                        order = 3,
                        name = L["Icon Size"],
                        desc = L["Icon size in relation to the bar height."],
                        min = 0,
                        max = 1,
                        step = 0.001,
                        bigStep = 0.05,
                        isPercent = true,
                        get = GetCustomIconSize,
                        set = SetCustomIconSize,
                        disabled = IsDisabledOvwerwriteIconSize,
                    },
                },
            },
        },
    }
    addPlaceholderOption(cleanName)
end

function ChocolateBar:AddCustomPluginOptions(pluginName, customOptions)
    for cleanName, _ in pairs(chocolateOptions) do
        if cleanName == pluginName then
            table.insert(chocolateOptions[cleanName].args, customOptions)
        end
    end
end

-- remove a bar and disalbe all plugins in it
function ChocolateBar:RemoveBar(name)
    local bar = self:GetBar(name)
    Drag:UnregisterFrame(bar)
    if bar then
        ChocolateBar:RemoveBarOptions(name)
        bar:Disable()
        for objName, _ in pairs(bar.chocolist) do
            self:DisableDataObject(objName)
        end
        self:GetBars()[name] = nil
        db.barSettings[name] = nil
        self:AnchorBars()
    end
end

-- call when general bar options change
-- updatekey: the key of the update function
function ChocolateBar:UpdateBarOptions(updatekey)
    for _, bar in pairs(self:GetBars()) do
        local func = bar[updatekey]
        if func then
            func(bar, db)
        end
    end
end

function ChocolateBar:OnProfileChanged(_, database)
    db = database.profile
    self:UpdateDB(db)

    -- itaret modules list and call each enable fuction
    for name, _ in pairs(ChocolateBar.modules) do
        if db.moduleSettings[name].enabled then
            ChocolateBar:EnableModule(name)
        else
            ChocolateBar:DisableModule(name)
        end
    end

    for k, v in pairs(self:GetBars()) do
        ChocolateBar:RemoveBarOptions(k)
        v:Hide()
        Drag:UnregisterFrame(v)
        v = nil
    end

    local barSettings = db.barSettings
    for k, v in pairs(barSettings) do
        local name = v.barName
        self:AddBar(k, v, true) --force no anchor update
        self:AddBarOptions(name)
    end
    self:AnchorBars()

    self:UpdateBarOptions()
    for name, obj in broker:DataObjectIterator() do
        local t = obj.type
        if t == "data source" or t == "launcher" then
            --for name, obj in pairs(dataObjects) do
            if db.objSettings[name].enabled then
                local choco = self:GetChocolate(name)
                if choco then
                    choco.settings = db.objSettings[name]
                end
                self:DisableDataObject(name)
                self:EnableDataObject(name, obj, true) --no bar update
            else
                self:DisableDataObject(name)
            end
        end
    end
    self:UpdateBars(true) --update chocolateBars here
    self:UpdateChoclates("resizeFrame")
    moreChocolate = broker:GetDataObjectByName("MoreChocolate")
    if moreChocolate then moreChocolate:SetBar(db) end
end
