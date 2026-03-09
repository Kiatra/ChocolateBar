local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local L = LibStub("AceLocale-3.0"):GetLocale("Arcana")

local LSM = LibStub("LibSharedMedia-3.0")
local Bar = Arcana.Bar
local ArcanaPiece = Arcana.ArcanaPiece
local jostle = Arcana.Jostle
local _G, pairs, ipairs, table, math, mod = _G, pairs, ipairs, table, math, mod
local CreateFrame, UIParent = CreateFrame, UIParent
local db

function Bar:OnMouseUp(button)
    if (db.combathidebar or self.settings.hideBarInCombat) and Arcana.InCombat then return end
    if button == "RightButton" then
        if db.disableoptons and Arcana.InCombat then return end
        if db.barRightClick == "OPTIONS" then
            Arcana:LoadOptions()
        elseif db.barRightClick == "BLIZZ" then
            if InCombatLockdown() then
                Arcana:LoadOptions()
                print("|cff88ccffArcana|r", L["Opening Arcana only options during combat."])
            else
                Arcana:LoadOptions(nil, nil, true)
            end
        end
    else
        if db.moreBar == self:GetName() then
            self:Hide()
        end
    end
end

function Bar:OnEnter()
    if (db.combathidebar or self.settings.hideBarInCombat) and Arcana.InCombat then return end
    self:ShowAll()
    if self.settings.opacityMouseOver ~= self.settings.opacity then
        self:SetAlpha(self.settings.opacityMouseOver or 1)
    end
end

function Bar:OnLeave()
    if (db.combathidebar or self.settings.hideBarInCombat) and Arcana.InCombat then return end
    if self.settings.autohide then
        self:HideAll()
    elseif self.settings.opacityMouseOver ~= self.settings.opacity then
        self:SetAlpha(self.settings.opacity or 1)
    end
end

function Bar:New(name, settings, database)
    db = database
    local frame = CreateFrame("Frame", name, _G.UIParent, BackdropTemplateMixin and "BackdropTemplate")
    ---@diagnostic disable-next-line: inject-field
    frame.pluginList = {} --create list of plugin pluginList in the bar

    -- add class methods to frame object
    for k, v in pairs(Bar) do
        frame[k] = v
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    frame:SetPoint("TOPLEFT", -1, 1);
    --frame:SetPoint("TOPLEFT", settings.xoff, settings.yoff);
    --frame:SetClampedToScreen(true)
    if settings.width == 0 then
        frame:ClearAllPoints()
        ---@diagnostic disable-next-line: param-type-mismatch
        frame:SetPoint("TOPLEFT", "UIParent", -1, 1);
        ---@diagnostic disable-next-line: param-type-mismatch
        frame:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        frame:SetPoint("RIGHT", "UIParent", 0, 0);
        frame:SetWidth(settings.width)
    end

    frame:SetHeight(db.height)
    ---@diagnostic disable-next-line: param-type-mismatch
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", self.OnEnter)
    frame:SetScript("OnLeave", self.OnLeave)
    frame:SetScript("OnMouseUp", self.OnMouseUp)

    ---@diagnostic disable-next-line: inject-field
    frame.settings = settings
    ---@diagnostic disable-next-line: inject-field
    frame.autohide = settings.hideonleave
    ---@diagnostic disable-next-line: undefined-field
    frame:UpdateTexture(db)
    ---@diagnostic disable-next-line: undefined-field
    frame:UpdateColors(db)
    ---@diagnostic disable-next-line: undefined-field
    frame:UpdateStrata(db)
    return frame
end

function Bar:UpdateStrata(db)
    self:SetFrameStrata(db.strata)
end

function Bar:UpdateAutoHide(db)
    if self.settings.autohide then
        self.autohide = true
        self:HideAll()
        if jostle then jostle:Unregister(self) end
    else
        self.autohide = false
        self:ShowAll()
        self:UpdateJostle(db)
    end
end

function Bar:UpdateJostle(db)
    if jostle then
        jostle:Unregister(self)
        if db.moveFrames then
            if self.settings.align == "bottom" then
                jostle:RegisterBottom(self)
            elseif self.settings.align == "top" then
                jostle:RegisterTop(self)
            end
        end
    end
end

function Bar:UpdateScale(db)
    self.scale = db.scale
    self:SetScale(db.scale)
    self:UpdateJostle(db)
end

