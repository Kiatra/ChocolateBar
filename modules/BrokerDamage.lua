-- globals
local LibStub = LibStub
local LE_EXPANSION_LEVEL_CURRENT = _G.LE_EXPANSION_LEVEL_CURRENT
local DEFAULT_CHAT_FRAME, RAID_CLASS_COLORS = DEFAULT_CHAT_FRAME, RAID_CLASS_COLORS
local AbbreviateNumbers, InCombatLockdown, DamageMeter = AbbreviateNumbers, InCombatLockdown, DamageMeter
local BreakUpLargeNumbers, GameTooltip, SetCVar = BreakUpLargeNumbers, GameTooltip, SetCVar
local C_DamageMeter, time, Enum, NORMAL_FONT_COLOR = C_DamageMeter, time, Enum, NORMAL_FONT_COLOR
local CreateFrame = CreateFrame
----
local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibQTip = LibStub('LibQTip-1.0')

local dataobj, tooltip, db
local color = true
local _
local addonName = "Damage"
local path = "Interface\\AddOns\\ChocolateBar\\modules\\BrokerDamage"

local function Debug(...)
    --@debug@
    local s = addonName .. " Debug:"
    for i = 1, _G.select("#", ...) do
        local x = _G.select(i, ...)
        s = _G.strjoin(" ", s, _G.tostring(x))
    end
    DEFAULT_CHAT_FRAME:AddMessage(s)
    --@end-debug@
end

local function OnClick(self, button, ...)
    if button == "RightButton" then
        --dataobj:OpenOptions()
    else
        local current = GetCVarBool("damageMeterEnabled")
        SetCVar("damageMeterEnabled", current and "0" or "1")
        --ToggleHide()
    end
end

