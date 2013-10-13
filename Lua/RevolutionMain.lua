-- Revolutions Main Lua file
-- Author: Gedemon
-- DateCreated: 3/30/2011 5:16:50 PM
--------------------------------------------------------------

print("---------------------------------------------------------------------------------------------------------------")
print("------------------------------------------ Revolutions script started -----------------------------------------")
print("---------------------------------------------------------------------------------------------------------------")


--------------------------------------------------------------
-- includes
--------------------------------------------------------------
include ("RevolutionDefines")
include ("RevolutionUtils")
include ("RevolutionDebug")
include ("RevolutionFunctions")
include ("RouteConnections")
--------------------------------------------------------------

local bWaitBeforeInitialize = true


local endTurnTime = 0
local startTurnTime = 0

function NewTurnSummary()
	local year = Game.GetGameTurnYear()
	startTurnTime = os.clock()
	Dprint("------------- NEW TURN --------------")
	Dprint ("Game year = " .. year)
	if endTurnTime > 0 then
		Dprint ("AI turn execution time = " .. startTurnTime - endTurnTime )	
	end
	Dprint("-------------------------------------")
end

function EndTurnsummary()
	endTurnTime = os.clock()
	Dprint("-------------------------------------")
	Dprint ("Your turn execution time = " .. endTurnTime - startTurnTime )
	Dprint("-------------------------------------")
end


-----------------------------------------
-- Initializing functions
-----------------------------------------

-- functions to call at beginning of turn
function OnNewTurn ()
	NewTurnSummary()
	InitializeActivePlayerTurn()
end
Events.ActivePlayerTurnStart.Add( OnNewTurn )

-- functions to call at end of turn
function OnEndTurn ()
	EndTurnsummary()
	RevolutionOutcome()
	FreeReservedCS()
	UpdateCultureRelationData()
end
Events.ActivePlayerTurnEnd.Add( OnEndTurn )

-- functions to call ASAP after launching a game
function OnFirstTurn ()
	--NewTurnSummary()
	InitializeTables()
	InitializeGameOption()
	ReserveCS()
	Events.SerialEventGameMessagePopup.Add(UpdateCityStateScreen)
	ShareGlobalTables()
	UpdateRebelsTextOnLoad()
end

-- functions to call ASAP after loading a game
function OnLoading ()
	InitializeGameOption()
	Events.SerialEventGameMessagePopup.Add(UpdateCityStateScreen)
	ShareGlobalTables()
	UpdateRebelsTextOnLoad()
end

-- functions to call after entering game (DoM screen button pushed)
function OnEnterGame ()
	UpdateRevolutionUI()

	-- Those functions need to wait for SaveUtils to be initialized before calling, which is done automatically after entering game to allow synchronization...
	-- And that synchronization could happen after the current function...
	-- So here we set the events for the next turns and call the functions for the active player on load, after manually calling share_SaveUtils()
	GameEvents.PlayerDoTurn.Add(UpdateSeparatist)
	GameEvents.PlayerDoTurn.Add(UpdateCultureRelations)
	GameEvents.PlayerDoTurn.Add(UpdateRebels)
	GameEvents.PlayerDoTurn.Add(RebelAttrition)
	share_SaveUtils()
	if not IsActivePlayerTurnInitialised() then
		UpdateSeparatist(Game.GetActivePlayer())
		UpdateCultureRelations(Game.GetActivePlayer())
		UpdateRebels(Game.GetActivePlayer())
		RebelAttrition(Game.GetActivePlayer())
	end
	----------------------------------------------------

	GameEvents.CityCaptureComplete.Add(OnCityCapture)
end
Events.LoadScreenClose.Add( OnEnterGame )



--------------------------------------------------------------
-- UI functions 
--------------------------------------------------------------

RevolutionInfosContext = ContextPtr:LoadNewContext("RevolutionInfos")
RevolutionInfosContext:SetHide(true)

print("Loading Main Revolutions UI functions...")
print("-------------------------------------")

