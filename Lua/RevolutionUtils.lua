-- Revolution Utils
-- Author: Gedemon
-- DateCreated: 1/29/2011 11:52:55 PM
--------------------------------------------------------------

print("Loading Revolution Utils Function...")
print("-------------------------------------")

--------------------------------------------------------------
-- Map functions 
--------------------------------------------------------------

--	here (x,y) = (0,0) is bottom left of map in Worldbuilder.
function GetPlot (x,y)
	local plot = Map:GetPlotXY(y,x)
	return plot
end

function GetPlotKey ( plot )
	-- set the key string used in cultureMap
	-- structure : g_CultureMap[plotKey] = { { ID = CIV_CULTURAL_ID, Value = cultureForThisCiv }, }
	local x = plot:GetX()
	local y = plot:GetY()
	local plotKey = x..","..y
	return plotKey
end

-- return the plot refered by the key string
function GetPlotFromKey ( plotKey )
	local pos = string.find(plotKey, ",")
	local x = string.sub(plotKey, 1 , pos -1)
	local y = string.sub(plotKey, pos +1)
	local plot = Map:GetPlotXY(y,x)
	return plot
end

function GetPlotXYFromKey ( plotKey )
	local pos = string.find(plotKey, ",")
	local x = string.sub(plotKey, 1 , pos -1)
	local y = string.sub(plotKey, pos +1)
	return x, y
end

function GetCloseCity ( iPlayer, plot )
	local pPlayer = Players[iPlayer]
	local distance = 1000
	local closeCity = nil
	for pCity in pPlayer:Cities() do
		distanceToCity = Map.PlotDistance(pCity:GetX(), pCity:GetY(), plot:GetX(), plot:GetY())
		if ( distanceToCity < distance) then
			distance = distanceToCity
			closeCity = pCity
		end
	end
	return closeCity
end

-- check if path is blocked for RouteConnections
function PathBlocked(pPlot, pPlayer)
	if ( pPlot == nil or pPlayer == nil) then
		Dprint ("WARNING : CanPass() called with a nil argument")
		return true
	end

	local ownerID = pPlot:GetOwner()
	local iPlayer = pPlayer:GetID()

	if ( ownerID == iPlayer or ownerID == -1 ) then
		return false
	end

	local pOwner = Players [ ownerID ]

	if ( pPlayer:GetTeam() == pOwner:GetTeam() or pOwner:IsAllies(iPlayer) or pOwner:IsFriends(iPlayer) ) then
		return false
	end

	--local team1 = Teams [ pPlayer:GetTeam() ]
	local plotTeam = Teams [ pOwner:GetTeam() ]
	if plotTeam:IsAllowsOpenBordersToTeam( pPlayer:GetTeam() ) then
		return false
	end

	return true -- return true if the path is blocked...
end

-- get iPlayer closest city from a plot (return city object)
function GetCloseCity ( iPlayer, plot , bNotSelf)
	local pPlayer = Players[iPlayer]
	if pPlayer then
		local distance = 1000
		local closeCity = nil
		for pCity in pPlayer:Cities() do
			if pCity:Plot() == plot and bNotSelf then
				--Dprint ( " -- GetCloseCity() called with (bNotSelf = true), don't test city on starting plot...")
			else
				distanceToCity = Map.PlotDistance(pCity:GetX(), pCity:GetY(), plot:GetX(), plot:GetY())
				if ( distanceToCity < distance) then
					distance = distanceToCity
					closeCity = pCity
				end
			end
		end
		return closeCity, distance
	else
		Dprint("- WARNING: pPlayer is nil for GetCloseCity()")
		if iPlayer then Dprint ("  -- iPlayer is :" .. iPlayer) else Dprint ("  -- iPlayer is : nil or false") end
		return nil, nil
	end
end

--------------------------------------------------------------
-- Load / Save 
--------------------------------------------------------------

