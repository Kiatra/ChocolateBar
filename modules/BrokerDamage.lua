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
local addonName = "QDB-DamageMeter"
local path = "Interface\\AddOns\\ChocolateBar\\modules\\BrokerDamage"

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
    label   = "QBA-Damage-Meter",
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
