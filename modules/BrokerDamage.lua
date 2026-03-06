local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
local addonName = "QDB-DamageMeter"
local path = "Interface\\AddOns\\Arcana\\modules\\BrokerDamage"

local lastTop2Text = "DM: —"

local function OnClick(self, button, ...)
    if button == "RightButton" then
        --dataobj:OpenOptions()
    else
        local current = GetCVarBool("damageMeterEnabled")
        SetCVar("damageMeterEnabled", current and "0" or "1")
        --ToggleHide()
    end
end

local dataobj = ldb:NewDataObject(addonName, {
    type    = "data source",
    icon    = path .. "green.tga",
    label   = "Damage Meter",
    text    = "Damage Meter",
    OnClick = OnClick
})
local obj = dataobj

local function FormatAmount(n)
    if type(n) ~= "number" then return "0" end

    if n >= 1000 and AbbreviateNumbers then
        return AbbreviateNumbers(n)
    end

    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(math.floor(n + 0.5))
    end

    return tostring(math.floor(n + 0.5))
end

-- Cache structure:
-- cache[sessionType][meterType] = { updatedAt = time(), rows = { {name, classFilename, ps, total}, ... } }
local cache = {}

local function EnsureCache()
    if not cache then cache = {} end
end

local function ShortName(name)
    name = (name or ""):match("^[^-]+") or (name or "")
    return name
end

local function SuperShortName(name)
    if not name then return "?" end
    return string.sub(name, 1, 3)
end

local function ClassRGB(classFilename)
    local c = classFilename and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function ClassHex(classFilename)
    local c = classFilename and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
    if not c then return "ffffffff" end
    return string.format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

local GREEN = "|cff00ff00"
local RESET = "|r"
local WHITE = "|cffffffff"

local function ReadSessionRows(sessionType, meterType)
    -- IMPORTANT: do not call in combat (API is secret/blocked in combat in some builds)
    if InCombatLockdown and InCombatLockdown() then return nil end
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then return nil end

    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or not session.combatSources then return {} end

    local rows = {}
    for _, s in ipairs(session.combatSources) do
        rows[#rows + 1] = {
            name = s.name,
            classFilename = s.classFilename,
            ps = tonumber(s.amountPerSecond) or 0,
            total = tonumber(s.totalAmount) or 0,
        }
    end

    table.sort(rows, function(a, b)
        if a.ps ~= b.ps then return a.ps > b.ps end
        return a.total > b.total
    end)

    return rows
end

local function CacheSet(sessionType, meterType, rows)
    EnsureCache()
    cache[sessionType] = cache[sessionType] or {}
    cache[sessionType][meterType] = {
        updatedAt = time and time() or 0,
        rows = rows or {},
    }
end

local function CacheGet(sessionType, meterType)
    return cache
        and cache[sessionType]
        and cache[sessionType][meterType]
        and cache[sessionType][meterType].rows
end

local function RefreshCaches()
    if InCombatLockdown and InCombatLockdown() then return end
    if not Enum or not Enum.DamageMeterSessionType or not Enum.DamageMeterType then return end

    local sessions = {
        Enum.DamageMeterSessionType.Current,
        Enum.DamageMeterSessionType.Overall,
    }
    local meters = {
        Enum.DamageMeterType.DamageDone,
        Enum.DamageMeterType.HealingDone,
    }

    for _, st in ipairs(sessions) do
        for _, mt in ipairs(meters) do
            local rows = ReadSessionRows(st, mt)
            if rows then
                CacheSet(st, mt, rows)
            end
        end
    end
end

-- --- live-or-cached rows ---------------------------------------------------
-- Assumes you have:
--   ReadSessionRows(sessionType, meterType) -> rows {name, classFilename, ps, total}
--   CacheGet(sessionType, meterType)
--   CacheSet(sessionType, meterType, rows)

local function GetRowsLiveOrCached(sessionType, meterType)
    if InCombatLockdown and InCombatLockdown() then
        return CacheGet(sessionType, meterType) or {}
    end

    local rows = ReadSessionRows(sessionType, meterType) or {}
    CacheSet(sessionType, meterType, rows)
    return rows
end

-- --- the 2-column tooltip block -------------------------------------------

