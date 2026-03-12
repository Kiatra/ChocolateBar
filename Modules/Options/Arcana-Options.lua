-- -- ✧─────────────────────────────────────-----─────────✧
--  Arcana
--  Options.lua
--
--  Overblown aceoptions tables, fun!
--
--  Made with love by Kiatra ♡
--  Forgetting to to close the brackes is even more fun!
-- ✧───────────────────────────────────────--------───────✧
local LibStub = LibStub
local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local ArcanaOptions = LibStub("AceAddon-3.0"):NewAddon("Arcana-Options")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana-Options")

local _G, pairs, string = _G, pairs, string
local db, moreArcana

local Drag = Arcana.Drag
local addonName = ...

---@diagnostic disable-next-line: undefined-field
local GetAddOnMetadata = _G.GetAddOnMetadata or _G.C_AddOns.GetAddOnMetadata;
local version = GetAddOnMetadata(addonName, "Version") or "unknown";
local title = "|TInterface\\AddOns\\Arcana\\Media\\Icons\\ArcanaKnowledge.tga:" ..
    12 .. ":" .. 12 .. ":0:0|t " .. "Arcana - Quel'dorei Observatory"

--local AceConfig = LibStub("AceConfig-3.0")
--AceConfig:RegisterOptionsTable("Arcana", aceoptions)
function ArcanaOptions:OnInitialize()
    self:RegisterOptions(Arcana.db.profile, _, Arcana.modules)
    for name, obj in LibDataBroker:DataObjectIterator() do
        self:AddObjectOptions(name, obj)
    end

    --inject placeholder options into ace3 object options for placeholder objects
    for placeHolderName, _ in pairs(db.placeholderNames) do
        local options = self:GetOjectOptions()[placeHolderName].args
        if options then
            table.insert(options, self:GetPlaceHolderOptions())
        end
    end

    for name, _ in pairs(Arcana.modules) do
        local subModuleOptions = self:GetAceOptions().args.moduleOptions.args[name].args
        subModuleOptions.Options = Arcana.modules[name].optionsExtended
    end

    for name, _ in pairs(Arcana.arcanaBars) do
        self:AddBarOptions(name)
    end
end

local function GetStats()
    local total = 0
    local enabled = 0
    local data = 0
    for name, obj in LibDataBroker:DataObjectIterator() do
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
    for name, obj in LibDataBroker:DataObjectIterator() do
        Arcana:EnableDataObject(name, obj)
    end
end

local function DisableAll()
    for name, _ in LibDataBroker:DataObjectIterator() do
        Arcana:DisableDataObject(name)
    end
end

local function DisableLauncher()
    for name, obj in LibDataBroker:DataObjectIterator() do
        if obj.type ~= "data source" then
            Arcana:DisableDataObject(name)
        end
    end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function createPlaceholder()
    local placeholderNames = db.placeholderNames
    local name = L["Placeholder"] .. tablelength(placeholderNames)
    placeholderNames[name] = true
    ArcanaOptions:AddObjectOptions(name, Arcana:NewPlaceholder(name))

    local options = ArcanaOptions:GetOjectOptions()[name].args
    if options then
        table.insert(options, ArcanaOptions:GetPlaceHolderOptions())
    end
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

