local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local Jostle2 = ChocolateBar.Jostle2
local bottomFrames = {}
local topFrames = {}
Jostle2.hooks = {}
local debug = ChocolateBar and ChocolateBar.Debug or function() end
local Jostle2Update = CreateFrame("Frame")
local _G, pairs = _G, pairs

local blizzardFrames = {
	'MicroButtonAndBagsBar',
	'TutorialFrameParent',
	'FramerateLabel',
	'DurabilityFrame',
	'StatusTrackingBarManager',
	'MinimapCluster',
	'PlayerFrame',
	'TargetFrame',
}

local editModeFrames = {
	MinimapCluster,
	PlayerFrame,
	TargetFrame,
}


--[[

/dump MinimapCluster:IsUserPlaced()
/dump MinimapCluster:GetTop() * UIParent:GetScale() --yes 767.99993179109
/dump UIParent:GetTop() * UIParent:GetScale() == MinimapCluster:GetTop() * UIParent:GetScale()

/dump UIParent:GetTop() * UIParent:GetScale() == PlayerFrame:GetTop() * UIParent:GetScale()

/dump MinimapCluster:GetScale()

04] Dump: value=MinimapCluster:GetTop()
[02:41:04] [1]=1054.875
[02:41:12] ChocolateBar debug: ChocolateBar Refresh Jostle2
[02:41:22] Edit Mode layout 'Modern' applied
[02:41:22] ChocolateBar debug: ChocolateBar Refresh Jostle2
[02:41:27] Dump: value=MinimapCluster:GetTop()
[02:41:27] [1]=1079.9998779297
[02:41:32] ChocolateBar debug: ChocolateBar Refresh Jostle2
-- after changing ui scalde
[02:43:00] Dump: value=MinimapCluster:GetTop()
[02:43:00] [1]=903.52941894531
UIParent:GetScale()

 GameTimeFrame
[03:48:06] Dump: value=GameTimeFrame:Hide()
[03:48:06] empty result
[03:48:18] TimeManagerClockButton


/dump for key, child in pairs(MinimapCluster) do DEFAULT_CHAT_FRAME:AddMessage(child:GetName()); end

/dump PlayerFrame:GetTop() * UIParent:GetScale()
/dump MinimapCluster:GetTop() * UIParent:GetScale()
]]

local blizzardFramesData = {}

local start = GetTime()
local nextTime = 0
local fullyInitted = false
local Jostle2Frame = CreateFrame("Frame")

if ChocolateBar:IsRetail() then
	Jostle2.Frame  = Jostle2Frame
	Jostle2Frame:SetScript("OnUpdate", function(this, elapsed)
		local now = GetTime()
		if now - start >= 3 then
			fullyInitted = true
			for k,v in pairs(blizzardFramesData) do
				blizzardFramesData[k] = nil
			end
			this:SetScript("OnUpdate", function(this, elapsed)
				if GetTime() >= nextTime then
					Jostle2:Refresh()
					--this:Hide()
				end
			end)
		end
	end)

	function Jostle2Frame:Schedule(time)
		time = time or 0
		nextTime = GetTime() + time
		self:Show()
	end

	Jostle2Frame:UnregisterAllEvents()
	Jostle2Frame:SetScript("OnEvent", function(this, event, ...)
		return Jostle2[event](Jostle2, ...)
	end)

	Jostle2Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Jostle2:PLAYER_ENTERING_WORLD()
	self:Refresh(BuffFrame, PlayerFrame, TargetFrame, MainMenuBar)
end

local function GetScreenTop()
	local bottom = GetScreenHeight()
	for _,frame in pairs(topFrames) do
		if frame.IsShown and frame:IsShown() and frame.GetBottom and frame:GetBottom() and frame:GetBottom() < bottom then
			bottom = frame:GetBottom()
		end
	end
	return bottom
end

local function GetScreenBottom()
	local top = 0
	local isBottomAdjusting = false
	for _,frame in pairs(bottomFrames) do
		if frame.IsShown and frame:IsShown() and frame.GetTop and frame:GetTop() and frame:GetTop() > top then
			top = frame:GetTop()
			isBottomAdjusting = true
		end
	end
	return top
end

local function isMinimapDefaultPosition()
	return UIParent:GetTop() * UIParent:GetScale() == frame:GetTop() * UIParent:GetScale()