function Bar:UpdateHeight(db)
    local height = db.height
    self.height = height
    self:SetHeight(height)
    Arcana:UpdatePlugins("updateSettings")
    db.fontSize = height - 8
    Arcana:UpdatePlugins("updatefont")
    self:UpdateJostle(db)
end

function Bar:UpdateColors(db)
    local bg = db.background
    local color = bg.borderColor
    self:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
    color = bg.color
    self:SetBackdropColor(color.r, color.g, color.b, color.a)
end

function Bar:UpdateTexture(db)
    local bg = {
        bgFile = db.background.texture,
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = db.background.tile,
        tileSize = db.background.tileSize,
        edgeSize = db.background.edgeSize,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    }
    self:SetBackdrop(bg);
    self:UpdateColors(db)
end

function Bar:ResetDrag(plugin, name)
    self.pluginList[name] = plugin
    self.dummy:Hide()
    self.dummy = nil
    plugin:SetAlpha(1)
    self:UpdateBar()
end

-- add some plugin to a bar
function Bar:AddArcanaPiece(plugin, name, noupdate)
    local pluginList = self.pluginList
    if pluginList[name] then
        return
    end

    pluginList[name] = plugin
    plugin:SetParent(self)
    plugin.bar = self

    local settings = plugin.settings
    settings.barName = self:GetName()

    if not noupdate then
        self:UpdateBar()
    end

    if self:GetAlpha() < 1 then
        plugin.text:Hide()
        if plugin.icon then
            plugin.icon:Hide()
        end
    end
end

-- reamove given plugin from a Arcana
function Bar:RemoveArcanaPiece(name)
    self.pluginList = self.pluginList or {}
    local plugin = self.pluginList[name]
    if plugin then
        plugin:Hide()
        self.pluginList[name] = nil
        self:UpdateBar()
    end
end

function Bar:HideAll()
    self:SetAlpha(0)
    for k, v in pairs(self.pluginList) do
        v.text:Hide()
        if v.icon then
            v.icon:Hide()
        end
    end
end

function Bar:ShowAll()
    self:SetAlpha(self.settings.opacity or 1)
    local settings
    for k, v in pairs(self.pluginList) do
        settings = v.settings
        --v:Show()
        if settings.showText then
            v.text:Show()
        end
        if settings.showIcon and v.icon then
            v.icon:Show()
        end
    end
end

function Bar:Disable()
    self:Hide()
    if jostle then jostle:Unregister(self) end
end

local function SortTab(tab)
    local templeft = {}
    local tempright = {}
    local tempcenter = {}

    for k, v in pairs(tab) do
        local index = v.settings.index or 500
        if v.settings.align == "left" then
            table.insert(templeft, { v, index })
        elseif v.settings.align == "center" then
            table.insert(tempcenter, { v, index })
        else
            table.insert(tempright, { v, index })
        end
    end
    table.sort(templeft, function(a, b) return a[2] < b[2] end)
    table.sort(tempcenter, function(a, b) return a[2] < b[2] end)
    table.sort(tempright, function(a, b) return a[2] < b[2] end)
    return templeft, tempcenter, tempright
end

local function SortList(list, side)
    local temp = {}
    for k, v in pairs(list) do
        local index = v.settings.index or 500
        if v.settings.align == side then
            table.insert(temp, { v, index })
        end
    end
    table.sort(temp, function(a, b) return a[2] < b[2] end)
    return temp
end