function LoadCultureMap()
	local startTime = os.clock()
	local pPlayer = Players[PLAYER_SAVE_SLOT]
	local cultureMap = load( pPlayer, "CultureMap" ) or {}
	local endTime = os.clock()
	local totalTime = endTime - startTime
	Dprint ("LoadCultureMap() used " .. totalTime .. " sec", DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
	return cultureMap
end
function SaveCultureMap( cultureMap )
	local startTime = os.clock()
	local pPlayer = Players[PLAYER_SAVE_SLOT]
	save( pPlayer, "CultureMap", cultureMap )
	local endTime = os.clock()
	local totalTime = endTime - startTime
	Dprint ("SaveCultureMap() used " .. totalTime .. " sec", DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
end

function LoadData( name, defaultValue, key )
	local startTime = os.clock()
	local plotKey = key or DEFAULT_SAVE_KEY
	local pPlot = GetPlotFromKey ( plotKey )
	if pPlot then
		local value = load( pPlot, name ) or defaultValue
		local endTime = os.clock()
		local totalTime = endTime - startTime
		Dprint ("LoadData() used " .. tostring(totalTime) .. " sec to retrieve " .. tostring(name) .. " from plot " .. tostring(plotKey) .. " (#entries = " .. tostring(GetSize(value)) ..")", DEBUG_PERFORMANCE)
		return value
	else
		Dprint("ERROR: trying to load script data from invalid plot (" .. tostring(plotKey) .."), data = " .. tostring(name))
		return nil
	end
end
function SaveData( name, value, key )
	local startTime = os.clock()
	local plotKey = key or DEFAULT_SAVE_KEY
	local pPlot = GetPlotFromKey ( plotKey )	
	if pPlot then
		save( pPlot, name, value )
		local endTime = os.clock()
		local totalTime = endTime - startTime
		Dprint ("SaveData() used " .. tostring(totalTime) .. " sec to store " .. tostring(name) .. " in plot " .. tostring(plotKey) .. " (#entries = " .. tostring(GetSize(value)) ..")", DEBUG_PERFORMANCE)
	else
		Dprint("ERROR: trying to save script data to invalid plot (" .. tostring(plotKey) .."), data = " .. tostring(name) .. " value = " .. tostring(value))
	end
end

function LoadModdingData( name, defaultValue)
	local startTime = os.clock()
	local savedData = Modding.OpenSaveData()
	local value = savedData.GetValue(name) or defaultValue
	local endTime = os.clock()
	local totalTime = endTime - startTime
	Dprint ("LoadData() used " .. totalTime .. " sec for " .. name, DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
	return value
end
function SaveModdingData( name, value )
	startTime = os.clock()
	local savedData = Modding.OpenSaveData()
	savedData.SetValue(name, value)
	endTime = os.clock()
	totalTime = endTime - startTime
	Dprint ("SaveData() used " .. totalTime .. " sec for " .. name, DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
end

function ShareGlobalTables()
	print("Sharing Global Tables...")
	MapModData.AH.CultureRelations = LoadData("CultureRelations")
end

--------------------------------------------------------------
-- Math functions 
--------------------------------------------------------------

function Round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function Shuffle(t)
  local n = #t
 
  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
 
  return t
end


function GetSize(t)

	if type(t) ~= "table" then
		return 1 
	end

	local n = #t 
	if n == 0 then
		for k, v in pairs(t) do
			n = n + 1
		end
	end 
	return n
end

--------------------------------------------------------------
-- Database functions 
--------------------------------------------------------------

-- return the first iPlayer using this CivilizationID or MinorcivID
function GetiPlayerFromCivID (id, bIsMinor, bReportError)
	if ( bIsMinor ) then
		for player_num = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
			local player = Players[player_num]
			if ( id == player:GetMinorCivType() ) then
				return player_num
			end
		end
	else
		for player_num = 0, GameDefines.MAX_MAJOR_CIVS-1 do
			local player = Players[player_num]
			if ( id == player:GetCivilizationType() ) then
				return player_num
			end
		end
	end
	if (id) then 
		Dprint ("WARNING : can't find Player ID for civ ID = " .. id , bReportError) 
	else	
		Dprint ("WARNING : civID is NILL or FALSE", bReportError) 
	end
	return false
end

-- return Civ type ID for iPlayer
function GetCivIDFromiPlayer (iPlayer, bReportError)
	if (iPlayer ~= -1) then
		if iPlayer <= GameDefines.MAX_MAJOR_CIVS-1 then
			local civID = Players[iPlayer]:GetCivilizationType()
			if (civID ~= -1) then
				return civID
			else
				Dprint ("WARNING : no major civ for iPlayer = " .. iPlayer , bReportError) 
				return false
			end
		else 
			local civID = Players[iPlayer]:GetMinorCivType()
			if (civID ~= -1) then
				return civID
			else
				Dprint ("WARNING : no minor civ for iPlayer = " .. iPlayer, bReportError) 
				return false
			end
		end
	else
		Dprint ("WARNING : trying to find CivType for iPlayer = -1", bReportError) 
		return false
	end
end

function GetCivTypeFromPlayer (iPlayer, bReportError)
	if (iPlayer ~= -1) then
		if iPlayer <= GameDefines.MAX_MAJOR_CIVS-1 then
			local civID = Players[iPlayer]:GetCivilizationType()
			if (civID ~= -1) then
				return GameInfo.Civilizations[civID].Type
			else
				Dprint ("WARNING : no major civ for iPlayer = " .. iPlayer , bReportError) 
				return false
			end
		else 
			local civID = Players[iPlayer]:GetMinorCivType()
			if (civID ~= -1) then
				return GameInfo.MinorCivilizations[civID].Type
			else
				Dprint ("WARNING : no minor civ for iPlayer = " .. iPlayer, bReportError) 
				return false
			end
		end
	else
		Dprint ("WARNING : trying to find CivType for iPlayer = -1", bReportError) 
		return false
	end
end

-- update localized text
function SetText ( str, tag )
	bDebug = true
	-- in case of language change mid-game :
	local query = "UPDATE Language_en_US SET Text = '".. str .."' WHERE Tag = '".. tag .."'"
	for result in DB.Query(query) do
	end
	Dprint (query, bDebug)
	-- that's the table used ingame :
	local query = "UPDATE LocalizedText SET Text = '".. str .."' WHERE Tag = '".. tag .."'"
	for result in DB.Query(query) do
	end
	Dprint (query, bDebug)
end

function RefreshText()
	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
	--Events.SystemUpdateUI( SystemUpdateUIType.ReloadUI )
end

-- return the first iPlayer using this Civilization or Minorciv type
function GetiPlayerFromCivType (type, bReportError)
	if (type) then 
		local civID = nil
		if GameInfo.Civilizations[type] then
			civID = GameInfo.Civilizations[type].ID
			return GetiPlayerFromCivID (civID, false, bReportError)
		elseif GameInfo.MinorCivilizations[type] then
			civID = GameInfo.MinorCivilizations[type].ID
			return GetiPlayerFromCivID (civID, true, bReportError)
		end
		Dprint ("WARNING : can't find Player ID for civ Type = " .. type , bReportError) 
	else	
		Dprint ("WARNING : civID is NIL or FALSE", bReportError) 
	end
	return false
end

--------------------------------------------------------------
-- Civilizations functions 
--------------------------------------------------------------

function RemoveCiv (iPlayer)
	local player = Players[iPlayer]
	-- kill all units
	for v in player:Units() do
		v:Kill()
	end
end


--------------------------------------------------------------
-- Text functions 
--------------------------------------------------------------

function GetRelationValueString(value)
	if value < THRESHOLD_EXASPERATED then
		return "[COLOR_NEGATIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_EXASPERATED").."[ENDCOLOR]"
	end
	if value < THRESHOLD_WOEFUL then
		return "[COLOR_NEGATIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_WOEFUL").."[ENDCOLOR]"
	end
	if value < THRESHOLD_UNHAPPY then
		return Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_UNHAPPY")
	end
	if value < THRESHOLD_CONTENT then
		return Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_CONTENT")
	end
	if value < THRESHOLD_HAPPY then
		return Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_HAPPY")
	end
	if value < THRESHOLD_JOYFUL then
		return "[COLOR_POSITIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_JOYFUL").."[ENDCOLOR]"
	end
	return "[COLOR_POSITIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATION_STATUS_ENTHUSIASTIC").."[ENDCOLOR]"