dataobj = ldb:NewDataObject(addonName, {
    type    = "data source",
    icon    = path .. "green.tga",
    label   = "Broker Damage",
    text    = "Broker Damage",
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

local function GetClassColorRGB(classFilename)
    local c = classFilename and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

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

local function AddMeterBlock(tooltip, title, sessionType, meterType, valueR, valueG, valueB)
    tooltip:AddLine(title)

    local rows
    if InCombatLockdown and InCombatLockdown() then
        rows = CacheGet(sessionType, meterType)
    else
        rows = ReadSessionRows(sessionType, meterType)
        if rows then
            CacheSet(sessionType, meterType, rows) -- keep cache fresh even out of combat
        end
    end

    if not rows or #rows == 0 then
        tooltip:AddLine("  (no data)")
        return
    end

    tooltip:AddDoubleLine("  Player", "PS      Total", 1, 1, 1, 1, 1, 1)
    valueR, valueG, valueB = valueR or 1, valueG or 1, valueB or 1

    for _, r in ipairs(rows) do
        local nr, ng, nb = GetClassColorRGB(r.classFilename)
        tooltip:AddDoubleLine(
            "  " .. ShortName(r.name),
            string.format("%s  %s", FormatAmount(r.ps), FormatAmount(r.total)),
            nr, ng, nb,
            valueR, valueG, valueB
        )
    end
end

local function AddSessionSection(tooltip, label, sessionType)
    tooltip:AddLine(label)
    tooltip:AddLine(" ")

    AddMeterBlock(
        tooltip,
        "Damage (DPS + Total)",
        sessionType,
        Enum.DamageMeterType.DamageDone,
        1, 1, 1 -- numbers white
    )

    tooltip:AddLine(" ")

    AddMeterBlock(
        tooltip,
        "Healing (HPS + Total)",
        sessionType,
        Enum.DamageMeterType.HealingDone,
        0, 1, 0 -- numbers green
    )

    tooltip:AddLine(" ")
end

obj.OnTooltipShow = function(tooltip)
    tooltip:AddLine("Midnight Damage Meter")
    tooltip:AddLine(" ")

    if not Enum or not Enum.DamageMeterSessionType or not Enum.DamageMeterType then
        tooltip:AddLine("Damage meter enums not available.")
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        tooltip:AddLine("|cffffaaaaIn combat: showing cached values|r")
        tooltip:AddLine(" ")
    end

    AddSessionSection(tooltip, "Current", Enum.DamageMeterSessionType.Current)
    AddSessionSection(tooltip, "Overall", Enum.DamageMeterSessionType.Overall)

    tooltip:AddLine("|cffffffffLeft-click:|r Toggle meter")
end

local ev = CreateFrame("Frame")
-- Damage meter events
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED") -- leaving combat (safe time to read)
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("DAMAGE_METER_RESET")

ev:SetScript("OnEvent", function(_, event)
    -- Only refresh on these when out of combat
    if not (InCombatLockdown and InCombatLockdown()) then
        RefreshCaches()
    end
    if hideDamageMeter then
        DamageMeter:Hide()
    end
end)

local function ShouldUsePerSecond(damageMeterType)
    if not Enum or not Enum.DamageMeterType then return false end
    return damageMeterType == Enum.DamageMeterType.DPS
        or damageMeterType == Enum.DamageMeterType.HPS
end

local function GetTopN(sessionType, damageMeterType, n)
    n = n or 2

    if InCombatLockdown and InCombatLockdown() then
        -- C_DamageMeter session fetch is SecretWhenInCombat.
        return nil, "combat"
    end

    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then
        return nil, "noapi"
    end

    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, damageMeterType)
    if not session or not session.combatSources then
        return nil, "nosession"
    end

    local usePS = ShouldUsePerSecond(damageMeterType)

    local sources = {}
    for _, s in ipairs(session.combatSources) do
        local amount = usePS and s.amountPerSecond or s.totalAmount
        if type(amount) == "number" and amount > 0 then
            table.insert(sources, {
                name = s.name,
                amount = amount,
                isLocalPlayer = s.isLocalPlayer,
                classFilename = s.classFilename,
            })
        end
    end

    table.sort(sources, function(a, b) return a.amount > b.amount end)

    local top = {}
    for i = 1, math.min(n, #sources) do
        top[i] = sources[i]
    end

    return top
end

local function UpdateBrokerTextOld()
    -- Pick what you want to show “top 2” of:
    -- Damage Done overall is a sensible default.
    local sessionType = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Overall
    local meterType   = Enum and Enum.DamageMeterType and Enum.DamageMeterType.DamageDone

    if not sessionType or not meterType then
        dataobj.text = "Damage Meter"
        return
    end

    local top, reason = GetTopN(sessionType, meterType, 2)
    if not top then
        if reason == "combat" then
            dataobj.text = "DM: (in combat)"
        else
            dataobj.text = "Damage Meter"
        end
        return
    end

    local p1 = top[1]
    local p2 = top[2]

    if p1 and p1 then
        dataobj.text = string.format("DM: 1) %s %s  2) %s %s",
            p1.name or "?", FormatAmount(p1.amount),
            p2.name or "?", FormatAmount(p2.amount)
        )
    elseif p1 then
        dataobj.text = string.format("DM: 1) %s %s", p1.name or "?", FormatAmount(p1.amount))
    else
        dataobj.text = "DM: —"
    end
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

local lastTop2Text = "DM: —"

local function ShortName(name)
    if not name then return "?" end
    return string.sub(name, 1, 3)
end

local function RemoveRealm(name)
    name = (name or ""):match("^[^-]+") or (name or "")
    return name
end

local function GetSessionSources(sessionType, meterType)
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then return nil end

    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or not session.combatSources then return nil end
    return session.combatSources
end

local function AddMeterBlock(tooltip, title, sources)
    tooltip:AddLine(title)

    if not sources or #sources == 0 then
        tooltip:AddLine("  (no data)")
        return
    end

    -- Copy + sort by per-second desc, then total desc
    local rows = {}
    for _, s in ipairs(sources) do
        local ps = tonumber(s.amountPerSecond) or 0
        local total = tonumber(s.totalAmount) or 0
        -- If you want to exclude 0s, uncomment:
        -- if ps > 0 or total > 0 then
        rows[#rows + 1] = { name = s.name, ps = ps, total = total }
        -- end
    end

    table.sort(rows, function(a, b)
        if a.ps ~= b.ps then return a.ps > b.ps end
        return a.total > b.total
    end)

    -- Header
    tooltip:AddDoubleLine("  Player", "PS      Total", 1, 1, 1, 1, 1, 1)

    for _, r in ipairs(rows) do
        tooltip:AddDoubleLine(
            "  " .. ShortName(r.name),
            string.format("%7.1f  %d", r.ps, r.total),
            0.9, 0.9, 0.9,
            0.9, 0.9, 0.9
        )
    end
end

local function AddSessionSection(tooltip, label, sessionType)
    tooltip:AddLine(label)
    tooltip:AddLine(" ")

    -- Damage Done: DPS + Total
    local dmgSources = GetSessionSources(sessionType, Enum.DamageMeterType.DamageDone)
    AddMeterBlock(tooltip, "Damage Done (DPS + Total)", dmgSources)

    tooltip:AddLine(" ")

    -- Healing Done: HPS + Total
    local healSources = GetSessionSources(sessionType, Enum.DamageMeterType.HealingDone)
    AddMeterBlock(tooltip, "Healing Done (HPS + Total)", healSources)

    tooltip:AddLine(" ")
end

local function UpdateBrokerText3()
    -- if in combat, just show cached snapshot
    if InCombatLockdown and InCombatLockdown() then
        obj.text = lastTop2Text .. " (frozen)"
        return
    end

    -- Pick what you want to show “top 2” of:
    -- Damage Done overall is a sensible default.
    local sessionType = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Overall
    local meterType   = Enum and Enum.DamageMeterType and Enum.DamageMeterType.DamageDone
    local heal        = GetTopPlayer(sessionType, Enum.DamageMeterType.HealingDone)

    if not sessionType or not meterType then
        dataobj.text = "Damage Meter"
        return
    end

    local top, reason = GetTopN(sessionType, meterType, 2) -- this calls C_DamageMeter
    if not top then
        obj.text = "Damage Meter"
        return
    end

    -- build text (formatting optional)
    local a, b = top[1], top[2]
    local text
    if a and b then
        text = string.format(
            "DM: %s %s | %s %s",
            ShortName(a.name) or "?",
            FormatAmount(a.amount) or 0,
            ShortName(b.name) or "?",
            FormatAmount(b.amount) or 0
        )
    elseif a then
        text = string.format("DM: %s %s", a.name or "?", FormatAmount(a.amount) or 0)
    else
        text = "DM: —"
    end

    lastTop2Text = text
    obj.text = text
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
        text = text .. ShortName(dmg.name) .. " " .. FormatAmount(dmg.amount)
    end

    --" • HL "
    if heal then
        text = text ..
            NORMAL_FONT_COLOR:WrapTextInColorCode(" HL: ") .. ShortName(heal.name) .. " " .. FormatAmount(heal.amount)
    end

    lastTop2Text = text
    obj.text = text
end

-- Update on relevant events
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED") -- leaving combat (safe time to query)

-- These are documented damage-meter events
-- DAMAGE_METER_CURRENT_SESSION_UPDATED
-- DAMAGE_METER_COMBAT_SESSION_UPDATED
-- DAMAGE_METER_RESET
--f:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
--f:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
--f:RegisterEvent("DAMAGE_METER_RESET")

f:SetScript("OnEvent", function()
    UpdateBrokerText()
    --ToggleHide()
end)

-- Initial
UpdateBrokerText()
