--[[
Copyright 2009 Quaiche of Dragonblight

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

local L = setmetatable({
	-- ["Foo"] = "This is foo",
}, {__index=function(t,i) return i end})

local defaults = {
	inventory = {},
}
local db
local function Print(...) print("|cFF33FF99Rawr Profiler|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("RawrProfiler")
local function Debug(...) if debugf then debugRawrProfiler:AddMessage(string.join(", ", tostringall(...))) end end

--[[ Addon Declaration ]]
local RawrProfiler = CreateFrame("frame")
RawrProfiler:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
RawrProfiler:RegisterEvent("ADDON_LOADED")

function RawrProfiler:ADDON_LOADED(event, addon)
	if addon:lower() ~= "rawrprofiler" then return end

	RawrProfilerDB = setmetatable(RawrProfilerDB or {}, {__index = defaults})
	db = RawrProfilerDB

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new("RawrProfiler", "RawrProfiler") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function RawrProfiler:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	-- Do anything you need to do after the player has entered the world
	self:ScanAll()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function RawrProfiler:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	-- Do anything you need to do as the player logs out
end

function RawrProfiler:ScanAll()
	self:ScanInventory()
end

--[[ Scans currently equipped items ]]
function RawrProfiler:ScanInventory()
	local slots = { "AmmoSlot", "BackSlot", "Bag0Slot", "Bag1Slot", "Bag2Slot", "Bag3Slot", "ChestSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "HandsSlot", "HeadSlot", "LegsSlot", "MainHandSlot", "NeckSlot", "RangedSlot", "SecondaryHandSlot", "ShirtSlot", "ShoulderSlot", "TabardSlot", "Trinket0Slot", "Trinket1Slot", "WaistSlot", "WristSlot" }
	for i, slot in ipairs(slots) do
		local link = GetInventoryItemLink("player", slot)
		db.inventory[slot] = link
	end
end