local function getFontOptions()
    return {
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
                Arcana:UpdateArcanaPieces("updatefont")
            end,
        },
        fontOutline = {
            type = 'select',
            order = 2.5,
            name = L["Font Outline"],
            desc = L["Font Outline"],
            values = {
                [""] = L["None"],
                ["OUTLINE"] = L["Outline"],
                ["THICKOUTLINE"] = L["Thick Outline"],
                ["MONOCHROME,OUTLINE"] = L["Monochrome Outline"],
            },
            get = function() return db.fontOutline end,
            set = function(_, value)
                db.fontOutline = value
                Arcana:UpdateArcanaPieces("updatefont")
            end,
        },
        textcolour = {
            type = "color",
            order = 3,
            name = L["Text color"],
            desc =
                L["Default text color of an arcana pice. This will not overwrite arcana pices that use own colors."],
            hasAlpha = true,
            get = function()
                local t = db.textColor or { r = 1, g = 1, b = 1, a = 1 }
                return t.r, t.g, t.b, t.a
            end,
            set = function(_, r, g, b, a)
                db.textColor = db.textColor or { r = 1, g = 1, b = 1, a = 1 }
                local t = db.textColor
                t.r, t.g, t.b, t.a = r, g, b, a
                Arcana:UpdateArcanaPieces("updateSettings")
            end,
        },
        labelColor = {
            type = "color",
            order = 3,
            name = L["Label color"],
            desc = L["Default label color of a arcana pice."],
            hasAlpha = true,
            get = function()
                local t = db.labelColor or { r = 1, g = 0.82, b = 0, a = 1 }
                return t.r, t.g, t.b, t.a
            end,
            set = function(_, r, g, b, a)
                db.labelColor = db.labelColor or { r = 1, g = 0.82, b = 0, a = 1 }
                local t = db.labelColor
                t.r, t.g, t.b, t.a = r, g, b, a
                Arcana:UpdateArcanaPieces("updateSettings")
            end,
        },
        iconcolour = {
            type = "toggle",
            order = 4,
            name = L["Desaturated Icons"],
            desc =
                L["Show icons in gray scale mode (This will not affect icons embedded in the text of a arcana pice)."],
            get = function()
                return db.desaturated
            end,
            set = function(_, vale)
                db.desaturated = vale
                for name, _ in LibDataBroker:DataObjectIterator() do
                    if db.objSettings[name] then
                        if db.objSettings[name].enabled then
                            local object = Arcana:GetArcanaPice(name)
                            if object then
                                object:Update(object, "iconR", nil)
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
            desc = L["Remove custom colors from arcana pices."],
            get = function()
                return db.forceColor
            end,
            set = function(_, value)
                db.forceColor = value
                for name, obj in LibDataBroker:DataObjectIterator() do
                    if db.objSettings[name] then
                        if db.objSettings[name].enabled then
                            local object = Arcana:GetArcanaPice(name)
                            if object then
                                object:Update(_, "text", obj.text)
                            end
                        end
                    end
                end
            end,
        },
    }
end

local function getCombatOptions()
    return {
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
                for _, bar in pairs(Arcana:GetBars()) do
                    bar.tempHide = bar:GetAlpha()
                    bar:SetAlpha(db.combatopacity)
                end
                Arcana:CancelTimer(opacityTimer)
                opacityTimer = Arcana:ScheduleTimer(function(_)
                    for _, bar in pairs(Arcana:GetBars()) do
                        bar:SetAlpha(bar.settings.opacity)
                    end
                end, 2)
            end,
        },
    }
end

local function getTextureOptions()
    return {
        textureStatusbar = {
            type = 'select',
            dialogControl = 'LSM30_Statusbar',
            values = AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.statusbar or {},
            order = 1,
            name = L["StatusBar Texture"],
            desc = L["Note: Some LibSharedMedia provided textures may be provided by other addons."],
            get = function()
                return db.background.textureName
            end,
            set = function(_, value)
                db.background.texture = LibSharedMedia:Fetch("statusbar", value)
                db.background.textureName = value
                db.background.tile = false
                ArcanaOptions:UpdateBarOptions("UpdateTexture")
            end,
        },
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
                ArcanaOptions:UpdateBarOptions("UpdateColors")
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
                ArcanaOptions:UpdateBarOptions("UpdateColors")
            end,
        }
    }
end

local function getAdvancedTextureOptions()
    return {
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
                db.background.texture = LibSharedMedia:Fetch("background", value)
                db.background.textureName = value
                db.background.tile = true
                local t = db.background.color
                t.r, t.g, t.b, t.a = 1, 1, 1, 1
                ArcanaOptions:UpdateBarOptions("UpdateTexture")
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
                ArcanaOptions:UpdateBarOptions("UpdateTexture")
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
                ArcanaOptions:UpdateBarOptions("UpdateTexture")
            end,
        }
    }
end