function Bar:GetPluginAtCursor()
    local s = self:GetEffectiveScale()
    local x, y = GetCursorPosition()

    if not s and x and y then return end

    x = x / s
    for _, v in pairs(self.pluginList) do
        if v and x > v:GetLeft() and x < v:GetRight() then --plugin found
            if x < v:GetLeft() + v:GetWidth() / 2 then
                return v, "left"
            else
                return v, "right"
            end
        end
    end
    -- cursor over bar
    local left = self.pluginMostLeft and self.pluginMostLeft:GetRight() or self:GetLeft()
    local right = self.pluginMostRight and self.pluginMostRight:GetLeft() or self:GetRight()
    local centerL = self.pluginCenterLeft and self.pluginCenterLeft:GetLeft() or self:GetWidth() / 2
    local centerR = self.pluginCenterRight and self.pluginCenterRight:GetRight() or self:GetWidth() / 2

    local nameCenterLeft = self.pluginCenterLeft and self.pluginCenterLeft:GetName()
    local nameCenterRight = self.pluginCenterRight and self.pluginCenterRight:GetName()

    if x < 8 then
        return nil, "left", "left" --left half on left side
    end
    if x > UIParent:GetWidth() - 8 then
        return nil, "right", "right"
    end

    local centerPos = "center"
    -- nocenter
    if left > centerR then
        if x < right / 2 + left / 2 then
            return self.pluginMostLeft, "right", "left"  --left half on right side
        else
            return self.pluginMostRight, "left", "right" --right half on right side,
        end
    end
    if right < centerL then
        if x < right / 2 + left / 2 then
            return self.pluginMostLeft, "right", "left"  --left half on left side
        else
            return self.pluginMostRight, "left", "right" --right half on left side
        end
    end
    -- with center
    if x < centerL then
        if x < centerL / 2 + left / 2 then
            return self.pluginMostLeft, "right", "left"    --left half on left side
        else
            return self.pluginCenterLeft, "left", "center" --right half on left side
        end
    end
    if x > centerR and x < right then
        if x < right / 2 + centerR / 2 then
            return self.pluginCenterRight, "right", "center" --left half on right side
        else
            return self.pluginMostRight, "left", "right"     --right half on right side,
        end
    end

    return nil, nil
end

--create a copy of the arcana
local function createDummy(self, plugin, name)
    local dummy = self.dummy
    if not dummy then
        dummy = ArcanaPiece:New("dummy", plugin.obj, plugin.settings, Arcana.db.profile)
        dummy:SetParent(self)
        dummy.name = "dummy"
        dummy:SetAlpha(0.5)
        dummy.bar = plugin.bar
        self.dummy = dummy
    end
    dummy:Show()
    dummy:SetWidth(plugin:GetWidth())
    dummy:SetHeight(plugin:GetHeight())

    dummy.settings.index = plugin.settings.index
    dummy.settings.align = plugin.settings.align
    self.pluginList[name] = dummy --replace original with dummy to free the original
end

function Bar:UpdateDragPlugin()
    local plugin, side, align = self:GetPluginAtCursor()
    self.pointer = self.pointer or Arcana:GetPointer(self)
    local pointer = self.pointer

    if plugin then
        pointer.align = plugin.settings.align    --align
        local offset = 0.5
        if plugin.settings.align == "right" then -- the right
            offset = -0.5
        end
        if side == "left" then
            pointer.index = plugin.settings.index - offset
            pointer:SetPoint("TOPLEFT", plugin, 0, 0)
        else
            pointer.index = plugin.settings.index + offset
            pointer:SetPoint("TOPLEFT", plugin, "TOPRIGHT", 0, 0)
            --pointer:SetPoint("TOPRIGHT",plugin,-5,0)
        end
    else
        if align == "left" then
            pointer.index = 0.5
            pointer.align = "left"
            pointer:SetPoint("TOPLEFT", self, 6, -1)
        elseif align == "right" then
            pointer.index = 0.5
            pointer.align = "right"
            pointer:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
            --pointer:SetPoint("TOPRIGHT",plugin,-5,0)
        else
            pointer.index = 1
            pointer.align = "center"
            --pointer:SetPoint("CENTER",self,"CENTER",0,0)
            pointer:SetPoint("TOPLEFT", self, self:GetWidth() / 2, 0)
        end
    end
    pointer:Show()
end

function Bar:Drag(name)
    local plugin = self.pluginList[name]
    plugin:SetAlpha(0.8)
    --if plugin.OnLeave then plugin:OnLeave() end
    createDummy(self, plugin, name)
    self.pointer = Arcana:GetPointer(self)
    self:UpdateBar(true)
end

function Bar:Drop(plugin, pos)
    local settings = plugin.settings
    settings.index = self.pointer.index
    settings.align = self.pointer.align
    plugin:SetAlpha(1)
    self.pointer:Hide()

    local oldbar = Arcana:GetBar(settings.barName)
    --check if droped from different bar
    if oldbar == self then -- same bar
        self.dummy:Hide()
        self.dummy = nil
        self.pluginList[plugin.obj.name] = plugin --replace dummy with original
    else                                          -- cross bars
        oldbar.pluginList[plugin.obj.name] = nil  --remove from oldbar
        oldbar.dummy:Hide()
        oldbar.dummy = nil
        oldbar:UpdateBar(true)
        self:AddArcanaPiece(plugin, plugin.obj.name)
    end
    self:UpdateBar(true)