local function AddDmgHealTwoColumn(tooltip, title, sessionType)
    tooltip:AddLine(title)
    tooltip:AddLine(" ")

    local dmg = GetRowsLiveOrCached(sessionType, Enum.DamageMeterType.DamageDone)
    local heal = GetRowsLiveOrCached(sessionType, Enum.DamageMeterType.HealingDone)

    if (#dmg == 0) and (#heal == 0) then
        tooltip:AddLine("  (no data)")
        return
    end

    -- sort damage list by DPS desc, then Total desc
    table.sort(dmg, function(a, b)
        local ad, bd = (a.ps or 0), (b.ps or 0)
        if ad ~= bd then return ad > bd end
        return (a.total or 0) > (b.total or 0)
    end)

    -- sort healing list by HPS desc, then Total desc
    table.sort(heal, function(a, b)
        local ah, bh = (a.ps or 0), (b.ps or 0)
        if ah ~= bh then return ah > bh end
        return (a.total or 0) > (b.total or 0)
    end)

    tooltip:AddDoubleLine(
        "  DMG (PS/Total)",
        "HEAL (PS/Total)",
        1, 1, 1,
        1, 1, 1
    )

    local n = math.max(#dmg, #heal)
    for i = 1, n do
        local d = dmg[i]
        local h = heal[i]

        -- Left side (damage) uses AddDoubleLine left RGB to class-color the whole left string
        local leftText = " "
        if d then
            local name = ShortName(d.name)
            local hex = ClassHex(d.classFilename)

            leftText = string.format(
                "  %d) %s%s|r %s/%s",
                i,
                "|c" .. hex, name,
                FormatAmount(d.ps or 0),
                FormatAmount(d.total or 0)
            )
        end

        -- Right side (healing): class-color the name + make numbers green using inline codes
        local rightText = " "
        if h then
            local name = ShortName(h.name)
            local hex = ClassHex(h.classFilename)
            rightText = string.format("  %d) |c%s%s|r %s%s/%s%s",
                i,
                hex, name,
                GREEN, FormatAmount(h.ps or 0), FormatAmount(h.total or 0), RESET
            )
        end

        tooltip:AddDoubleLine(leftText, rightText, 1, 1, 1, 1, 1, 1)
    end
end

obj.OnTooltipShow = function(tooltip)
    tooltip:AddLine("Midnight Damage Meter")
    tooltip:AddLine(" ")

    if InCombatLockdown and InCombatLockdown() then
        tooltip:AddLine("|cffffaaaaIn combat: showing cached values|r")
        tooltip:AddLine(" ")
    end

    AddDmgHealTwoColumn(tooltip, "Current", Enum.DamageMeterSessionType.Current)
    tooltip:AddLine(" ")
    AddDmgHealTwoColumn(tooltip, "Overall", Enum.DamageMeterSessionType.Overall)

    tooltip:AddLine(" ")
    tooltip:AddLine("|cffffffffLeft-click:|r Toggle meter")
end

local function GetTopPlayer(sessionType, meterType)
    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or not session.combatSources then return end

    local best

    for _, s in ipairs(session.combatSources) do
        local amount = s.totalAmount or s.amountPerSecond
        if amount and amount > 0 then
            if not best or amount > best.amount then
                best = { name = s.name, amount = amount }
            end
        end
    end

    return best
end

local function UpdateBrokerText()
    if InCombatLockdown and InCombatLockdown() then
        obj.text = lastTop2Text .. " (frozen)"
        return
    end

    local sessionType = Enum.DamageMeterSessionType.Current

    local dmg = GetTopPlayer(sessionType, Enum.DamageMeterType.DamageDone)
    local heal = GetTopPlayer(sessionType, Enum.DamageMeterType.HealingDone)

    local text = NORMAL_FONT_COLOR:WrapTextInColorCode("DM: ")

    if dmg then
        text = text .. SuperShortName(dmg.name) .. " " .. FormatAmount(dmg.amount)
    end

    --" • HL "
    if heal then
        text = text ..
            NORMAL_FONT_COLOR:WrapTextInColorCode(" HL: ") ..
            SuperShortName(heal.name) .. " " .. FormatAmount(heal.amount)
    end

    lastTop2Text = text
    obj.text = text
end

-- Update on relevant events
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- inital set cache
f:RegisterEvent("PLAYER_REGEN_ENABLED")  -- leaving combat (safe time to query)
---@diagnostic disable-next-line: param-type-mismatch
f:RegisterEvent("DAMAGE_METER_RESET")    --query
f:SetScript("OnEvent", function()
    -- Only refresh on these when out of combat
    if not (InCombatLockdown and InCombatLockdown()) then
        RefreshCaches()
    end
    UpdateBrokerText()
end)

-- Initial
UpdateBrokerText()