function OnCultureRelationClicked()
	
	--RevolutionInfosContext:SetHide(false)
	UIManager:PushModal(RevolutionInfosContext)

end
Controls.CultureRelationString:RegisterCallback( Mouse.eLClick, OnCultureRelationClicked )

function UpdateRevolutionUI()
	Controls.CultureRelationString:ChangeParent(ContextPtr:LookUpControl("/InGame/TopPanel/TopPanelInfoStack"))
	ContextPtr:LookUpControl("/InGame/TopPanel/TopPanelInfoStack"):ReprocessAnchoring()
	DoInitCultureRelationTooltips()
	UpdateCultureRelationData()
end

-- Tooltip init
function DoInitCultureRelationTooltips()
	Controls.CultureRelationString:SetToolTipCallback( CultureRelationTipHandler );
end

local tipControlTable = {}
TTManager:GetTypeControlTable( "TooltipTypeTopPanel", tipControlTable )

-- Culture Relation Tooltip
function CultureRelationTipHandler( control )

	local strText
	local iPlayer = Game.GetActivePlayer()
	local player = Players[iPlayer]
	local team = Teams[player:GetTeam()]
	local city = UI.GetHeadSelectedCity()

	local cultureMap = MapModData.AH.CultureMap
	
	strText = ""

	local cultureRelations = LoadData("CultureRelations")
	if not (cultureRelations[iPlayer]) then
		strText = "[COLOR_NEGATIVE_TEXT]WARNING : No culture relation table ![ENDCOLOR]"
	else
		local realPopulation = player:GetRealPopulation()
		strText = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_EMPIRE_POPULATION").." "..realPopulation ..".[NEWLINE]"
		local cultureGroups, totalCulture = GetCultureGroups(iPlayer)

		for i, data in pairs(cultureGroups) do
			local civAdj = GetCultureTypeAdj(data.Type)
			local culturePercent = Round(data.Value / totalCulture * 100)
			local relation = cultureRelations[iPlayer][data.Type]
			local relationStr = ""
			if relation then 
				relationStr = " (" .. GetRelationValueString(relation) ..")"
			end
			strText = strText .. "[NEWLINE][ICON_BULLET] " .. culturePercent .. "%  " .. civAdj .. relationStr
		end
	end

	local bTrouble = false
	local maxTrouble = 0
	local troubleCities = {}

	for city in player:Cities() do
		 local citytrouble, percentRevolt, percentRebellion, percentRevolution = GetCityRebellion(city, cultureMap, cultureRelations)
		 if citytrouble > maxTrouble then
			maxTrouble = citytrouble
		 end
		 if (percentRevolt > 0) or (percentRebellion > 0) then
			bTrouble = true
			table.insert (troubleCities, { City = city, Revolt = percentRevolt, Rebellion = percentRebellion, Revolution = percentRevolution } )
		 end
	end
	table.sort(troubleCities, function(a,b) return a.Revolt > b.Revolt end)

	strText = strText .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_EMPIRE_STATE", GetTroubleValueString(maxTrouble))

	if (#troubleCities > 0) then
		strText = strText .. " " .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_LOWER_DISORDER") .. ":"
		for i, data in pairs(troubleCities) do
			if i <= MAX_LINE_REVOLUTION_TOOLTIP then
				strText = strText .. "[NEWLINE][NEWLINE] " .. data.City:GetName() .. ": [NEWLINE]".. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_STRIKE_PROBABILITY", data.Revolt)
				if data.City:GetPopulation() < MIN_REVOLT_CITY_SIZE then
					strText = strText .. " (" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REVOLT") .. ")"
				end
				if data.Rebellion > 0 then
					strText = strText .. "[NEWLINE]".. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_REBELLION_PROBABILITY", data.Rebellion)
					if data.City:GetPopulation() < MIN_REBELLION_CITY_SIZE then
						strText = strText .. " (" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REBELLION") .. ")"
					end
				end
				if data.Revolution > 0 then
					strText = strText .. "[NEWLINE]".. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_REVOLUTION_PROBABILITY", data.Revolution)
					if data.City:GetPopulation() < MIN_REVOLUTION_CITY_SIZE then
						strText = strText .. " (" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REVOLUTION") .. ")"
					end
				end
			end
		end
	end
	
	if(strText ~= "") then
		tipControlTable.TopPanelMouseover:SetHide(false);
		tipControlTable.TooltipLabel:SetText( strText );
	else
		tipControlTable.TopPanelMouseover:SetHide(true);
	end
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

