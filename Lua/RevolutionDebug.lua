-- Debug
-- Author: Gedemon
-- DateCreated: 1/30/2011 8:03:25 PM
--------------------------------------------------------------

print("Loading Revolution Debug Functions...")
print("-------------------------------------")

-- Output debug text
function Dprint ( str, bOutput )
  if bOutput == nil then
    bOutput = true
  end
  if ( DEBUG_REVOLUTION and bOutput ) then
    print (str)
  end
end

-- Display Culture Map
function DisplayCultureMap()
	local cultureMap = MapModData.AH.CultureMap
	Dprint("Culture map :")
	Dprint("-------------------------------------")
	for key, plotCulture in pairs (cultureMap) do
		for i, civCulture in ipairs (plotCulture) do
			Dprint(" (" .. key .. ") :" .. civCulture.ID .. " civilization has " .. civCulture.Value .. " culture") 
		end
	end
	Dprint("-------------------------------------")
end

function ShowCultureGroups()
	print ("List all culture groups")
	Dprint("-------------------------------------")
	local cultureRelations = LoadData("CultureRelations", {})
	for iPlayer = 0, GameDefines.MAX_PLAYERS do
		local player= Players[iPlayer]
		if player and player:IsAlive() then
			local cultureGroups = GetCultureGroups(iPlayer)
			Dprint ("List of culture groups for " .. player:GetName())	
			for i, data in pairs(cultureGroups) do
				local relation = 0
				if cultureRelations[iPlayer] then
					if cultureRelations[iPlayer][data.Type] then
						relation = cultureRelations[iPlayer][data.Type]
					end
				end
				Dprint (" - " .. data.Type .. " (" .. data.Value .. ") = " .. relation )
			end	
			Dprint ("------------------ ")
		end
	end
end

function CreateReservedCS()
	local reservedCS = {}
	for i = 30, 40 do -- no !!!
		local player = Players[i]
		local CityStateType = GetCivTypeFromPlayer (i)
		SetText ("REBEL_"..i, "TXT_KEY_CITYSTATE_" .. CityStateType)
		SetText ("REBEL_ADJ_"..i, "TXT_KEY_CITYSTATE_" .. CityStateType .. "_ADJ")
		SetText ("REBEL_TXT_"..i, "TXT_KEY_CIV5_" .. CityStateType .. "_TEXT")
		reservedCS[i] = { Action = nil, Type = nil, Reference = nil }
	end
	SaveData( "ReservedCS", reservedCS )
end

function ShowReservedCS()

	Dprint ("------------------ ")
	Dprint ("Show reservation for CS...")
	
	local reservedCS = LoadData ("ReservedCS")
	for id, data in pairs(reservedCS) do
		local player = Players[id]
		Dprint ("  - Name : " .. player:GetName())
		Dprint ("  - ID : " .. id)
		if	reservedCS[id].Action then Dprint ("  - Action : " .. reservedCS[id].Action) end
		if	reservedCS[id].Type then Dprint ("  - Type : " .. reservedCS[id].Type) end
		if	reservedCS[id].Reference then Dprint ("  - Reference : " .. reservedCS[id].Reference) end
	end
end

-- Hide/Show HUD for screenshot...
function HideHUD(bValue)
	ContextPtr:LookUpControl("/InGame/TopPanel/"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/DiploCorner"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/UnitPanel"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/InfoCorner"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/PlotHelpManager"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/PlotHelpText"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/WorldView/MiniMapPanel"):SetHide(bValue)
	ContextPtr:LookUpControl("/InGame/UnitFlagManager"):SetHide(bValue)
end 