local _, WorldMapPin = ...
WorldMapPin:SetAddonOutput()
WorldMapPin:EnableWaypointFallback(function()
	WMPTABPC = WMPTABPC or {}
	return WMPTABPC
end)

WorldSpacePin = WorldMapPin:GetWaypointFrame()
function WorldMapPin_GetDistance()
	return WorldMapPin:GetWaypointDistance()
end

function WorldMapPin_GetDistanceF()
	return floor(WorldMapPin:GetWaypointDistance() + 0.5)
end

if WorldMapPin:IsForever() then
	local loader = CreateFrame("Frame")
	local function KeepWaypointVisible()
		local frame = SuperTrackedFrame
		if not frame or not C_Navigation or not C_Navigation.GetDistance then return end

		for _, method in ipairs({"GetTargetAlphaBaseValue", "GetTargetAlpha"}) do
			local getAlpha = frame[method]
			if getAlpha then
				frame[method] = function(self, ...)
					local alpha = getAlpha(self, ...)
					if alpha == 0 and self.navFrame and WorldMapPin:IsWaypointTracked() and (C_Navigation.GetDistance() or 0) > 0 then
						return 0.5
					end

					return alpha
				end
			end
		end

		loader:UnregisterAllEvents()
	end

	loader:RegisterEvent("PLAYER_LOGIN")
	loader:RegisterEvent("ADDON_LOADED")
	loader:SetScript("OnEvent", KeepWaypointVisible)
	KeepWaypointVisible()
end

C_Timer.After(0, function() WorldMapPin:SetVersion() end)
