local enabled = nil

local function BUII_AddColoredExpLine(name)
	if name == "Classic" then
		GameTooltip:AddLine(name, 1, 1, 1)
	elseif name == "Burning Crusade" then
		GameTooltip:AddLine(name, 0, 1, 0)
	elseif name == "Wrath of the Lich King" then
		GameTooltip:AddLine(name, 0, 0.8, 1)
	elseif name == "Cataclysm" then
		GameTooltip:AddLine(name, 0.8, 0.2, 0)
	elseif name == "Mists of Pandaria" then
		GameTooltip:AddLine(name, 0, 1, 0.6)
	elseif name == "Warlords of Draenor" then
		GameTooltip:AddLine(name, 0.78, 0.61, 0.43)
	elseif name == "Legion" then
		GameTooltip:AddLine(name, 0, 0.8, 0)
	elseif name == "Battle for Azeroth" then
		GameTooltip:AddLine(name, 0.20, 0.39, 0.67)
	elseif name == "Shadowlands" then
		GameTooltip:AddLine(name, 0.6, 0.8, 1)
	elseif name == "Dragonflight" then
		GameTooltip:AddLine(name, 0, 1, 0.6)
	elseif name == "Current Season" then
		 -- ignore current season tag
	else
		print("Missing expansion: " .. name)
	end
end

local function BUII_TooltipImprovements_OnTooltipSetItem(tooltip, data)
	if enabled then
		if tooltip == GameTooltip then
			local item = select(3, tooltip:GetItem())
			if item then
				local expansionID = select(15, GetItemInfo(item))
				if expansionID then
					-- EJ_GetTierInfo needs expansionID + 1 to get the correct expansion
					local expansionName = EJ_GetTierInfo(expansionID + 1)
					BUII_AddColoredExpLine(expansionName)
				end
			end
		end
	end
end

function BUII_TooltipImprovements_Enabled()
	if enabled == nil then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, BUII_TooltipImprovements_OnTooltipSetItem)
		enabled = true
	end
end

function BUII_TooltipImprovements_Disable()
	enabled = false
end