end

function GetCultureTypeAdj(cultureID)
	local civAdj = ""
	for row in GameInfo.Civilizations() do
		if row.Type == cultureID then
			civAdj = Locale.ConvertTextKey (row.Adjective)
		end
	end
	if civAdj == "" then
		for row in GameInfo.MinorCivilizations() do
			if row.Type == cultureID then
				civAdj = Locale.ConvertTextKey (row.Adjective)
			end
		end
	end

	if cultureID == SEPARATIST_TYPE then
		civAdj = Locale.ConvertTextKey ("TXT_KEY_REVOLUTION_CULTURE_TYPE_SEPARATIST_ADJ")
	end
	return civAdj
end

function GetTroubleValueString(value)
	if value == 0 then
		return "[COLOR_POSITIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TROUBLE_VALUE_STABLE").."[ENDCOLOR]"
	end
	if value == 1 then
		return Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TROUBLE_VALUE_PROTESTER")
	end
	if value == 2 then
		return "[COLOR_NEGATIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TROUBLE_VALUE_UNSTABLE").."[ENDCOLOR]"
	end
	if value == 3 then
		return "[COLOR_NEGATIVE_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TROUBLE_VALUE_REBELLIOUS").."[ENDCOLOR]"
	end
end


--------------------------------------------------------------
-- Diplomacy 
--------------------------------------------------------------

