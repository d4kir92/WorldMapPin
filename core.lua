local AddonName, WorldMapPin = ...
WorldMapPin:SetAddonOutput("WorldMapPin", 134269)
local pinsize = 24
local pinx = -1
local piny = -1
local WMP_Dist = 0
local WMP_Dist_F = 0
function WorldMapPin_GetDistance()
	return WMP_Dist
end

function WorldMapPin_GetDistanceF()
	return WMP_Dist_F
end

-- libs
local function MathIsNear(pos1, pos2, near)
	if abs(pos2 - pos1) < near then return true end

	return false
end

local function MathC(num, min, max)
	if num < min then
		return min
	elseif num > max then
		return max
	end

	return num
end

-- Memory Fix
local MapRects = {}
local TempVec2D = CreateVector2D(0, 0)
local function GetPlayerMapPos(MapID)
	local R, P, _ = MapRects[MapID], TempVec2D
	if not R then
		R = {}
		_, R[1] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(0, 0))
		_, R[2] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(1, 1))
		R[2]:Subtract(R[1])
		MapRects[MapID] = R
	end

	P.x, P.y = UnitPosition("Player")
	if P.x and P.y then
		P:Subtract(R[1])

		return (1 / R[2].y) * P.y, (1 / R[2].x) * P.x
	else
		return nil, nil
	end
end

-- Memory Fix
-- libs
WorldSpacePin = CreateFrame("FRAME", "WorldSpacePin")
WorldSpacePin:SetFrameStrata("HIGH")
WorldSpacePin:SetSize(pinsize, pinsize)
WorldSpacePin.texture = WorldSpacePin:CreateTexture(nil, "OVERLAY")
WorldSpacePin.texture:SetAllPoints(WorldSpacePin)
WorldSpacePin.texture:SetTexture("Interface\\COMMON\\Indicator-Yellow")
WorldSpacePin.texture:SetVertexColor(1, 1, 1, 1)
WorldSpacePin.text = WorldSpacePin:CreateFontString(nil, "OVERLAY")
WorldSpacePin.text:SetFont(STANDARD_TEXT_FONT, 10, "")
WorldSpacePin.text:SetPoint("TOP", WorldSpacePin, "BOTTOM", 0, 0)
WorldSpacePin.text:SetText("LOADING (WMP)")
local WMP = CreateFrame("FRAME", "WMP", WorldMapFrame.ScrollContainer)
WMP:SetSize(20, 20)
WMP.texture = WMP:CreateTexture(nil, "OVERLAY")
WMP.texture:SetAllPoints(WMP)
WMP.texture:SetTexture("Interface\\COMMON\\Indicator-Green")
WorldMapFrame.ScrollContainer.Child:SetScript(
	"OnUpdate",
	function(self, btn)
		self.wmpswitch = self.wmpswitch or false
		if IsMouseButtonDown("LeftButton") and IsControlKeyDown() then
			local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
			y = 1 - y
			if self.wmpswitch == false then
				self.wmpswitch = true
				if MathIsNear(x, pinx, 0.01) and MathIsNear(y, piny, 0.01) then
					pinx = -1
					piny = -1
				else
					pinx = x
					piny = y
				end
			end
		else
			self.wmpswitch = false
		end
	end
)

function WorldMapPin:MapPlayerAlpha()
	facing = GetPlayerFacing()
	if facing == nil then
		facing = 0
	end

	return facing / (2 * math.pi) * 360
end

function WorldMapPin:MapPinX()
	local mapID = C_Map.GetBestMapForUnit("PLAYER")
	if mapID then
		local posx, posy = GetPlayerMapPos(mapID)
		if posx and posy then
			local sw = WorldMapFrame.ScrollContainer:GetWidth()
			local sh = WorldMapFrame.ScrollContainer:GetHeight()
			local ratio = sw / sh
			local xc, yc = posx, posy -- Character X, Y
			local xp, yp = pinx, piny -- Pin X, Y
			yc = 1 - yc -- Fix for Y
			local res = math.sqrt(math.pow(xc - xp, 2) + math.pow(math.abs(yc - yp), 2))
			WMP_Dist = res * 1000
			WMP_Dist_F = tonumber(format("%0.0f", WMP_Dist))
			xc = (xc - 0.5) * ratio + 0.5
			xp = (xp - 0.5) * ratio + 0.5
			local ca = WorldMapPin:MapPlayerAlpha() -- 0-360
			local rx = acos(((xc - xp) * sin(ca) + (yp - yc) * cos(ca)) / math.sqrt(math.pow(xp - xc, 2) + math.pow(yp - yc, 2)))
			local cr = (xp - xc) * cos(ca) + (yp - yc) * sin(ca)
			if cr > 0 then
				rx = rx * -1
			end

			return rx
		else
			return 0
		end
	else
		return 0
	end
end

function WorldMapPin:HasCoords()
	local mapID = C_Map.GetBestMapForUnit("PLAYER")
	if mapID then
		local pos = GetPlayerMapPos(mapID)
		if pos then return true end
	end

	return false
end

function WorldMapPin:UpdatePinPos()
	if WorldMapPin:HasCoords() and pinx >= 0 and piny >= 0 then
		local alpha = WorldMapPin:MapPinX()
		if alpha > -3 and alpha < 3 then
			WorldSpacePin.texture:SetTexture("Interface\\COMMON\\Indicator-Green")
		elseif alpha > 85 or alpha < -85 then
			WorldSpacePin.texture:SetTexture("Interface\\COMMON\\Indicator-Red")
		else
			WorldSpacePin.texture:SetTexture("Interface\\COMMON\\Indicator-Yellow")
		end

		local x = GetScreenWidth() * UIParent:GetEffectiveScale() / 2 + alpha / -180 * GetScreenWidth() * UIParent:GetEffectiveScale()
		local y = GetScreenHeight() * UIParent:GetEffectiveScale() / 2 - pinsize / 2
		x = MathC(x, 0, GetScreenWidth() * UIParent:GetEffectiveScale() - pinsize)
		WorldSpacePin:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
		local scale = WorldMapFrame.ScrollContainer.Child:GetScale()
		local sw = WorldMapFrame.ScrollContainer.Child:GetWidth() * scale
		local sh = WorldMapFrame.ScrollContainer.Child:GetHeight() * scale
		WorldSpacePin.text:SetText(WMP_Dist_F .. "m")
		WorldSpacePin:Show()
		WMP:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer.Child, "BOTTOMLEFT", sw * pinx - 10, sh * piny - 10)
		WMP:Show()
	else
		WorldSpacePin:Hide()
		WMP:Hide()
	end

	C_Timer.After(0.01, WorldMapPin.UpdatePinPos)
end

WorldMapPin:UpdatePinPos()
C_Timer.After(
	0,
	function()
		WorldMapPin:SetVersion(134269, "1.1.75")
	end
)