local function getObjectOptions()
    return {
        stats = {
            inline = true,
            name = L["Arcana Pice Statistics"],
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
                    desc = L["Get back my arcana pices!"],
                    func = EnableAll,
                },
                disableAll = {
                    type = 'execute',
                    order = 4,
                    name = L["Disable All"],
                    desc = L["Disable all arcana pices."],
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
        defaults = {
            inline = true,
            name = L["Defaults"],
            type = "group",
            order = 3,
            args = {
                label = {
                    order = 0,
                    type = "description",
                    name = L["Automatically disable new arcana pices of type:"],
                },
                dataobjects = {
                    type = 'toggle',
                    order = 1,
                    name = L["Data Source"],
                    desc = L
                        ["If enabled new arcana pices of type data source will automatically be disabled."],
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
                    desc = L["If enabled new arcana pices of type launcher will automatically be disabled."],
                    get = function()
                        return db.autodislauncher
                    end,
                    set = function(_, value)
                        db.autodislauncher = value
                    end,
                },
            },
        },
        placeholder = {
            inline = true,
            name = L["Placeholder"],
            type = "group",
            order = 4,
            args = {
                label = {
                    order = 0,
                    type = "description",
                    name = L["A placeholder is a arcana pice with no text that you can put between arcana pices."] ..
                        "\n" ..
                        L["Tipp: Set the width behavior to fixed and adjust the the max text width to scale the placeholder."],
                },
                newPlaceholder = {
                    type = 'execute',
                    order = -1,
                    name = L["Create Placeholder"],
                    desc = L["Creates a new arcana pice to use as a placeholder."],
                    func = createPlaceholder,
                },
            },
        },
        --@debug@
        debug = {
            type = 'toggle',
            order = 30,
            name = "Debug",
            desc = "This one is for me, not for you :P",
            get = function()
                return Arcana.db.char.debug
            end,
            set = function(_, value)
                Arcana.db.char.debug = value
            end,
        },
        --@end-debug@
    }
end

local function BuildNewsArgs()
    local args = {}
    local order = 1

    -- find highest index
    local max = 0
    for key in pairs(L) do
        local i = key:match("^news%.(%d+)%.header$")
        if i then
            i = tonumber(i)
            if i > max then
                ---@diagnostic disable-next-line: cast-local-type
                max = i
            end
        end
    end

    -- newest → oldest
    for i = max, 1, -1 do
        if rawget(L, "news." .. i .. ".header") then
            args["header" .. i] = {
                order = order,
                type = "header",
                name = L["news." .. i .. ".header"],
            }
            order = order + 1

            args["text" .. i] = {
                order = order,
                type = "description",
                name = L["news." .. i .. ".text"],
            }
            order = order + 1
        end
    end

    return args
end

local aceoptions = {
    name = title,
    handler = Arcana,
    type = 'group',
    childGroups = "tab",
    desc = "Arcana - Quel'dorei Observatory",
    args = {
        version = {
            order = 1,
            type = "description",
            name = version,
        },
        newsAndObjects = {
            name = L["Info & Arcana Pices"],
            type = "group",
            order = 0,
            args = {
                infoAndNews = {
                    name = L["Whats New & Info"],
                    type = "group",
                    order = 1,
                    args = {
                        info = {
                            name = title,
                            type = "group",
                            inline = true,
                            order = 0,
                            args = {
                                infoText = {
                                    order = increment(),
                                    type = "description",
                                    name = L
                                        ["infoandnews.infoText"]
                                },
                                infoTextObjects = {
                                    order = increment(),
                                    type = "description",
                                    name = L
                                        ["infoandnews.adding.arcanapices"],
                                },
                                objects = {
                                    order = increment(),
                                    type = "execute",
                                    name = L["arcanapices.search"],
                                    func = function()
                                        showURLPopup(
                                            "https://www.curseforge.com/wow/search?sortBy=popularity&class=addons&categories=data-broker&search=plugin");
                                    end,
                                    width = 1.5,
                                }
                            }
                        },
                        news = {
                            name = L["Whats New"],
                            type = "group",
                            inline = true,
                            order = -1,
                            args = BuildNewsArgs()
                        }
                    }
                },
                objects = {
                    name = L["group.arcanaPices"],
                    type = "group",
                    order = -1,
                    args = getObjectOptions()
                }
            }
        },
        general = {
            name = L["General"],
            type = "group",
            order = 1,
            args = {
                general = {
                    inline = true,
                    name = L["General"],
                    type = "group",
                    order = 1,
                    args = {
                        locked = {
                            type = 'toggle',
                            order = 1,
                            name = L["Lock Arcana Pices"],
                            desc = L["Hold alt key to drag a arcana pice."],
                            get = function()
                                return db.locked
                            end,
                            set = function(_, value)
                                db.locked = value
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
                                ArcanaOptions:UpdateBarOptions("UpdateAutoHide")
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
                                Arcana:ToggleOrderHallCommandBar()
                            end,
                        },
                    },
                },
                combat = {
                    name = L["In Combat"],
                    type = "group",
                    inline = true,
                    order = 1,
                    args = getCombatOptions()
                }
            },
        },
        lookAndTexture = {
            name = L["Look & Texture"],
            type = "group",
            order = 4,
            args = {
                general = {
                    inline = true,
                    name = L["General"],
                    type = "group",
                    order = 1,
                    args = {
                        gap = {
                            type = 'range',
                            order = 10,
                            name = L["Gap"],
                            desc = L["Set the gap between the arcana pieces."],
                            min = 0,
                            max = 50,
                            step = 1,
                            get = function()
                                return db.gap
                            end,
                            set = function(_, value)
                                db.gap = value
                                Arcana.ArcanaPiece:UpdateGap(value)
                                Arcana:UpdateArcanaPieces("updateSettings")
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
                                Arcana:UpdateArcanaPieces("updateSettings")
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
                                ArcanaOptions:UpdateBarOptions("UpdateHeight")
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
                                ArcanaOptions:UpdateBarOptions("UpdateHeight")
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
                                ArcanaOptions:UpdateBarOptions("UpdateStrata")
                            end,
                        },
                    }
                },
                textures = {
                    inline = true,
                    name = L["Textures"],
                    type = "group",
                    order = 2,
                    args = getTextureOptions()
                },
                advanced = {
                    inline = true,
                    name = L["Advanced Textures"],
                    type = "group",
                    order = 3,
                    args = getAdvancedTextureOptions()
                },
                font = {
                    inline = true,
                    name = L["Font"],
                    type = "group",
                    order = 4,
                    args = getFontOptions()
                },
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
                        local name = Arcana:AddBar()
                        ArcanaOptions:AddBarOptions(name)
                    end,
                }
            }
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
                        ["Modules are buildin arcana pices that can be enabled or disabled here. Disabled arcana pices will not be loaded."]
                }
            }
        }
    }
}