function DeclarePermanentWar(iPlayer1, iPlayer2)
	local player1 = Players[ iPlayer1 ]
	local player2 = Players[ iPlayer2 ]
	local team1 = Teams[ player1:GetTeam() ]
	local team2 = Teams[ player2:GetTeam() ]
	team1:DeclareWar( player2:GetTeam() )
	team1:SetPermanentWarPeace( player2:GetTeam(), true)
	team2:SetPermanentWarPeace( player1:GetTeam(), true)
end

function MakePermanentPeace(iPlayer1, iPlayer2)
	local player1 = Players[ iPlayer1 ]
	local player2 = Players[ iPlayer2 ]
	local team1 = Teams[ player1:GetTeam() ]
	local team2 = Teams[ player2:GetTeam() ]
	team1:MakePeace( player2:GetTeam() )
	team1:SetPermanentWarPeace( player2:GetTeam(), true)
	team2:SetPermanentWarPeace( player1:GetTeam(), true)
end

-- Functions to hide Minor civ War Button
function HideMinorWarButton( popupInfo )

	local bDebug = true
		Dprint ("-------------------------------------", bDebug)
		Dprint ("Check War button for Minor civ...", bDebug)
	
	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO ) then
		return
	end
	
    local minoriPlayer = popupInfo.Data1
    --local minorTeamID = Players[minoriPlayer]:GetTeam()	
	local iPlayer = Game.GetActivePlayer()
	local team = Teams [Players[iPlayer]:GetTeam()]
	
	local bForcedPeace = false
	local strToolTip = nil
	local strText = nil

	if Game.GetGameTurn() < WAR_MINIMUM_STARTING_TURN then
		bForcedPeace = true
		strToolTip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_WAR_MINIMUM_STARTING_TURN") .. " " .. WAR_MINIMUM_STARTING_TURN
	end
	if not ALLOW_ALTERNATE_HISTORY then
		bForcedPeace = true
		strToolTip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NO_ALTERNATE_HISTORY")
	end

	if g_MinorProtector then
		local protectorList = g_MinorProtector[GetCivIDFromiPlayer (minoriPlayer)]
		if protectorList then
			for i, protectorID in pairs (protectorList) do
				local protector = Players[GetiPlayerFromCivID (protectorID, false, true)]
				if team:IsForcePeace( protector:GetTeam() ) then
					Dprint ("Peace forced beetwen player and " .. protector:GetName(), bDebug)
					
					bForcedPeace = true
					strToolTip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_FORCED_PEACE_TOOLTIP")
					strText = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_FORCED_PEACE_MESSAGE")
				end
			end
		end
	end

	if ( bForcedPeace ) then
		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/WarButton"):SetDisabled(true)
		if strToolTip then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/WarButton"):SetToolTipString( strToolTip ); end
		if strText then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/DescriptionLabel"):SetText( strText ); end
	else
		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/WarButton"):SetDisabled(false)
		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/WarButton"):SetToolTipString( "" )
	end
end
-- add to Events.SerialEventGameMessagePopup on init and loading...


