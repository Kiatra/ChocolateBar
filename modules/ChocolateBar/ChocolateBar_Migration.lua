--migration to make WoW load ChocolateBarDB from ChocolateBar.lua under the SavedVariables folder.
--[[
local function HasStubMarker(db)
    return type(db) == "table"
        and type(db.profileKeys) == "table"
        and db.profileKeys["ChocolateBar.lua - FromStub"] == "Default"
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, addon)
    if addon == "ChocolateBar" or addon == "Arcana" then
        print("|cff88ccffChocolateBar Debug|r ADDON_LOADED:", addon)
        print("  ChocolateBarDB:", ChocolateBarDB)
        print("  HasStubMarker:", HasStubMarker(ChocolateBarDB))
    end
end)
]]