aceoptions.args.lookAndTexture.args.font.args.font = {
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
        db.fontPath = LibSharedMedia:Fetch("font", value)
        db.fontName = value
        Arcana:UpdateArcanaPieces("updatefont")
    end,
}

local objectOptions = aceoptions.args.newsAndObjects.args.objects.args
local barOptions = aceoptions.args.bars.args
local moduleOptions = aceoptions.args.moduleOptions.args
Arcana.optionsTable = aceoptions

---
-- placeholder options
function ArcanaOptions:GetOjectOptions()
    return objectOptions
end

local function removePlaceholder(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.placeholderNames[cleanName] = nil
    print(db.placeholderNames)
    Arcana:DisableDataObject(name)
    objectOptions[cleanName] = nil
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

function ArcanaOptions:GetPlaceHolderOptions()
    return placeholderOptions
end

-----
-- bar option functions
-----
function ArcanaOptions:GetAceOptions()
    return aceoptions
end

-- return the number of bars aligend to align (top or bottom)
function ArcanaOptions:GetNumBars(align)
    local i = 0
    for _, v in pairs(Arcana:GetBars()) do
        if v.settings.align == align then
            i = i + 1
        end
    end
    return i
end

local function GetBarName(info)
    local name = info[#info]
    local bar = Arcana:GetBar(name)
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
    local bar = Arcana:GetBar(name)
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
        local bar = Arcana:GetBar(name)
        if bar then
            bar:UpdateAutoHide(db)
            Arcana:AnchorBars()
        end
    end
end

local function RemoveBar(info)
    local name = info[#info - 2]
    Arcana:RemoveBar(name)
end

local function MoveUp(info)
    local name = info[#info - 2]
    local bar = Arcana:GetBar(name)
    local index = bar.settings.index
    if bar then
        if db.barSettings[name].align == "bottom" then
            index = index + 1.5
            if index > (ArcanaOptions:GetNumBars("bottom") + 1) then
                index = ArcanaOptions:GetNumBars("top") + 1
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
        Arcana:AnchorBars()
    end
end

local function MoveDown(info)
    local name = info[#info - 2]
    local bar = Arcana:GetBar(name)
    local index = bar.settings.index
    if bar then
        if db.barSettings[name].align == "bottom" then
            index = index - 1.5
        elseif db.barSettings[name].align == "top" then
            index = index + 1.5
            if index > (ArcanaOptions:GetNumBars("top") + 1) then
                index = ArcanaOptions:GetNumBars("bottom") + 1
                SetBarAlign(info, "bottom")
            end
        else
            db.barSettings[name].align = "top"
            index = 0
            SetBarAlign(info, "top")
        end
        bar.settings.index = index
        Arcana:AnchorBars()
    end
end

local function getAutoHide(info)
    local name = info[#info - 2]
    return db.barSettings[name].autohide
end

local function setAutoHide(info, value)
    local name = info[#info - 2]
    db.barSettings[name].autohide = value
    local bar = Arcana:GetBar(name)
    bar:UpdateAutoHide(db)
end

------- Bar Opacity -----------------------------------
local function getOpacity(info)
    local name = info[#info - 2]
    return db.barSettings[name].opacity or 1
end

local function setOpacity(info, value)
    local name = info[#info - 2]
    if value > 1 then
        value = 1
    elseif value < 0.01 then
        value = 0.001
    end
    db.barSettings[name].opacity = value
    local bar = Arcana:GetBar(name)
    bar:SetAlpha(value)
end

------- Bar OpacityMouseOver --------------------------
local function getOpacityMouseOver(info)
    local name = info[#info - 2]
    return db.barSettings[name].opacityMouseOver or 1
end

local function setOpacityMouseOver(info, value)
    local name = info[#info - 2]
    if value > 1 then
        value = 1
    elseif value < 0.01 then
        value = 0.001
    end
    db.barSettings[name].opacityMouseOver = value

    local currentBar = Arcana:GetBar(name)
    currentBar:SetAlpha(value)

    Arcana:CancelTimer(opacityTimer)
    opacityTimer = Arcana:ScheduleTimer(function(_)
        for _, bar in pairs(Arcana:GetBars()) do
            bar:SetAlpha(db.barSettings[name].opacity or 1)
        end
    end, 2)
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
    local bar = Arcana:GetBar(name)
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
    Arcana:StartMoving()
    Arcana.isMoving = true
end

local function OnDragStop(self)
    Arcana:StopMovingOrSizing()
    Arcana.isMoving = false
end

local function SetLockedBar(info, value)
    local name = info[#info - 2]
    local settings = db.barSettings[name]
    local bar = Arcana:GetBar(name)
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
                    Arcana:ChatCommand()
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
        for _, v in pairs(bar.arcanaPices) do
            v:Hide()
        end
    else
        bar:SetClampedToScreen(false)
        for _, v in pairs(bar.arcanaPices) do
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
    local bar = Arcana:GetBar(name)
    if not value then
        SetLockedBar(info, true)
        db.barSettings[name].align = "top"
        bar:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
        Arcana:AnchorBars()
    else
        db.barSettings[name].align = "custom"
    end
    bar:UpdateJostle(db)
end

local function GetLockedBar(info)
    local name = info[#info - 2]
    local bar = Arcana:GetBar(name)
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
    local bar = Arcana:GetBar(name)
    local settings = bar.settings
    return settings.align == "custom" or (settings.align == "bottom" and settings.index < 1.5)
end

local function IsDisabledMoveUp(info)
    local name = info[#info - 2]
    local bar = Arcana:GetBar(name)
    local settings = db.barSettings[name]
    return settings.align == "custom" or (settings.align == "top" and bar.settings.index < 1.5)
end

-----
-- object option functions
-----
local function GetStyledIdentifier(info)
    local cleanName = info[#info]
    local name = objectOptions[cleanName].desc
    --local icon = objectOptions[cleanName].icon
    local dataobj = LibDataBroker:GetDataObjectByName(name)

    local styled = ""
    if (not db.objSettings[name].enabled) then
        -- disabled
        styled = "|H" .. name .. "|h|cFFFF0000" .. name .. "|r"
    elseif dataobj and dataobj.type == "data source" then
        --enabled data source
        --local arcanaPice = Arcana:GetArcanaPice(name)
        --local text = arcanaPice and arcanaPice.text and arcanaPice.text:GetText()
        --styled = text and "|H" .. name .. "|h" .. name .. " |cFFBBBBBB[|r" .. text .. "|cFFBBBBBB]|r"
        --or "|H" .. name .. "|h" .. name
        styled = "|H" .. name .. "|h" .. name
    else
        --enabled launcher
        styled = "|H" .. name .. "|h|cFFBBBBBB" .. name .. "|r"
    end
    return styled
end

local function GetType(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return (LibDataBroker:GetDataObjectByName(name).type == "data source" and L["Type"] .. ": " .. L["Data Source"] .. "\n") or
        L["Type"] .. ": " .. L["Launcher"] .. "\n"
end

local function GetAlignment(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].align
end

local function SetAlignment(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].align = value
    local object = Arcana:GetArcanaPice(name)
    db.objSettings[name].index = 500
    if object and object.bar then
        object.bar:UpdateBar(true)
        --object.bar:UpdateBar()
    end
end

local function SetEnabled(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    if value then
        local obj = LibDataBroker:GetDataObjectByName(name)
        Arcana:EnableDataObject(name, obj)
    else
        Arcana:DisableDataObject(name)
    end
end

local function GetEnabled(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].enabled
end

local function GetDisabled(info)
    return not GetEnabled(info)
end

local function GetIcon(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].showIcon
end

local function SetIcon(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].showIcon = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetCustomLabel(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].customLabel
end

local function SetCustomLabel(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].customLabel = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetDisableTooltip(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].disableTooltip
end

local function SetDisableTooltip(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].disableTooltip = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetLabel(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].showLabel
end

local function SetLabel(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].showLabel = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetText(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].showText
end

local function SetText(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].showText = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].textOffset or db.textOffset
end

local function SetTextOffset(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].textOffset = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetWidth(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].width
end

local function SetWidth(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].width = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function GetWidthBehavior(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    if not db.objSettings[name].widthBehavior and db.objSettings[name].width == 0 then
        return "free"
    else
        return db.objSettings[name].widthBehavior or "fixed"
    end
end

local function SetWidthBehavior(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    db.objSettings[name].widthBehavior = value
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function IsDisabledTextWidth(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return true and (db.objSettings[name].widthBehavior == "free" or not db.objSettings[name].widthBehavior) or false
end

local function GetIconImage(info, name)
    if info then
        local cleanName = info[#info]
        name = objectOptions[cleanName].desc
    end
    local obj = LibDataBroker:GetDataObjectByName(name)
    if obj and obj.icon then
        return obj.icon
    end
    return "Interface\\AddOns\\Arcana\\Media\\ArcanaKnowledge"
end

local function GetIconCoords(info)
    local cleanName = info[#info]
    local name = objectOptions[cleanName].desc
    local obj = LibDataBroker:GetDataObjectByName(name)
    if obj and obj.iconCoords then
        return obj.iconCoords
    end
end

local function IsDisabledIcon(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    local obj = LibDataBroker:GetDataObjectByName(name)
    return not (obj and obj.icon) --return true if there is no icon
end

local function IsDisabledSetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return not db.objSettings[name].textOffset
end

local function IsEnabledSetTextOffset(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].textOffset
end

local function SetEnabledSetTextOffset(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    local settings = db.objSettings[name]
    if settings.textOffset then
        settings.textOffset = nil
    else
        settings.textOffset = db.textOffset
    end
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function SetEnabledOverwriteIconSize(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    local settings = db.objSettings[name]
    if settings.iconSize then
        settings.iconSize = nil
    else
        settings.iconSize = db.iconSize
    end
    Arcana:AttributeChanged(nil, name, "updateSettings", value)
end

local function SetCustomIconSize(info, value)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    if value > 1 then
        value = 1
    elseif value < 0.01 then
        value = 0.001
    end
    db.objSettings[name].iconSize = value
    ArcanaOptions:UpdateBarOptions("UpdateHeight")
end

local function GetCustomIconSize(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].iconSize or db.iconSize
end

local function IsEnabledOvwerwriteIconSize(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return db.objSettings[name].iconSize
end

local function IsDisabledOvwerwriteIconSize(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    return not db.objSettings[name].iconSize
end


local function GetHeaderName(info)
    local cleanName = info[#info - 1]
    local name = objectOptions[cleanName].desc
    local nameWithIcon = "|T" .. GetIconImage(nil, name) .. ":18|t " .. name
    return nameWithIcon
end

local function ShowArcanaPiceOnBar(info)
    local cleanName = info[#info - 2]
    local name = objectOptions[cleanName].desc
    local object = Arcana:GetArcanaPice(name)
    if object then
        object.blinkTimerCount = 0

        local pointer = Arcana:GetPointer(object)
        pointer:ClearAllPoints()
        pointer:SetPoint("CENTER", object, "CENTER", pointer:GetWidth() / 2, 0)
        pointer:SetAlpha(0)
        pointer:Hide()
        pointer:Show()
        object.timer = Arcana:ScheduleRepeatingTimer(function(obj)
            local c = obj.blinkTimerCount
            c = c + 1
            obj:highlight(1, 0, 0, c % 2)
            pointer:SetAlpha(c % 2)
            if c >= 10 then
                Arcana:CancelTimer(obj.timer)
                object:highlight(1, 0, 0, 0)
                obj:SetAlpha(0)
                pointer:Hide()
            end
            obj.blinkTimerCount = c
        end, 0.1, object)
    end
end

function ArcanaOptions:UpdateOptions(arcanaBars)
    for name, obj in LibDataBroker:DataObjectIterator() do
        Arcana:AddObjectOptions(name, obj)
    end

    for name, _ in pairs(arcanaBars) do
        self:AddBarOptions(name)
    end
end

function ArcanaOptions:RegisterOptions(data, _, modules)
    db = data
    aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Arcana.db)
    AceConfigDialog:SetDefaultSize("Arcana", 700, 600)

    AceConfigDialog:SelectGroup("Arcana", "newsAndObjects", "objects")
    AceConfigDialog:SelectGroup("Arcana", "newsAndObjects", "news")

    for name, module in pairs(modules) do
        --Arcana:AddModuleOptions(name, module.options)
        moduleOptions[name] = module.options
        if module.OnOpenOptions then module:OnOpenOptions() end
    end
end

function ArcanaOptions:OpenOptions(objName)
    if objName then
        AceConfigDialog:SelectGroup("Arcana", "newsAndObjects", "objects", objName)
    end

    if InCombatLockdown() then
        Arcana:Info("|cff88ccffArcana|r", L["combat.openoption"])
        AceConfigDialog:Open("Arcana")
    else
        Settings.OpenToCategory(Arcana.BlizzardOptionsCategoryID)
    end
end

function ArcanaOptions:BuildArcanaOptions()
    return aceoptions
end

function ArcanaOptions:AddBarOptions(name)
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
                        order = 1,
                        name = L["Autohide"],
                        desc = L["Autohide"],
                        get = getAutoHide,
                        set = setAutoHide
                    },
                    opacity = {
                        type = 'range',
                        order = 2,
                        name = L["Opacity"],
                        desc = L
                            ["Set the opacity of the the bars. You can set the alpha of the bar background unter textures."],
                        min = 0,
                        max = 1,
                        step = 0.001,
                        bigStep = 0.05,
                        isPercent = true,
                        get = getOpacity,
                        set = setOpacity,
                        disabled = getAutoHide
                    },
                    opacityMouseOver = {
                        type = 'range',
                        order = 3,
                        name = L["Mouseover Opacity"],
                        desc = L["Set the opacity of the the bars when the mouse is over a bar."],
                        min = 0,
                        max = 1,
                        step = 0.001,
                        bigStep = 0.05,
                        isPercent = true,
                        get = getOpacityMouseOver,
                        set = setOpacityMouseOver,
                        disabled = getAutoHide
                    },
                    removeBar = {
                        type = 'execute',
                        order = 6,
                        name = L["Remove Bar"],
                        desc = L["Removes the selected Bar."],
                        func = RemoveBar,
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

function ArcanaOptions:RemoveBarOptions(name)
    barOptions[name] = nil
end

function ArcanaOptions:RemoveobjectOptions(cleanName)
    objectOptions[cleanName] = nil
end

local alignments         = { left = L["Left"], center = L["Center"], right = L["Right"] }
local widthBehaviorTypes = { free = L["Free"], fixed = L["Fixed"], max = L["Max"] }

function ArcanaOptions:AddObjectOptions(name, obj)
    if not obj or not obj.type or (obj.type ~= "data source" and obj.type ~= "launcher") then
        Arcana:Log("Not adding arcna object: ", name, " type: ", obj.type)
        return
    end

    local cleanName = Arcana:GetCleanName(name)
    --use cleanName of name because aceconfig does not like some characters in the object names
    objectOptions[cleanName] = {
        name = GetStyledIdentifier,
        desc = name,
        desc2 = name,
        cleanName = cleanName,
        icon = GetIconImage,
        --iconTexCoords = obj.iconCoords,
        iconCoords = GetIconCoords,
        type = "group",
        args = {
            objectsSettings = {
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
                    showArcanaPiceOnBar = {
                        type = 'execute',
                        order = 3,
                        name = L["Highlight"],
                        desc = L["Temporarily highlights the position of the arcana pice on the bar."],
                        func = ShowArcanaPiceOnBar,
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
                        desc = L["How should the arcana pice width adapt to the text?"],
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
                        desc = L["Change the label of this arcana pice."],
                        width = "full",
                        get = GetCustomLabel,
                        set = SetCustomLabel,
                    },
                    disableTooltip = {
                        type = 'toggle',
                        order = 2,
                        name = L["Disable Tooltip"],
                        desc = L["Only show tooltip of this arcana pice when a modifier (shift, alt, ctrl) is held."],
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
end

function ArcanaOptions:AddCustomobjectOptions(objectName, customOptions)
    for cleanName, _ in pairs(objectOptions) do
        if cleanName == objectName then
            table.insert(objectOptions[cleanName].args, customOptions)
        end
    end
end

-- remove a bar and disalbe all arcana pices in it
function ArcanaOptions:RemoveBar(name)
    local bar = Arcana:GetBar(name)
    Drag:UnregisterFrame(bar)
    if bar then
        Arcana:RemoveBarOptions(name)
        bar:Disable()
        for objName, _ in pairs(bar.arcanaPices) do
            Arcana:DisableDataObject(objName)
        end
        Arcana:GetBars()[name] = nil
        db.barSettings[name] = nil
        Arcana:AnchorBars()
    end
end

-- call when general bar options change
-- updatekey: the key of the update function
function ArcanaOptions:UpdateBarOptions(updatekey)
    for _, bar in pairs(Arcana:GetBars()) do
        local func = bar[updatekey]
        if func then
            func(bar, db)
        end
    end
end

function ArcanaOptions:OptionsOnProfileChanged(_, database)
    local arcanalabelColor = db.labelColor

    db = database.profile
    Arcana:UpdateDB(db)

    -- itaret modules list and call each enable fuction
    for name, _ in pairs(Arcana.modules) do
        if db.moduleSettings[name].enabled then
            Arcana:EnableModule(name)
        else
            Arcana:DisableModule(name)
        end
    end

    for k, v in pairs(Arcana:GetBars()) do
        Arcana:RemoveBarOptions(k)
        v:Hide()
        Drag:UnregisterFrame(v)
        v = nil
    end

    local barSettings = db.barSettings
    for k, v in pairs(barSettings) do
        local name = v.barName
        Arcana:AddBar(k, v, true) --force no anchor update
        self:AddBarOptions(name)
    end

    Arcana:AnchorBars()
    self:UpdateBarOptions()

    for name, obj in LibDataBroker:DataObjectIterator() do
        local t = obj.type
        if t == "data source" or t == "launcher" then
            --for name, obj in pairs(dataObjects) do
            if db.objSettings[name].enabled then
                local object = Arcana:GetArcanaPice(name)
                if object then
                    object.settings = db.objSettings[name]
                end
                Arcana:DisableDataObject(name)
                Arcana:EnableDataObject(name, obj, true) --no bar update
            else
                Arcana:DisableDataObject(name)
            end
        end
    end
    Arcana:UpdateBars(true) --update arcanaBars here
    Arcana:UpdateArcanaPieces("updateSettings")
    Arcana:UpdateArcanaPieces("resizeFrame")

    --Arcana:AttributeChanged(nil, name, "updateSettings", value)
    moreArcana = LibDataBroker:GetDataObjectByName("MoreArcana")
    if moreArcana then moreArcana:SetBar(db) end
end
