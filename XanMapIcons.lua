--This mod is heavily inspired by the Group Icons found in the Mapster Mod.
--I wanted the functionality of the group icons without having to have Mapster installed.
--Full credit where due to Hendrik "Nevcairiel" Leppkes for his addon Mapster.

local _G = _G
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local MapUnit_IsInactive = MapUnit_IsInactive

local f = CreateFrame("frame","XanMapIcons",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
		self:RegisterEvent("ADDON_LOADED")
	else
		f:FixMapUnits(1, true)
	end
	f:FixMapUnits(0, true)

	--replace the worldmapunit function
	WorldMapUnit_Update = f.WorldMapUnit_Update;

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	
	local ver = GetAddOnMetadata("XanMapIcons","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded", "XanMapIcons", ver or "1.0"))
end

------------------------------
--         Handlers         --
------------------------------

function f:ADDON_LOADED(event, addon)
	if addon == "Blizzard_BattlefieldMinimap" then
		self:UnregisterEvent("ADDON_LOADED")
		f:FixMapUnits(1, true)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function f:WorldMapUnit_Update(unit)
	if unit == nil then return end
	f:UpdateIcon(unitFrame.icon, unitFrame.unit)
end

------------------------------
--      Icon Functions      --
------------------------------

function f:SetIcon(unit, state, isNormal)
	local frm = _G[unit]
	local icon = frm.icon
	if state then
		frm.elapsed = 0.5
		frm:SetScript('OnUpdate', function(self, elapsed)
			self.elapsed = self.elapsed - elapsed
			if self.elapsed <= 0 then
				self.elapsed = 0.5
				XanMapIcons:UpdateIcon(self.icon, self.unit)
			end
		end)
		frm:SetScript("OnEvent", nil)
		if isNormal then
			icon:SetTexture("Interface\\AddOns\\XanMapIcons\\Icons\\Normal")
		end
	else
		frm.elapsed = nil
		frm:SetScript("OnUpdate", nil)
		frm:SetScript("OnEvent", WorldMapUnit_OnEvent)
		icon:SetVertexColor(1, 1, 1)
		icon:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon")
	end
end

function f:FixMapUnits(switch, state)
	if switch == 0 then
		--WORLD MAP
		for i = 1, 4 do
			f:SetIcon(string.format("WorldMapParty%d", i), state, true)
		end
		for i = 1,40 do
			f:SetIcon(string.format("WorldMapRaid%d", i), state)
		end
	elseif switch == 1 then
		--BATTLEFIELD MAP
		if BattlefieldMinimap then
			for i = 1, 4 do
				f:SetIcon(string.format("BattlefieldMinimapParty%d", i), state, true)
			end
			for i = 1, 40 do
				f:SetIcon(string.format("BattlefieldMinimapRaid%d", i), state)
			end
		end
	end
end

function f:UpdateIcon(icon, unit)
	if not (icon and unit) then return end

	local _, fileName = UnitClass(unit)
	if not fileName then return end

	if string.find(unit, "raid", 1, true) then
		local _, _, subgroup = GetRaidRosterInfo(string.sub(unit, 5))
		if not subgroup then return end
		icon:SetTexture(string.format("Interface\\AddOns\\XanMapIcons\\Icons\\Group%d", subgroup))
	end
	
	--set colors, flash if in combat
	local t = RAID_CLASS_COLORS[fileName]
	if (GetTime() % 1 < 0.5) then
		if UnitAffectingCombat(unit) then
			icon:SetVertexColor(0.8, 0, 0) --red flash, unit in combat
		elseif UnitIsDeadOrGhost(unit) then
			icon:SetVertexColor(0.2, 0.2, 0.2) --grey for dead units
		elseif PlayerIsPVPInactive(unit) then
			icon:SetVertexColor(0.5, 0.2, 0.8) --purple for inactives
		end
	elseif t then
		icon:SetVertexColor(t.r, t.g, t.b) --class color
	else
		icon:SetVertexColor(0.8, 0.8, 0.8) --grey for default
	end
end

------------------------
--       LOADER	      --
------------------------

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
