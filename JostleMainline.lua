local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local Jostle = ChocolateBar.Jostle
local bottomFrames = {}
local topFrames = {}
Jostle.hooks = {}
local _G, pairs = _G, pairs
local UnitHasVehicleUI = UnitHasVehicleUI and UnitHasVehicleUI or function() end

local blizzardFrames = {
    'MicroButtonAndBagsBar',
    'TutorialFrameParent',
    'FramerateLabel',
    'DurabilityFrame',
    'StatusTrackingBarManager',
    'MinimapCluster',
    'BuffFrame'
}

local blizzardFramesData = {}

local start = GetTime()
local nextTime = 0
local fullyInitted = false
local JostleFrame = CreateFrame("Frame")

Jostle.Frame = JostleFrame
JostleFrame:SetScript("OnUpdate", function(this, elapsed)
    local now = GetTime()
    if now - start >= 3 then
        fullyInitted = true
        for k, _ in pairs(blizzardFramesData) do
            blizzardFramesData[k] = nil
        end
        this:SetScript("OnUpdate", function(this, elapsed)
            if GetTime() >= nextTime then
                Jostle:Refresh()
            end
        end)
    end
end)

---@diagnostic disable-next-line: inject-field
function JostleFrame:Schedule(time)
    time = time or 0
    nextTime = GetTime() + time
    self:Show()
end

JostleFrame:UnregisterAllEvents()


local function GetScreenTop()
    local bottom = GetScreenHeight()
    for _, frame in pairs(topFrames) do
        if frame.IsShown and frame:IsShown() and frame.GetBottom and frame:GetBottom() and frame:GetBottom() < bottom then
            bottom = frame:GetBottom()
        end
    end
    return bottom
end

local function GetScreenBottom()
    local top = 0
    local isBottomAdjusting = false
    for _, frame in pairs(bottomFrames) do
        if frame.IsShown and frame:IsShown() and frame.GetTop and frame:GetTop() and frame:GetTop() > top then
            top = frame:GetTop()
            isBottomAdjusting = true
        end
    end
    return top
end

local function isMinimapClusterUserPlaced()
    return not (UIParent:GetTop() * UIParent:GetScale() == MinimapCluster:GetTop() * UIParent:GetScale())
end

function Jostle:RegisterBottom(frame)
    if frame and not bottomFrames[frame] then
        bottomFrames[frame] = frame
        JostleFrame:Schedule()
    end
end

function Jostle:RegisterTop(frame)
    if frame and not topFrames[frame] then
        topFrames[frame] = frame
        ChocolateBar:Debug("RegisterTop:", frame and frame.GetName and frame:GetName() or "no name")
        JostleFrame:Schedule()
    end
end

function Jostle:Unregister(frame)
    if frame and topFrames[frame] then
        topFrames[frame] = nil
    elseif frame and bottomFrames[frame] then
        bottomFrames[frame] = nil
        JostleFrame:Schedule()
    end
end

local tmp = {}
local queue = {}
local inCombat = false
function Jostle:ProcessQueue()
    if not inCombat and HasFullControl() then
        for k in pairs(queue) do
            self:Refresh(k)
            queue[k] = nil
        end
    end
end

function Jostle:Refresh(...)
    if not fullyInitted then
        return
    end

    local screenHeight = GetScreenHeight()
    local topOffset = GetScreenTop() or screenHeight
    local bottomOffset = GetScreenBottom() or 0
    if topOffset ~= screenHeight or bottomOffset ~= 0 then
        JostleFrame:Schedule(10)
    end

    local frames
    -- check for frames in parameter list
    if select('#', ...) >= 1 then
        for k in pairs(tmp) do
            tmp[k] = nil
            --ChocolateBar:Debug(k)
        end
        for i = 1, select('#', ...) do
            tmp[i] = select(i, ...)
        end
        frames = tmp
    else
        frames = blizzardFrames
    end

    ---@diagnostic disable-next-line: redundant-parameter
    if inCombat or not HasFullControl() and not UnitHasVehicleUI("player") then
        for _, frame in ipairs(frames) do
            if type(frame) == "string" then
                frame = _G[frame]
            end
            if frame then
                queue[frame] = true
            end
        end
        return
    end

    -- setup blizzardFramesData
    for _, frame in ipairs(frames) do
        if type(frame) == "string" then
            frame = _G[frame]
        end

        local framescale = frame and frame.GetScale and frame:GetScale() or 1

        if frame and not blizzardFramesData[frame] and frame.GetTop and frame:GetCenter() and select(2, frame:GetCenter()) then
            if select(2, frame:GetCenter()) <= screenHeight / 2 or frame == MultiBarRight then
                blizzardFramesData[frame] = { y = frame:GetBottom(), top = false }
            else
                blizzardFramesData[frame] = { y = frame:GetTop() - screenHeight / framescale, top = true }
            end
        end
    end

    -- move the blizzardFrames
    for _, frame in ipairs(frames) do
        if type(frame) == "string" then
            frame = _G[frame]
        end

        if frame == MinimapCluster and isMinimapClusterUserPlaced() then
            return
        end

        local framescale = frame and frame.GetScale and frame:GetScale() or 1

        if frame then
            local anchor
            local anchorAlt
            local width, height = GetScreenWidth(), GetScreenHeight()
            local x

            if frame:GetRight() and frame:GetLeft() then
                local anchorFrame = UIParent
                if frame == GroupLootFrame1 or frame == FramerateLabel then
                    x = 0
                    anchor = ""
                elseif frame:GetRight() / framescale <= width / 2 then
                    x = frame:GetLeft() / framescale
                    anchor = "LEFT"
                else
                    x = frame:GetRight() - width / framescale
                    anchor = "RIGHT"
                end
                local y = blizzardFramesData[frame].y
                local offset = 0
                if blizzardFramesData[frame].top then
                    anchor = "TOP" .. anchor
                    offset = (topOffset - height) / framescale
                else
                    anchor = "BOTTOM" .. anchor
                    offset = bottomOffset / framescale
                end

                if frame == FramerateLabel then
                    anchorFrame = WorldFrame
                end

                if not InCombatLockdown() then
                    frame:ClearAllPoints()
                    frame:SetPoint(anchor, anchorFrame, anchorAlt or anchor, x, y + offset)
                end
            end
        end
    end
end