end

local function getTopBarsHeight()
	--[[
	local height = 0
	for _,frame in pairs(topFrames) do
		if frame.IsShown and frame:IsShown() then
			height = height + frame:GetHeight()
			ChocolateBar:Debug("height", height)
		end
	end
	return height
	--]]
	return (GetScreenHeight() - GetScreenTop()) * UIParent:GetScale()
end

local function getFrameOffsetTop(frame)
	return UIParent:GetTop() * UIParent:GetScale() - frame:GetTop() * UIParent:GetScale() 
end

local function isFrameBelowTopBars(frame)
    ChocolateBar.Debug("isFrameBelowTopBars", frame:GetName())
    ChocolateBar.Debug("isFrameBelowTopBars", getFrameOffsetTop(frame) , getTopBarsHeight())
    ChocolateBar.Debug("isFrameBelowTopBars", getFrameOffsetTop(frame) > getTopBarsHeight() )
   
	return getFrameOffsetTop(frame) > getTopBarsHeight()
	--765
end


function Jostle2:RegisterBottom(frame)
	if frame and not bottomFrames[frame] then
		bottomFrames[frame] = frame
		Jostle2Frame:Schedule()
	end
end

function Jostle2:RegisterTop(frame)
	if frame and not topFrames[frame] then
		topFrames[frame] = frame
		Jostle2Frame:Schedule()
	end
end

function Jostle2:Unregister(frame)
	if frame and topFrames[frame] then
		topFrames[frame] = nil
	elseif frame and bottomFrames[frame] then
		bottomFrames[frame] = nil
		Jostle2Frame:Schedule()
	end
end

if not Jostle2.hooks.UIParent_ManageFramePositions then
	Jostle2.hooks.UIParent_ManageFramePositions = true
	hooksecurefunc("UIParent_ManageFramePositions", function()
		if Jostle2.UIParent_ManageFramePositions then
			Jostle2:UIParent_ManageFramePositions()
		end
	end)
end

function Jostle2:UIParent_ManageFramePositions()
	--ChocolateBar:Debug("UIParent_ManageFramePositions")
	--self:Refresh(MinimapCluster)
end

if not Jostle2.hooks.EditModeManagerFrame_OnHide then
	Jostle2.hooks.EditModeManagerFrame_OnHide = true
	hooksecurefunc(EditModeManagerFrame,"Hide",  function()
		if Jostle2.EditModeManagerFrame_OnHide then
			Jostle2:EditModeManagerFrame_OnHide()
		end
	end)
end

function Jostle2:EditModeManagerFrame_OnHide()
	ChocolateBar:Debug("EditModeManagerFrame_OnHide")
	self:Refresh(MinimapCluster)
end

local tmp = {}
local queue = {}
local inCombat = false
function Jostle2:ProcessQueue()
	if not inCombat and HasFullControl() then
		for k in pairs(queue) do
			self:Refresh(k)
			queue[k] = nil
		end
	end
end
function Jostle2:PLAYER_CONTROL_GAINED()
	self:ProcessQueue()
end

local function isClose(alpha, bravo)
	return math.abs(alpha - bravo) < 0.1
end


