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

local db
local realm, player = GetRealmName(), GetUnitName("player", false)
local function Print(...) print("|cFF33FF99RawrProfiler|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("RawrProfiler")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

--[[ Addon Declaration ]]
RawrProfiler = CreateFrame("frame")
RawrProfiler:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
RawrProfiler:RegisterEvent("ADDON_LOADED")

function RawrProfiler:ADDON_LOADED(event, addon)
	if addon:lower() ~= "rawrprofiler" then return end

	-- Do anything you need to do after addon has loaded
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("BANKFRAME_OPENED")

	LibStub("tekKonfig-AboutPanel").new(nil, "RawrProfiler") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

function RawrProfiler:UNIT_INVENTORY_CHANGED()
	self:ScanEquippedItems()
	self:ScanInventory()
end

function RawrProfiler:PLAYER_LOGIN()
	-- Do anything you need to do after the player has entered the world
	realm, player = GetRealmName(), GetUnitName("player", false)
	self:CheckDB()

	-- Delay the scan until GetTalentTabInfo returns data
	-- because for some reason Talent info isnt available on PLAYER_LOGIN
	local total = 0
	self:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed
		if total >= 1.0 then -- try every half second
			Debug("Checking whether talents are available")
			if db and GetTalentTabInfo(1) then
				Debug("Good to go", db)
				self:ScanAll()
				self:SetScript("OnUpdate", nil)
			end
		end
	end)

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function RawrProfiler:ACTIVE_TALENT_GROUP_CHANGED()
	Debug("Talent change detected.")
	if db then self:ScanTalents() end
end
RawrProfiler.PLAYER_TALENT_UPDATE = RawrProfiler.ACTIVE_TALENT_GROUP_CHANGED

function RawrProfiler:BANKFRAME_OPENED()
	self:ScanBank()
end

function RawrProfiler:CheckDB()
	if not RawrProfilerDB then RawrProfilerDB = {} end
	if not RawrProfilerDB[realm] then RawrProfilerDB[realm] = {} end
	if not RawrProfilerDB[realm][player] then 
		RawrProfilerDB[realm][player] = {
			equipped = {},
			inventory = {},
			bank = {},
			glyphs = {},
		}
	end
	db = RawrProfilerDB[realm][player]
	db.patch = GetBuildInfo() -- What patch level was this taken?
end

function RawrProfiler:ScanAll()
	self:ScanEquippedItems()
	self:ScanInventory()
	self:ScanTalents()
end

function RawrProfiler:ScanEquippedItems()
	local slots = { "AmmoSlot", "BackSlot", "Bag0Slot", "Bag1Slot", "Bag2Slot", "Bag3Slot", "ChestSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "HandsSlot", "HeadSlot", "LegsSlot", "MainHandSlot", "NeckSlot", "RangedSlot", "SecondaryHandSlot", "ShirtSlot", "ShoulderSlot", "TabardSlot", "Trinket0Slot", "Trinket1Slot", "WaistSlot", "WristSlot" }
	Debug("Scanning Equipped Items")
	for i, slotName in ipairs(slots) do
		local slot = GetInventorySlotInfo(slotName)
		local link = GetInventoryItemLink("player", slot)
		db.equipped[slotName] = link
	end
end

local function ScanBag(bag, dbtable)
	Debug("ScanBag", bag, GetContainerNumSlots(bag))
	for slot = 1, GetContainerNumSlots(bag) do
		local link = GetContainerItemLink(bag, slot)
		if link then
			local class = select(6, GetItemInfo(link))
			if class=="Weapon" or class=="Armor" or class=="Quiver" or class=="Projectile" then
				table.insert(dbtable, link)
			end
		end
	end
end

function RawrProfiler:ScanInventory()
	Debug("Scanning Bags")
	db.inventory = {}
	for bag = 0, NUM_BAG_SLOTS do
		ScanBag(bag, db.inventory)
	end
end

function RawrProfiler:ScanBank()
	Debug("Scanning Bank")
	db.bank = {}
	ScanBag(BANK_CONTAINER, db.bank)
	for bag = NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
		ScanBag(bag, db.bank)
	end
end

function RawrProfiler:ScanTalents()
	Debug("Scanning Talents")
	local talentString = ""
	for tabIndex = 1,GetNumTalentTabs("player") do
		for talentIndex = 1,GetNumTalents(tabIndex, false, false) do
			local points = select(5, GetTalentInfo(tabIndex, talentIndex, false, false, nil))
			talentString = talentString .. tostring(points)
		end
	end
	db.talents = talentString
end

