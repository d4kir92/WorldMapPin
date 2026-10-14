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

C_Timer.After(0, function() WorldMapPin:SetVersion() end)