-- Functions to hide Minor civ War Button
function UpdateCityStateScreen( popupInfo )

	local bDebug = true
	
	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO ) then
		return
	end
	
	Dprint ("-------------------------------------", bDebug)
	Dprint ("Check Peace button for Minor civ...", bDebug)
	
    local minoriPlayer = popupInfo.Data1
    --local minorTeamID = Players[minoriPlayer]:GetTeam()	
	local iPlayer = Game.GetActivePlayer()
	local team = Teams [Players[iPlayer]:GetTeam()]
	
	local strToolTip = nil
	local strText = nil
	local strStatusText = nil
	local strStatusTooltip = nil
	local background = nil

	if IsRebellingAgainst(minoriPlayer, iPlayer) then
		Dprint ("War forced beetwen player and " .. Players[minoriPlayer]:GetName(), bDebug)
		bForcedWar = true
		strToolTip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NO_PEACE_WITH_REBELS")
		strText = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_MOTTO")
		
		strStatusText = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_AGAINST_YOU")

		strStatusTooltip = ""

		local era = Players[minoriPlayer]:GetCurrentEra()	 
		background = g_EraRebelsBackground[era]

		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/PeaceButton"):SetDisabled(true)

	elseif IsRebelling(minoriPlayer) then
		Dprint ("Entering Rebel City-State Screen of " .. Players[minoriPlayer]:GetName(), bDebug)

		strText = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_MOTTO")

		local master = Players[GetMaster(minoriPlayer)]
		strStatusText = "[COLOR_PLAYER_YELLOW_TEXT]"..Locale.ConvertTextKey("TXT_KEY_REVOLUTION_AGAINST_ANOTHER").." "..tostring(master:GetName()) .."[ENDCOLOR]"

		strStatusTooltip = ""

		local era = Players[minoriPlayer]:GetCurrentEra()	 
		background = g_EraRebelsBackground[era]

		-- hide everything except Peace and war...
		if  ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/GoldGiftButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/GoldGiftButton"):SetHide(true); end -- Vanilla 
		if ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/UnitGiftButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/UnitGiftButton"):SetHide(true); end -- Vanilla 
		if ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/GiveButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/GiveButton"):SetHide(true); end -- Expansion 
		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/PledgeButton"):SetHide(true)
		if ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/RevokePledgeButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/RevokePledgeButton"):SetHide(true); end -- Expansion 
		if ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/TakeButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/TakeButton"):SetHide(true); end -- Expansion 
		if ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/BuyoutButton") then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/BuyoutButton"):SetHide(true); end -- Expansion 
		ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/NoUnitSpawningButton"):SetHide(true)

	else
		--ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/PeaceButton"):SetDisabled(false)
		--ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/PeaceButton"):SetToolTipString( "" )
	end
	
	-- Update Screen
	if strToolTip then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/PeaceButton"):SetToolTipString( strToolTip ); end		
	if strText then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/DescriptionLabel"):SetText( strText ); end	
	if strStatusText then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/StatusInfo"):SetText( strStatusText ); end
	if strStatusTooltip then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/StatusInfo"):SetToolTipString( strStatusTooltip ); end
	if background then ContextPtr:LookUpControl("/InGame/CityStateDiploPopup/BackgroundImage"):SetTexture(background); end

end
-- add to Events.SerialEventGameMessagePopup on init and loading...

function IsRebellingAgainst(minoriPlayer, iPlayer)

	local reservedCS = LoadData ("ReservedCS")
	if reservedCS[minoriPlayer] and reservedCS[minoriPlayer].Reference == iPlayer then
		return true
	else
		return false
	end
end

function IsRebelling(minoriPlayer)
	local reservedCS = LoadData ("ReservedCS")
	if reservedCS[minoriPlayer] and reservedCS[minoriPlayer].Action == "REVOLT" then
		return true
	else
		return false
	end
end

function GetMaster(minoriPlayer)
	local reservedCS = LoadData ("ReservedCS")
	if reservedCS[minoriPlayer] and reservedCS[minoriPlayer].Reference then
		return reservedCS[minoriPlayer].Reference
	else
		return nil
	end
end

function IsActivePlayerTurnInitialised()
	local turn = Game.GetGameTurn()
	local str = "player"..tostring(Game.GetActivePlayer()).."_turn"..turn
	local init = LoadModdingData(str)
	return (init and init == 1)
end

function InitializeActivePlayerTurn()
	local bDebug = true
	local turn = Game.GetGameTurn()
	local str = "player"..tostring(Game.GetActivePlayer()).."_turn"..turn
	Dprint("Initialize Active Player Turn = " .. str, bDebug)
	SaveModdingData( str, 1 )
end