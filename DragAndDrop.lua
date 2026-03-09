-- DragAndDrop by yess
-- this adds drag and drop support between bars/drop points for Arcana
local Arcana = LibStub("AceAddon-3.0"):GetAddon("Arcana")
local Drag = Arcana.Drag
local frameslist = {}
local DragUpdate = CreateFrame("Frame")
local GetCursorPosition, pairs = GetCursorPosition, pairs
local counter = 0
local delay = .1
local focus = nil
local pluginName

local function ChangeFocus(newfocus)
    if focus and focus.LoseFocus then
        focus:LoseFocus(pluginName)
    end
    newfocus:GetFocus(pluginName)
    focus = newfocus
end

local function MouseIsOver(frame)
    local x, y = GetCursorPosition();
    local s = frame:GetEffectiveScale();
    x, y = x / s, y / s;
    return ((x >= frame:GetLeft()) and (x <= frame:GetRight())
        and (y >= frame:GetBottom()) and (y <= frame:GetTop()));
end

local function GetFocus()
    for k, v in pairs(frameslist) do
        if MouseIsOver(v) then
            if focus ~= v then
                ChangeFocus(v)
            end
        end
    end
    if focus and focus.UpdateDragPlugin then
        focus:UpdateDragPlugin()
    end
    return focus
end

local function OnDragUpdate(frame, elapsed)
    counter = counter + elapsed
    if focus and counter >= delay then
        GetFocus()
        counter = 0
        focus:SetAlpha(1)
    end
end

function Drag:RegisterFrame(frame)
    local name = frame:GetName()
    if name and not frameslist[name] then
        frameslist[name] = frame
    end
end

function Drag:UnregisterFrame(frame)
    frameslist[frame:GetName()] = nil
end

function Drag:Start(bar, name, _)
    for k, v in pairs(frameslist) do
        v.dragshow = v:IsVisible()
        v:Show()
    end

    pluginName = name
    bar:Drag(name)
    focus = bar
    DragUpdate:SetScript("OnUpdate", OnDragUpdate)
end

function Drag:Stop(frame)
    for k, v in pairs(frameslist) do
        if not v.dragshow then
            v:Hide()
        end
    end
    DragUpdate:SetScript("OnUpdate", nil)
    if focus then focus:Drop(frame) end
end