end

function Bar:LoseFocus(name)
    self.pointer:Hide()
end

function Bar:GetFocus(name)
    local plugin = Arcana:GetPlugin(name)
    Arcana:GetPointer(self)
end

-- rearange all plugins pluginList in a given bar
-- called only when plugins are added, removed or moved
function Bar:UpdateBar(updateindex)
    local plugins = self.pluginList
    -- set left plugins
    local tempList = SortList(plugins, "left")
    self.pluginMostLeft = tempList[#tempList] and tempList[#tempList][1]

    local yoff = 0
    local relative = nil
    for i, v in ipairs(tempList) do
        local plugin = v[1]
        plugin:ClearAllPoints()
        if (relative) then
            plugin:SetPoint("TOPLEFT", relative, "TOPRIGHT", 0, 0)
            plugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
            plugin:SetPoint("TOP", self, 0, 0)
        else
            plugin:SetPoint("TOPLEFT", self, 6, yoff)
            plugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
            plugin:SetPoint("TOP", self, 0, 0)
        end
        if updateindex then
            plugin.settings.index = i
        end
        relative = plugin
    end

    -- set center plugins
    self.listCenter = SortList(plugins, "center")
    local listCenter = self.listCenter
    self.pluginCenterLeft = listCenter[1] and listCenter[1][1]
    self.pluginCenterRight = listCenter[#listCenter] and listCenter[#listCenter][1]

    local centerIndex = math.ceil(#listCenter / 2)
    local v = listCenter[centerIndex]
    local relative = nil

    if v then
        local centerPlugin = v[1]
        self.centerPlugin = centerPlugin
        local last = nil
        if centerPlugin then
            if mod(#listCenter, 2) > 0 then --uneven
                centerPlugin:ClearAllPoints()
                centerPlugin:SetPoint("CENTER", self, 0, yoff)
                centerPlugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
            else --even
                centerPlugin:ClearAllPoints()
                centerPlugin:SetPoint("RIGHT", self, "CENTER", 0, yoff)
                centerPlugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
            end
            local relativeR = centerPlugin

            for i, v in ipairs(listCenter) do
                local plugin = v[1]
                if i <= centerIndex then
                    if last then
                        last:ClearAllPoints()
                        last:SetPoint("TOPRIGHT", plugin, "TOPLEFT", 0, 0)
                        last:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
                    end
                    last = plugin
                elseif i > centerIndex then
                    plugin:ClearAllPoints()
                    plugin:SetPoint("TOPLEFT", relativeR, "TOPRIGHT", 0, 0)
                    plugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
                    relativeR = plugin
                end
                if updateindex then
                    plugin.settings.index = i
                end
            end
        end
        self:UpdateCenter()
    end

    -- set right plugins
    tempList = SortList(plugins, "right")
    self.pluginMostRight = tempList[#tempList] and tempList[#tempList][1]

    relative = nil
    for i, v in ipairs(tempList) do
        local plugin = v[1]
        plugin:ClearAllPoints()
        if (relative) then
            plugin:SetPoint("TOPRIGHT", relative, "TOPLEFT", 0, 0)
            plugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
            --list them downwards
            --plugin:SetPoint("TOPLEFT",relative,"BOTTOMLEFT", 0,0)
        else
            plugin:SetPoint("TOPRIGHT", self, 0, yoff)
            plugin:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
        end
        if updateindex then
            plugin.settings.index = i
        end
        relative = plugin
    end
end

function Bar:UpdateCenter()
    if true then return end
    local centerPlugin = self.centerPlugin --the plugin the others are aligend to
    if not centerPlugin or not db.adjustCenter then return end

    local totalwidth = 0
    local centerPluginPosX = 0
    --get the total width of all center plugin's and the relative position of the plugin they are aligend to
    local listCenter = self.listCenter
    for i, v in ipairs(listCenter) do
        local plugin = v[1]
        if i == math.ceil(#listCenter / 2) then
            centerPluginPosX = totalwidth
        end
        totalwidth = totalwidth + plugin:GetWidth()
    end
    local deltaX = totalwidth / 2 - centerPluginPosX
    centerPlugin:ClearAllPoints()
    centerPlugin:SetPoint("LEFT", self, "CENTER", -deltaX, 0)
    centerPlugin:SetPoint("BOTTOM", self, "BOTTOM", -deltaX, 0)
end