function UpdateCultureRelationData()

	local bDebug = true
	Dprint ("------------------ ", bDebug)
	Dprint ("Updating Culture Relation Data...", bDebug)

	local iPlayer = Game.GetActivePlayer()

	local player = Players[iPlayer]
	local team = Teams[player:GetTeam()]
	local city = UI.GetHeadSelectedCity()
	
	local cultureMap = MapModData.AH.CultureMap
	local cultureRelations = LoadData("CultureRelations")

	local strCultureRelationText
			
	strCultureRelationText = "[ICON_RESISTANCE]"

	local maxTrouble = 0

	for city in player:Cities() do
		 local citytrouble = GetCityRebellion(city, cultureMap, cultureRelations)
		 if citytrouble > maxTrouble then
			maxTrouble = citytrouble
		 end
	end

	strCultureRelationText = strCultureRelationText .. GetTroubleValueString(maxTrouble)
			
	if Controls.CultureRelationString then Controls.CultureRelationString:SetText(strCultureRelationText) end

end

function UpdateCultureRelationDataOnMove(iPlayer, unitID, x, y)
	
	local bDebug = true

	--Dprint("- Unit Moving at " .. x .. "," .. y , bDebug)

	local player = Players[iPlayer]	
	if (not player:IsHuman()) then	
		return	
	end

	local unit = player:GetUnitByID(unitID)	
	if (unit == nil or unit:IsDelayedDeath()) then	
		return	
	end	
	local plot = GetPlot(x, y)	
	local missionPlot = unit:LastMissionPlot()
	--local endPathPlot = unit:GetPathEndTurnPlot()
	
	--Dprint("- missionPlot = " .. tostring(missionPlot), bDebug)
	--Dprint("- endPathPlot = " .. tostring(endPathPlot), bDebug)
	
	--Dprint("- Unit at (" .. x .. "," .. y .. "), Mission Plot at ("..missionPlot:GetX()..","..missionPlot:GetY()..")", bDebug)
	--Dprint("- Unit at (" .. x .. "," .. y .. "), Mission Plot at ("..missionPlot:GetX()..","..missionPlot:GetY().."), End Path Plot at ("..endPathPlot:GetX()..","..endPathPlot:GetY()..")", bDebug)
	
	if plot == missionPlot then
		UpdateCultureRelationData()
	end
end

-- Register Events
--Events.SerialEventGameDataDirty.Add(UpdateCultureRelationData)
--Events.SerialEventTurnTimerDirty.Add(UpdateCultureRelationData)
Events.SerialEventCityInfoDirty.Add(UpdateCultureRelationData)
--Events.SerialEventUnitMoveToHexes.Add(UpdateCultureRelationData)
GameEvents.UnitSetXY.Add (UpdateCultureRelationDataOnMove)

Events.SerialEventCityDestroyed.Add(UpdateCultureRelationData)
Events.SerialEventCityCaptured.Add(UpdateCultureRelationData)

--------------------------------------------------------------
-- Initialize when RevolutionMain is loaded
--------------------------------------------------------------

if ( bWaitBeforeInitialize ) then
	bWaitBeforeInitialize = false
	local initialised = LoadData ("RevolutionInitialised", false)
	if not initialised then
		OnFirstTurn()
		SaveData("RevolutionInitialised", 1)
		SaveData("GameStartTurn", Game.GetGameTurn())
	else
		OnLoading()
	end
end

-----------------------------------------
-----------------------------------------

print("--------------------------------------------------------------------------------------------------------------")
print("----------------------------------------- Revolutions script loaded ------------------------------------------")
print("--------------------------------------------------------------------------------------------------------------")