function Jostle2:Refresh(...)
	--ChocolateBar:Debug("Refresh Jostle2")
	if not fullyInitted then
		return
	end

	--hocolateBar:Debug("gettop", GetScreenTop() - GetScreenHeight())

	-- do not touch player placed frames
	--for _, frame in ipairs(editModeFrames) do
	--	ChocolateBar:Debug("frame", frame)
	--	if isDefaultPosition(frame) then
	--		ChocolateBar:Debug(frame:GetName(), " is edited = ", isUserPlacedEditMode(frame))
	--		return
	--	end
	--end

	local screenHeight = GetScreenHeight()
	local topOffset = GetScreenTop() or screenHeight
	local bottomOffset = GetScreenBottom() or 0
	if topOffset ~= screenHeight or bottomOffset ~= 0 then
		Jostle2Frame:Schedule(10)
	end

	local frames
	-- check for frames in parameter list
	if select('#', ...) >= 1 then
		for k in pairs(tmp) do
			tmp[k] = nil
			ChocolateBar:Debug(k)
		end
		for i = 1, select('#', ...) do
			tmp[i] = select(i, ...)
		end
		frames = tmp
		
		for _,frame in ipairs(frames) do
			--ChocolateBar:Debug("maunall update",frame:GetName())
		end
	else
		frames = blizzardFrames
	end

	if inCombat or not HasFullControl() and not UnitHasVehicleUI("player") then
		for _,frame in ipairs(frames) do
			if type(frame) == "string" then
				frame = _G[frame]
			end
			if frame then
				queue[frame] = true
			end
		end
		return
	end

	local screenHeight = GetScreenHeight()
	-- setup blizzardFramesData
	for _,frame in ipairs(frames) do
		if type(frame) == "string" then
			frame = _G[frame]
		end

		local framescale = frame and frame.GetScale and frame:GetScale() or 1

		if frame and not blizzardFramesData[frame] and frame.GetTop and frame:GetCenter() and select(2, frame:GetCenter()) then
			if select(2, frame:GetCenter()) <= screenHeight / 2 or frame == MultiBarRight then
				blizzardFramesData[frame] = {y = frame:GetBottom(), top = false}
			else
				blizzardFramesData[frame] = {y = frame:GetTop() - screenHeight / framescale, top = true}
			end
		end
	end

	--ChocolateBar:Debug("setting frame 1")

	-- move the blizzardFrames 
	for _,frame in ipairs(frames) do

		if type(frame) == "string" then
			frame = _G[frame]
		end

        -- quick fix for not touching the top frames if they are not anchored at the top
		--if frame == MinimapCluster and isMinimapUserPlaced then
		--	return
		--end
		if frame == (PlayerFrame or TargetFrame or MinimapCluster) and isFrameBelowTopBars(frame) then
			return
		end

		--ChocolateBar:Debug("setting frame 2")

		local framescale = frame and frame.GetScale and frame:GetScale() or 1

		if ((frame and frame.IsUserPlaced and not frame:IsUserPlaced()) or ((frame == DEFAULT_CHAT_FRAME or frame == ChatFrame2) and SIMPLE_CHAT == "1") or frame == FramerateLabel) and (frame ~= ChatFrame2 or SIMPLE_CHAT == "1") then
			--ChocolateBar:Debug("setting frame 3")
			local frameData = blizzardFramesData[frame]
			if (select(2, frame:GetPoint(1)) ~= UIParent and select(2, frame:GetPoint(1)) ~= WorldFrame) then
				-- do nothing
				--ChocolateBar:Debug("setting frame 3.1")
			elseif bottomOffset == 0 and (frame == FramerateLabel) then
				-- do nothing
				--ChocolateBar:Debug("setting frame 3.2")
			elseif frame == DurabilityFrame and DurabilityFrame:IsShown() and (DurabilityFrame:GetLeft() > GetScreenWidth() or DurabilityFrame:GetRight() < 0 or DurabilityFrame:GetBottom() > GetScreenHeight() or DurabilityFrame:GetTop() < 0) then
				DurabilityFrame:Hide()
				--ChocolateBar:Debug("setting frame 3.3")
			elseif frame == FramerateLabel and ((frameData.lastX and not isClose(frameData.lastX, frame:GetLeft())) or not isClose(WorldFrame:GetHeight() * WorldFrame:GetScale(), UIParent:GetHeight() * UIParent:GetScale()))  then
				-- do nothing
				--ChocolateBar:Debug("setting frame 3.4")
			elseif frame == FramerateLabel or frame == MinimapCluster or frame == DurabilityFrame or not (frameData.lastScale and frame.GetScale and frameData.lastScale == frame:GetScale()) or not (frameData.lastX and frameData.lastY and (not isClose(frameData.lastX, frame:GetLeft()) or not isClose(frameData.lastY, frame:GetTop()))) then
				local anchor
				local anchorAlt
				local width, height = GetScreenWidth(), GetScreenHeight()
				local x

				--hocolateBar:Debug("setting frame 4")

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
						offset = ( topOffset - height ) / framescale
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
						--blizzardFramesData[frame].lastX = frame:GetLeft()
						--blizzardFramesData[frame].lastY = frame:GetTop()
						--blizzardFramesData[frame].lastScale = framescale
						--ChocolateBar:Debug("setting frame 5 ",frame:GetName())
					end
				end
			end
		end
	end
end
