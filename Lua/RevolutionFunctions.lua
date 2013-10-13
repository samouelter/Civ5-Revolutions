-- Revolutions
-- Author: Gedemon
-- DateCreated: 3/16/2012 5:58:40 PM
--------------------------------------------------------------

print("Loading Revolutions Functions...")
print("-------------------------------------")

-- gloabal variable
g_HarborsToCapital = {}	
g_HarborsOverSea = {}
g_IndirectRoute = {}

-------------------------------------------------
-- Culture functions 
-------------------------------------------------
function GetPlotCulture( plotKey, cultureMap )
	-- return a table with all civs culture for a plot in cultureMap
	for key, plotCulture in pairs ( cultureMap ) do
		if (key == plotKey) then
			return plotCulture
		end
	end
	return false
end
function GetPlotCulturePercent( plotKey, cultureMap )
	-- return a table with civs culture % for a plot in cultureMap and the total culture
	local bDebugOutput = false
	local plotCulturePercent = {}
	local totalCulture = 0
	for key, plotCulture in pairs (cultureMap) do
		if (key == plotKey) then
			for i = 1, #plotCulture do
				totalCulture = totalCulture + plotCulture[i].Value
			end
			Dprint("Total culture for ("..plotKey..") is : " .. totalCulture , bDebugOutput )
			if (totalCulture > 0) then -- don't mess with the universe
				for i = 1, #plotCulture do
					table.insert (plotCulturePercent, { ID = plotCulture[i].ID, Value = (plotCulture[i].Value / totalCulture * 100) } )
					Dprint(" - ".. plotCulture[i].ID .. " have " .. (plotCulture[i].Value / totalCulture * 100) .. "%" , bDebugOutput )
				end
			end			
			Dprint ("---" , bDebugOutput )
			return plotCulturePercent, totalCulture
		end
	end
	Dprint ("---" , bDebugOutput )
	return false, 0
end
function GetCivPlotCulture ( plotKey, cultureMap, cultureID )	-- plotKey returned by GetPlotKey(plot), cultureID is civilization cultural ID 
																-- return the culture value for civilization (cultureID) of a given plot (plotKey)
	local civsCulture = GetPlotCulture(plotKey, cultureMap)
	if ( civsCulture ) then
		for i, culture in ipairs ( civsCulture ) do
			if culture.ID == cultureID then
				return culture.Value
			end
		end
	end
	return false
end
function ChangeCivPlotCulture ( plotKey, cultureMap, cultureID, value ) -- plotKey: returned by GetPlotKey(plot), cultureID: civ culture ID , value: change to apply
																		-- change a civ culture on a plot by value
																		-- todo : handle negative result
	local bDebugOutput = true

	local civsCulture = GetPlotCulture( plotKey, cultureMap )
	if ( civsCulture ) then
		for i, culture in ipairs ( civsCulture ) do
			if (culture.ID == cultureID) then
				Dprint (" - changing culture value of " .. cultureID .. " at " .. plotKey, bDebugOutput)
				cultureMap[plotKey][i].Value = math.floor(culture.Value + value)
				return cultureMap
			end
		end
		-- no entry for this civ, add it
		Dprint (" - first entry for " .. cultureID .. " at " .. plotKey, bDebugOutput)
		table.insert (cultureMap[plotKey], { ID = cultureID, Value = math.floor(value) } )
		return cultureMap
	else
		-- no entry for this plot, add it
		Dprint (" - plot first entry at (" .. plotKey .. "), first in are " .. cultureID, bDebugOutput)		
		cultureMap[plotKey] = { { ID = cultureID, Value = math.floor(value) } }
		return cultureMap
	end
end

-------------------------------------------------
-- Revolution functions 
-------------------------------------------------

function UpdateSeparatist(iPlayer)
	local t1 = os.clock()
	local bDebug = true

	local player = Players[iPlayer]

	Dprint ("------------------ ", bDebug)
	Dprint ("Updating separatist culture for " .. player:GetName(), bDebug)
	
	local cultureID = GetCivTypeFromPlayer(iPlayer)
	local capital = player:GetCapitalCity()
	if not capital then
		Dprint ("- Aborting, no capital found...", bDebug)
		return
	end
	local bHarborInCapital = ( capital:GetNumBuilding(GameInfo.Buildings.BUILDING_HARBOR.ID) >  0 )

	local cultureMap = MapModData.AH.CultureMap
	local bMapChanged = false

	g_HarborsToCapital = {}
	g_HarborsOverSea = {}
	g_IndirectRoute = {}

	for city in player:Cities() do
		if city ~= capital then
			Dprint ("- checking : " .. city:GetName(), bDebug)
			local airDist, landDist, seaDist, roadDist, railDist = -1, -1, -1, -1, -1 -- initialize distance for each city
			local bIndirectRoute = false
			local bAnotherLand = false
			-- flying distance
			airDist = Map.PlotDistance(city:GetX(), city:GetY(), capital:GetX(), capital:GetY())
			Dprint ("    - Air distance : " .. airDist, bDebug)
			
			if isCityConnected(player, city, capital, "Land", true, nil, PathBlocked) then
				-- distance by land plot
				landDist = getRouteLength()-1
				Dprint ("    - Land distance : " .. landDist, bDebug)
				-- distance by road
				if isCityConnected(player, city, capital, "Road", true, nil, PathBlocked) then
					roadDist = getRouteLength()-1
					Dprint ("    - Road distance : " .. roadDist, bDebug)
				end
				-- distance by rail
				if isCityConnected(player, city, capital, "Railroad", true, nil, PathBlocked) then
					railDist = getRouteLength()-1
					Dprint ("    - Rail distance : " .. railDist, bDebug)
				end
				if city:GetNumBuilding(GameInfo.Buildings.BUILDING_HARBOR.ID) > 0 then 
					g_HarborsToCapital[city] = {Land = landDist, Road = roadDist, Rail = railDist}
					Dprint ("    - Registering harbor city connected to capital by land...", bDebug)
				end
			else
				if capital:Area() ~= city:Area() then
					bAnotherLand = true
				end
				if city:GetNumBuilding(GameInfo.Buildings.BUILDING_HARBOR.ID) > 0 then
					Dprint ("    - Registering harbor city not connected to capital by land...", bDebug)
					g_HarborsOverSea[city] = true
				end
				-- distance by sea
				local seaStr = "Ocean" -- to do : add a check for ability to cross ocean
				if isCityConnected(player, city, capital, seaStr, true, nil, PathBlocked) then
					seaDist = getRouteLength()-1
					Dprint ("    - Maritime distance : " .. seaDist, bDebug)
				end
				if (seaDist < 1) and player:IsCapitalConnectedToCity(city) then 
					Dprint ("    - Registering city connected to capital indirectly...", bDebug)
					--g_IndirectRoute[city] = true
					bIndirectRoute = true
				end
			end

			local era = player:GetCurrentEra()

			local airRatio, landRatio, seaRatio, roadRatio, railRatio = 0, 0, 0, 0, 0 -- default value = city is not far from capital

			local maxAir = g_MaximumDistance[AIR]*g_EraDistanceRatio[era]/100
			Dprint ("    - maxAir = " .. maxAir, bDebug)
			
			local maxLand = g_MaximumDistance[LAND]*g_EraDistanceRatio[era]/100
			Dprint ("    - maxLand = " .. maxLand, bDebug)
			
			local maxSea = g_MaximumDistance[SEA]*g_EraDistanceRatio[era]/100
			Dprint ("    - maxSea = " .. maxSea, bDebug)
			
			local maxRoad = g_MaximumDistance[ROAD]*g_EraDistanceRatio[era]/100
			Dprint ("    - maxRoad = " .. maxRoad, bDebug)
			
			local maxRail = g_MaximumDistance[RAIL]*g_EraDistanceRatio[era]/100
			Dprint ("    - maxRail = " .. maxRail, bDebug)

			if airDist > maxAir then
				airRatio = (airDist - maxAir) * AIR_DIST_FACTOR / 100
				Dprint ("    - airRatio = " .. airRatio, bDebug)
			elseif airDist == -1 then
				airRatio = DISTANCE_MAX_RATIO
			end

			if (landDist > maxLand ) then
				landRatio = (landDist - maxLand) * LAND_DIST_FACTOR / 100
			elseif landDist == -1 then
				landRatio = DISTANCE_MAX_RATIO
			end
			Dprint ("    - landRatio = " .. landRatio, bDebug)

			if (seaDist > maxSea ) then
				seaRatio = (seaDist - maxSea) * SEA_DIST_FACTOR / 100 
			elseif seaDist == -1 then
				seaRatio = DISTANCE_MAX_RATIO
			end
			Dprint ("    - seaRatio = " .. seaRatio, bDebug)

			if (roadDist > maxRoad ) then
				roadRatio = (roadDist - maxRoad) * ROAD_DIST_FACTOR / 100  
			elseif roadDist == -1 then
				roadRatio = DISTANCE_MAX_RATIO
			end
			Dprint ("    - roadRatio = " .. roadRatio, bDebug)

			if (railDist > maxRail ) then
				railRatio = (railDist - maxRail) * RAIL_DIST_FACTOR / 100 
			elseif railDist == -1 then
				railRatio = DISTANCE_MAX_RATIO
			end			
			Dprint ("    - railRatio = " .. railRatio, bDebug)

			if airRatio + landRatio + seaRatio + roadRatio + railRatio > 0 then -- at least one value has changed

				local distFactor = math.min(airRatio, landRatio, seaRatio, roadRatio, railRatio) -- get the minimal factor
				if distFactor > 0 then
					distFactor = distFactor + 1 -- value under 1 generate negative handicap...
					Dprint ("    - City is outside the range of the capital...", bDebug)
					Dprint ("    - Base handicap is : " .. distFactor, bDebug)
					local indirectRouteBonus, anotherLandMalus = 0, 0
					if bIndirectRoute then
						indirectRouteBonus = distFactor * INDIRECT_ROUTE_FACTOR / 100 
					end
					if bAnotherLand then					
						anotherLandMalus = distFactor * ANOTHER_LAND_FACTOR / 100 
					end
					distFactor = distFactor - indirectRouteBonus + anotherLandMalus
					Dprint ("    - Final handicap is : " .. distFactor, bDebug)
					if distFactor >= 1 then -- value under 1 generate negative handicap...
						local convertRatio = math.log10(math.pow( distFactor, 5))

						Dprint ("    - Convert ratio is : " .. convertRatio, bDebug)

						local plotKey = GetPlotKey ( city:Plot() )
						--local civValue = GetCivPlotCulture ( plotKey, cultureMap, cultureID ) or 0
						local separatistValue = GetCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE ) or 0
						local turnFounded = city:GetGameTurnFounded()
						local turn = Game.GetGameTurn()
						if turn > turnFounded + TURN_BEFORE_CHECK_INDEPENDENCE then

							local civsCulture = GetPlotCulture( plotKey, cultureMap )
							if ( civsCulture ) then
								for i, culture in ipairs ( civsCulture ) do									
									if  (culture.ID ~= SEPARATIST_TYPE) then 
										local toConvert = Round(culture.Value * convertRatio  /100)
										Dprint ("         - converting " .. toConvert .. " of " .. culture.ID .. " (".. culture.Value ..") to SEPARATIST (" .. separatistValue .. ")", bDebug)

										cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, culture.ID, - toConvert )
										cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE, toConvert )
										bMapChanged = true
										separatistValue = separatistValue + toConvert
									end
								end
							end

							--[[
							local toConvert = Round(civValue * convertRatio  /100)
							Dprint ("         - converting " .. toConvert .. " of " .. cultureID .. " (".. civValue ..") to SEPARATIST (" .. separatistValue .. ")", bDebug)
							cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, cultureID, - toConvert )
							cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE, toConvert )
							--]]
						else
							Dprint ("         - but still have " .. turnFounded + TURN_BEFORE_CHECK_INDEPENDENCE + 1 - turn .. " turn(s) before generating separatist movement", bDebug)
						end
					else
						Dprint ("    - Handicap is not high enough to produce separatists..." , bDebug)
					end
				else
					Dprint ("    - City is in range of capital, no separatist added..." , bDebug)
				end				
			end
		end
	end

	--[[for city, bool in pairs (g_IndirectRoute) do
		
	end --]]
	local t2 = os.clock()
	if bMapChanged then
		MapModData.AH.CultureMap = cultureMap
	end
	local t3 = os.clock()
	Dprint ("" , bDebug)
	Dprint ("Updating time = " .. t3-t1 .." (saving time = ".. t3-t2 ..")" , bDebug)
	Dprint ("" , bDebug)
end
-- added to GameEvents.PlayerDoTurn

function ReserveCS()

	local bDebug = true

	Dprint ("------------------ ", bDebug)
	Dprint ("Initializing City-States... ", bDebug)

	local numCS = modUserData.GetValue("NumMinorCivs")
	
	Dprint ("  - Number of CS required by the player = " .. numCS, bDebug)

	local loadedCS = {}
	local inactiveCS = {}
	for iPlayer = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
		local player = Players[iPlayer]
		local minorCivID = player:GetMinorCivType()
		-- Does this civ exist ?
		if minorCivID ~= -1 then
			table.insert(loadedCS, iPlayer)
			if player:GetNumUnits() == 0 then
				table.insert(inactiveCS, iPlayer)
			end
		end
	end
	
	Dprint ("  - Number of loaded CS in game = " .. #loadedCS, bDebug)
	Dprint ("  - Number of inactivated CS    = " .. #inactiveCS, bDebug)

	local reservedCS = {}
	--[[
	if #inactiveCS >=  RESERVED_CITY_STATES then
		Dprint ("  - Inactive CS >= RESERVED_CITY_STATES, use them, don't change anything for the active CS")
		for i, iPlayer in ipairs(inactiveCS) do
			reservedCS[iPlayer] = { Action = nil, Type = nil, Reference = nil}
		end
	
	elseif --]]
	if RESERVED_CITY_STATES > #loadedCS then
		Dprint ("  - WARNING : Loaded CS < RESERVED_CITY_STATES, reserving all available CS")
		for i = 1, #loadedCS do
			local iPlayer = loadedCS[i]
			RemoveCiv (iPlayer)
			reservedCS[iPlayer] = { Action = nil, Type = nil, Reference = nil}
		end
	elseif numCS + RESERVED_CITY_STATES > #loadedCS then
		Dprint ("  - Not enough CS active for all request, keeping " .. #loadedCS - RESERVED_CITY_STATES .. " alive..." , bDebug)
		for i = #loadedCS - RESERVED_CITY_STATES, #loadedCS do
			local iPlayer = loadedCS[i]
			RemoveCiv (iPlayer)
			reservedCS[iPlayer] = { Action = nil, Type = nil, Reference = nil}
		end
	else
		Dprint ("  - Keeping " .. numCS .. " alive..." , bDebug)
		for i = numCS + 1, #loadedCS do
			local iPlayer = loadedCS[i]
			RemoveCiv (iPlayer)
			reservedCS[iPlayer] = { Action = nil, Type = nil, Reference = nil}
		end
	end
	SaveData( "ReservedCS", reservedCS )
end
-- called once on first turn

-------------------------------------------------
-- UI functions 
-------------------------------------------------

function RemoveDeadNotifications(Id, type, toolTip, strSummary, iGameValue, iExtraGameData)

	local turn = Game.GetGameTurn()
	local startTurn = LoadData ("GameStartTurn", 0)
	if turn == startTurn then -- no dead civs notifications at start
		if type == NotificationTypes.NOTIFICATION_PLAYER_KILLED then
			Events.NotificationRemoved(Id)
		end
	end
	--[[
	if turn < 2 and Game.IsHotSeat() then  -- no dead civs notifications at start in hotseat
		if type == NotificationTypes.NOTIFICATION_PLAYER_KILLED then
			Events.NotificationRemoved(Id)
		end
	end
	--]]
end
Events.NotificationAdded.Add( RemoveDeadNotifications )
-- added ASAP...

-------------------------------------------------
-- Tested functions 
-------------------------------------------------


function UpdateCultureRelations(iPlayer)

	local t1 = os.clock()

	local bDebug = true
	local player = Players[iPlayer]

	Dprint ("------------------ ", bDebug)
	Dprint ("Update culture relations for " .. player:GetName(), bDebug)

	local cultureRelations = LoadData("CultureRelations", {})
	local cultureGroups = GetCultureGroups(iPlayer)

	for i, data in pairs(cultureGroups) do
		local relationChange = GetRelationChange(iPlayer, data.Type)
		Dprint ("   - relations change with " .. tostring(data.Type) .. " = " .. tostring(relationChange), bDebug)
		
		if cultureRelations[iPlayer][data.Type] then
			cultureRelations[iPlayer][data.Type] = cultureRelations[iPlayer][data.Type] + relationChange
		else
			cultureRelations[iPlayer][data.Type] = relationChange
		end

		local maximumCultureRelation = GetMaximumRelationValue(iPlayer)
		if cultureRelations[iPlayer][data.Type] > maximumCultureRelation then cultureRelations[iPlayer][data.Type] = maximumCultureRelation end
		if cultureRelations[iPlayer][data.Type] < MIN_CULTURE_RELATION then cultureRelations[iPlayer][data.Type] = MIN_CULTURE_RELATION end

	end
	
	local t2 = os.clock()
	SaveData( "CultureRelations", cultureRelations )	
	MapModData.AH.CultureRelations = cultureRelations
	local t3 = os.clock()
	Dprint ("" , bDebug)
	Dprint ("Updating time = " .. t3-t1 .." (saving time = ".. t3-t2 ..")" , bDebug)
	Dprint ("" , bDebug)
end

function InitializeTables()
	Dprint ("------------------ ")
	Dprint ("Initializing Revolution Tables...")
	local cultureRelations = {}
	for iPlayer = 0, GameDefines.MAX_PLAYERS do
		cultureRelations[iPlayer] = {}
	end

	SaveData( "CityCountDown", {} )
	SaveData( "CultureRelations", cultureRelations )	
	MapModData.AH.CultureRelations = cultureRelations
	
end

function GetCultureGroups(iPlayer, bDebug)

	local bDebug = bDebug or false
	local player = Players[iPlayer]

	Dprint ("------------------ ", bDebug)
	Dprint ("Get culture groups for " .. player:GetName(), bDebug)

	local cultureGroups = {}
	local cultureMap = MapModData.AH.CultureMap
	local totalCulture = 0

	for city in player:Cities() do
		local plotKey = GetPlotKey ( city:Plot() )
		Dprint ("  - " .. city:GetName() .. " at " .. plotKey, bDebug)
		local civsCulture = GetPlotCulture(plotKey, cultureMap)
		if ( civsCulture ) then
			for i, culture in ipairs ( civsCulture ) do
				if cultureGroups[culture.ID] then
					cultureGroups[culture.ID] = cultureGroups[culture.ID] + culture.Value
					Dprint ("    - adding " .. culture.Value .. " for " .. culture.ID .. ", total is " .. cultureGroups[culture.ID], bDebug)
					totalCulture = totalCulture + culture.Value
				else
					cultureGroups[culture.ID] = culture.Value
					Dprint ("    - initializing " .. culture.Value .. " for " .. culture.ID, bDebug)
					totalCulture = totalCulture + culture.Value
				end
			end
		end
	end

	-- sorted table
	local sortedCultureGroups = {}
	for type, value in pairs(cultureGroups) do
		table.insert (sortedCultureGroups, { Type = type, Value = value } )
	end
	table.sort(sortedCultureGroups, function(a,b) return a.Value > b.Value end)	
	
	return sortedCultureGroups, totalCulture
end

function UpdateRebels(iPlayer)

	local t1 = os.clock()
	local bDebug = true
	local player = Players[iPlayer]

	Dprint ("------------------ ", bDebug)
	Dprint ("Checking Rebels spawning for " .. player:GetName(), bDebug)

	local player = Players[iPlayer]
	local cultureMap = MapModData.AH.CultureMap
	local cultureRelations = LoadData("CultureRelations")
	if not (cultureRelations[iPlayer]) then
		Dprint ("WARNING : No culture relation table... ")
		return
	end

	for city in player:Cities() do
		local cityPlot = city:Plot()
		local plotKey = GetPlotKey ( cityPlot )
		Dprint ("  - " .. city:GetName() .. " at " .. plotKey, bDebug)
		local civsCulture = GetPlotCulturePercent( plotKey, cultureMap )
		table.sort(civsCulture, function(a,b) return a.Value > b.Value end)
		for i = 1, #civsCulture do
			if (i <= MAX_REBELS_GROUPS) and (civsCulture[i].Value > MIN_RATIO_REBELS_SPAWN) then
				local cultureType = civsCulture[i].ID
				local cultureTypeValue =  GetCivPlotCulture ( plotKey, cultureMap, cultureType )
				if cultureTypeValue >= MIN_CULTURE_REBELS_SPAWN then 
					Dprint ("    -  " .. cultureType .. " has enought strength to rebel, check relation...", bDebug)
					local culturePercentValue = civsCulture[i].Value
					if not (cultureRelations[iPlayer][cultureType]) then
						Dprint ("WARNING : No entry in culture relation table for " .. cultureType)
					else
						local relation = cultureRelations[iPlayer][cultureType]
						if relation < MIN_RELATION_BEFORE_REBELLION then
							Dprint ("    - Bad relation with tile owner for "..cultureType..", check for rebellion spawning...", bDebug)
							local citySize = city:GetPopulation()
							local randNum = math.random( 0, 100 )
							local militaryPresence, martialLawValue = GetNumMilitaryUnitAround(city)
							local ratio = 100
							if city:IsPuppet() then
								ratio = PUPPET_RATIO
							end
							if city:IsOccupied() and not city:IsNoOccupiedUnhappiness() then
								ratio = OCCUPIED_RATIO
							end
							--local spawnChance = (randNum - relation + culturePercentValue - martialLawValue) * ratio / 100
							local cityHappiness = GetCityHappiness(city, cultureMap, cultureRelations)
							local spawnChance = (randNum - cityHappiness - martialLawValue) * ratio / 100 -- cityHappiness can be negative, then raising spawn chance
							-- minimum is 0+MIN_RATIO_REBELS_SPAWN(25)-MIN_RELATION_BEFORE_REBELLION(-75) = 100
							-- maximum is 100+max(culturePercentValue)(100)-MIN_CULTURE_RELATION(-200) = 400						
							local revolt = spawnChance-REVOLT_VALUE
							local revoltChance = math.random( 0, 100 )
							if (revolt > 0) and (citySize >= MIN_REVOLT_CITY_SIZE) and (city:GetResistanceTurns() == 0) and (revoltChance > REVOLT_ABORT_CHANCE) then 
								local cityResistanceTurns = math.min(Round (revolt/CITY_REVOLT_POINTS), MAX_TURNS_REVOLT_CITY, citySize)
								if cityResistanceTurns >= 1 then
									Dprint ("         - city revolting for " .. cityResistanceTurns .. " turn(s)" , bDebug)
									player:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_PROTEST", GetCultureTypeAdj(cultureType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_PROTEST_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())
									city:ChangeResistanceTurns(cityResistanceTurns)
								end
							end
							local rebellion = spawnChance-REBELLION_VALUE
							local rebellionChance = math.random( 0, 100 )
							if (rebellion > 0) and (citySize >= MIN_REBELLION_CITY_SIZE) and (rebellionChance > REBELLION_ABORT_CHANCE) then
								local numRebelsToSpawn = Round (rebellion/UNIT_REBELLION_POINTS)
								if numRebelsToSpawn >= 1 then
									Dprint ("         - spawning " .. numRebelsToSpawn .. " unit(s)" , bDebug)
									local maxSpawnableRebels = Round (citySize*culturePercentValue/100) -- max rebels linked to pop and culture percent
									local numRebels = math.min(numRebelsToSpawn, maxSpawnableRebels)
									local unitType = SpawnRebels( city, iPlayer, cultureType, numRebels) -- spawn numRebels, get type of unit spawned
									if unitType then -- SpawnRebels return false if it can't spawn any unit
										player:AddNotification(NotificationTypes.NOTIFICATION_REBELS, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLT", GetCultureTypeAdj(cultureType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLT_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY(), unitType)
									end
								end
							end
							local revolution = spawnChance-REVOLUTION_VALUE
							local revolutionChance = math.random( 0, 100 )
							if (revolution > 0) and (citySize >= MIN_REVOLUTION_CITY_SIZE) and (revolutionChance > REVOLUTION_ABORT_CHANCE) then
								Dprint ("         - generating revolution !!!" , bDebug)
								local revolutionResult = RevolutionInCity( city, iPlayer, cultureType)
								if revolutionResult then
									player:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLUTION", GetCultureTypeAdj(cultureType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLUTION_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())
								else
									player:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLUTION_ATTEMPT", GetCultureTypeAdj(cultureType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_REVOLUTION_ATTEMPT_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())
								end
							end
						end
					end
				end
			end
		end
	end
	local t2 = os.clock()
	Dprint ("" , bDebug)
	Dprint ("Updating time = " .. t2-t1  , bDebug)
	Dprint ("" , bDebug)
end

function GetCityRebellion(city, cultureMap, cultureRelations, bDebug)

	local bDebug = bDebug or false

	local iPlayer = city:GetOwner()

	local cityPlot = city:Plot()
	local plotKey = GetPlotKey ( cityPlot )
	Dprint ("------------------ ", bDebug)
	Dprint ("Checking Rebels spawning for " .. city:GetName(), bDebug)

	local bNearTrouble = 0
	local bPossibleTrouble = 0
	local bPossibleRebels = 0
	
	local cityPercentRevolt = 0
	local groupPercentRevolt = 0

	local cityPercentRebellion = 0
	local groupPercentRebellion = 0
	
	local cityPercentRevolution = 0
	local groupPercentRevolution = 0

	local from = {}
	from.MilitaryUnits = 0
	from.MartialLaw = 0
	from.IsPuppet = 0
	from.IsOccupied = 0
	from.Affinity = 0
	from.Minimum = 0
	from.Maximum = 0
	from.Random = 0
	from.Representation = 0
	from.Relation = 0

	local civsCulture = GetPlotCulturePercent( plotKey, cultureMap )
	table.sort(civsCulture, function(a,b) return a.Value > b.Value end)
	for i = 1, #civsCulture do
		local cultureType = civsCulture[i].ID
		Dprint (" -  check : " .. cultureType, bDebug)

		if (i <= MAX_REBELS_GROUPS) and (civsCulture[i].Value > MIN_RATIO_REBELS_SPAWN) then
			
			Dprint (" -  enought representation to trigger revolt, check relation...", bDebug)
			
			local culturePercentValue = civsCulture[i].Value
			if not (cultureRelations[iPlayer]) then
				Dprint ("ERROR : cultureRelations is empty for player " .. tostring(iPlayer))
			elseif not (cultureRelations[iPlayer][cultureType]) then
				Dprint ("WARNING : No entry in culture relation table for " .. cultureType)
			else
				local relation = cultureRelations[iPlayer][cultureType]
				Dprint (" -  Relation = " .. relation, bDebug)
				if relation < MIN_RELATION_BEFORE_REBELLION then
					from.Representation = civsCulture[i].Value
					from.Relation = relation
					Dprint ("   - Bad relation with tile owner for "..cultureType..", check for rebellion spawning...", bDebug)
					local militaryPresence, martialLawValue = GetNumMilitaryUnitAround(city)
					from.MilitaryUnits = militaryPresence
					from.MartialLaw = - Round(martialLawValue)
					local ratio = 100
					if city:IsPuppet() then
						ratio = PUPPET_RATIO
						from.IsPuppet = ratio
					end
					if city:IsOccupied() and not city:IsNoOccupiedUnhappiness() then
						ratio = OCCUPIED_RATIO
						from.IsOccupied  = ratio
					end
					local cityHappiness = GetCityHappiness(city, cultureMap, cultureRelations, bDebug)
					from.Affinity = - Round(cityHappiness)
					--local minimum = (culturePercentValue - relation - martialLawValue) * ratio / 100
					--local maximum = (100 + culturePercentValue - relation - martialLawValue) * ratio / 100
					local minimum = (- cityHappiness - martialLawValue) * ratio / 100
					local maximum = (100 - cityHappiness - martialLawValue) * ratio / 100
					from.Minimum = Round(minimum)
					from.Maximum = Round(maximum)
					from.Random = 100
					local revolt = maximum-REVOLT_VALUE
					local rebellion = maximum-REBELLION_VALUE
					local revolution = maximum-REVOLUTION_VALUE
					--if rebellion > 0 then
						local maxRebels = Round (rebellion/UNIT_REBELLION_POINTS)
						local minRebels = Round ((minimum-REBELLION_VALUE)/UNIT_REBELLION_POINTS)
						local maxCityResistance = math.min(Round (revolt/CITY_REVOLT_POINTS),MAX_TURNS_REVOLT_CITY)
						local minCityResistance = math.min(Round ((minimum-REVOLT_VALUE)/CITY_REVOLT_POINTS),MAX_TURNS_REVOLT_CITY)
						Dprint ("     - military = " .. martialLawValue, bDebug)
						Dprint ("     - minimum = " .. minimum, bDebug)
						Dprint ("     - maximum = " .. maximum, bDebug)
						Dprint ("     - minRevolution = " .. minimum-REVOLUTION_VALUE, bDebug)
						Dprint ("     - maxRevolution = " .. revolution, bDebug)
						Dprint ("     - minRebellion = " .. minimum-REBELLION_VALUE, bDebug)
						Dprint ("     - maxRebellion = " .. rebellion, bDebug)
						Dprint ("     - minRevolt = " .. minimum-REVOLT_VALUE, bDebug)
						Dprint ("     - maxRevolt = " .. revolt, bDebug)
						Dprint ("     - maxRebels = " .. maxRebels, bDebug)
						Dprint ("     - minRebels = " .. minRebels, bDebug)
						Dprint ("     - maxCityResistance = " .. maxCityResistance, bDebug)
						Dprint ("     - minCityResistance = " .. minCityResistance, bDebug)

						bNearTrouble = 1
						if maxCityResistance > 0 then bPossibleTrouble = 1 end
						if maxRebels > 0 then bPossibleRebels = 1 end

						cityPercentRevolt = math.min( math.max (Round (revolt*(100-REVOLT_ABORT_CHANCE)/100), 0), 100)
						cityPercentRebellion = math.min( math.max (Round (rebellion*(100-REBELLION_ABORT_CHANCE)/100), 0), 100)
						cityPercentRevolution = math.min( math.max (Round (revolution*(100-REVOLUTION_ABORT_CHANCE)/100), 0), 100)
						
						Dprint ("     - cityPercentRevolt = " .. cityPercentRevolt, bDebug)
						Dprint ("     - cityPercentRebellion = " .. cityPercentRebellion, bDebug)
						Dprint ("     - cityPercentRevolution = " .. cityPercentRevolution, bDebug)

						-- maybe this is not needed anymore, calculation being based on global city happiness, not from specifi culture relation...
						if cityPercentRevolt > groupPercentRevolt then groupPercentRevolt = cityPercentRevolt end
						if cityPercentRebellion > groupPercentRebellion then groupPercentRebellion = cityPercentRebellion end
						if cityPercentRevolution > groupPercentRevolution then groupPercentRevolution = cityPercentRevolution end

					--end
				end
			end
		else
			local culturePercentValue = civsCulture[i].Value
			if cultureRelations[iPlayer][cultureType] then
				local relation = cultureRelations[iPlayer][cultureType]
				if relation < MIN_RELATION_BEFORE_REBELLION then
					from.Relation = relation
				end
			end
		end
	end
	local troubleLevel = bNearTrouble + bPossibleTrouble + bPossibleRebels
	return troubleLevel, groupPercentRevolt, groupPercentRebellion, groupPercentRevolution, from
end

function GetCityHappiness(city, cultureMap, cultureRelations, bDebug)

	local bDebug = bDebug or false

	local cityPlot = city:Plot()
	local iPlayer = city:GetOwner()
	local plotKey = GetPlotKey ( cityPlot )
	Dprint ("   - Getting local happiness in " .. city:GetName() .. " at " .. plotKey, bDebug)
	local civsCulture = GetPlotCulturePercent( plotKey, cultureMap )
	local happiness = 0
	local happy = 0
	local neutral = 0
	local unhappy = 0
	local cityComposition = {}
	for i = 1, #civsCulture do
		local culturePercentValue = civsCulture[i].Value
		local cultureType = civsCulture[i].ID
		if not (cultureRelations[iPlayer][cultureType]) then
			--Dprint ("    - WARNING : No entry in culture relation table for " .. cultureType)
		else
			local relation = cultureRelations[iPlayer][cultureType]
			if relation < THRESHOLD_WOEFUL then
				unhappy = unhappy + culturePercentValue
			elseif relation < THRESHOLD_JOYFUL then
				neutral = neutral + culturePercentValue
			else
				happy = happy + culturePercentValue
			end
			local value = relation*culturePercentValue/100
			happiness = happiness + value
			Dprint ("     - "..cultureType.." happiness = (" .. relation .."*" .. culturePercentValue .. "/100) = " .. value, bDebug)
		end
	end	
	Dprint ("     - local happiness = " .. happiness, bDebug)
	return happiness, happy, neutral, unhappy
end

function GetNumMilitaryUnitAround(city)
	
	local bDebug = false
	Dprint ("------------------ ", bDebug)
	Dprint ("Get military presence around " .. city:GetName(), bDebug)

	local owner = city:GetOwner()
	local unitCount = 0
	local martialLawValue = 0
	for i = 0, city:GetNumCityPlots() - 1, 1 do
		local plot = city:GetCityIndexPlot( i )
		if plot then -- how can this be nil ???
			local plotNumUnits = plot:GetNumUnits()    
			for j = 0, plotNumUnits - 1, 1	do
    			local unit = plot:GetUnit( j )
				if (unit:GetOwner() == owner) and (unit:IsCombatUnit()) and (unit:GetDomainType() == DomainTypes.DOMAIN_LAND) then			
					local distanceToCity = (distanceBetween(city:Plot(), unit:GetPlot()) - 1)
					unitCount = unitCount + 1
					if distanceToCity == 0 then
						martialLawValue = martialLawValue + (MILITARY_BONUS_PER_UNIT*2) -- double value if unit is in city
					else
						martialLawValue = martialLawValue + (MILITARY_BONUS_PER_UNIT/distanceToCity)
					end				
					Dprint ("  - Found "..unit:GetName()..", distance =  " .. distanceToCity .. ", total value = " .. martialLawValue, bDebug)
				end
			end
		end
	end
	return unitCount, martialLawValue
end

function GetFreeSlotsAndRebelID(reservedCS, iPlayer, cultureType)
	local rebelID = nil
	local freeSlots = {}
	for id, data in pairs(reservedCS) do -- debug "id"
		if not data.Action then
			table.insert(freeSlots, id)
		elseif (data.Type == cultureType) and (data.Reference == iPlayer) then
			Dprint ("              - Slot already open, use it...", bDebug)
			rebelID = id
		end
	end
	return freeSlots, rebelID
end

function SpawnRebels( city, iPlayer, cultureType, numRebels)
	local bDebug = true

	local cityCountDown = LoadData ("CityCountDown")
	local cityPlotKey = GetPlotKey ( city:Plot() )
	if cityCountDown[cityPlotKey] then
		Dprint ("        - WARNING: " .. tostring(city:GetName()) .." is already in Revolution, don't spawn rebels vs rebels ! ", bDebug)
		return false
	end

	local player = Players[iPlayer]
	Dprint ("            - Spawning "..cultureType.." Rebels against " .. player:GetName(), bDebug)

	local reservedCS = LoadData ("ReservedCS")
	-- count available CS slots
	local freeSlots, rebelID = GetFreeSlotsAndRebelID(reservedCS, iPlayer, cultureType)

	-- assign rebel slot
	if not rebelID then
		if #freeSlots > 0 then

			rebelID = AssignRebelSlot(freeSlots, iPlayer, cultureType)

		else
			Dprint ("              - WARNING : No free slot !!!", bDebug)
			return false -- can't set rebelID
		end
	end

	-- spawn unit
	local rebel = Players[rebelID]
	local era = player:GetCurrentEra()
	 
	local unitType = g_EraRebels[era]
	local freePlots = {}
	for i = 0, city:GetNumCityPlots() - 1, 1 do
		local plot = city:GetCityIndexPlot( i )
		local plotNumUnits = plot:GetNumUnits()
		if not (plot:IsWater()) and not (plotNumUnits>0) and (plot ~= city:Plot()) and (plot:GetOwner() == city:GetOwner()) then
			table.insert(freePlots, plot)
		end
	end
	Shuffle(freePlots)
	for n, plot in pairs(freePlots) do
		if n <= numRebels then
			if rebel:GetNumMilitaryUnits() < GetMaxRebelUnits(iPlayer, cultureType) then
				Dprint ("              - Spawning rebel unit at " .. GetPlotKey ( plot ), bDebug)
				local newUnit = rebel:InitUnit(unitType, plot:GetX(), plot:GetY())
				newUnit:SetDeployFromOperationTurn(Game.GetGameTurn()+1)
			else
				-- enough rebels, don't spawn more, but add damage to city instead...
				local damage = Round((GameDefines.MAX_CITY_HIT_POINTS - city:GetDamage())*CITY_DAMAGE_PERCENT_REBELS/100)
				city:ChangeDamage(damage)
			end
		end
	end
	rebel:AddTemporaryDominanceZone (city:GetX(), city:GetY())

	return unitType
end

function FreeReservedCS()

	local bDebug = true
	Dprint ("------------------ ", bDebug)
	Dprint ("Removing uneeded reservation for CS...", bDebug)

	local cultureMap = MapModData.AH.CultureMap
	local reservedCS = LoadData ("ReservedCS")
	local civToRemove = {}
	local cultureToRemove = {}
	for id, data in pairs(reservedCS) do
		if data.Action then
			local player = Players[id]
			if not player:IsAlive() then
				Dprint ("  - Found dead rebels : " .. player:GetName(), bDebug)

				local cityStateType = GetCivTypeFromPlayer(id)

				local tagStr = string.gsub (cityStateType, "MINOR_CIV_", "")

				SetText ("RESERVED", "TXT_KEY_CITYSTATE_" .. tagStr)
				SetText ("RESERVED", "TXT_KEY_CITYSTATE_" .. tagStr .. "_ADJ")
				SetText ("Rebels Cities", "TXT_KEY_CIV5_" .. tagStr .. "_TEXT")

				RefreshText()

				reservedCS[id].Action = nil
				reservedCS[id].Type = nil
				reservedCS[id].Reference = nil
				local rebel = Players[id]
				for iPlayer = 0, GameDefines.MAX_PLAYERS do
					local player = Players[iPlayer]
					if player and (id ~= iPlayer) and not player:IsBarbarian() and player:IsEverAlive() then
						MakePermanentPeace(id, iPlayer)
						if not player:IsMinorCiv() then
							rebel:ChangeMinorCivFriendshipWithMajor(iPlayer, - rebel:GetMinorCivFriendshipWithMajor(iPlayer))
						end
					end
				end

				table.insert(civToRemove, cityStateType)
			end
		end
	end

	-- Removing the rebels from the face of earth ! <insert hysterical laugh here>
	for plotKey, plotCulture in pairs (cultureMap) do
		for index, culture in pairs ( plotCulture ) do
			for j, cityStateType in pairs(civToRemove) do
				if culture.ID == cityStateType then
					Dprint (" - marking plot " .. tostring(plotKey) .." to remove " .. tostring(cityStateType), bDebug)	
					table.insert(cultureToRemove, {PlotKey = plotKey, Index = index})
				end
			end
		end
	end	
	for i, data in pairs(cultureToRemove) do
		Dprint (" - removing culture from plot " .. tostring(data.PlotKey) .." for " .. tostring(cultureMap[data.PlotKey][data.Index].ID), bDebug)	
		table.remove ( cultureMap[data.PlotKey], data.Index )
	end
	SaveData( "ReservedCS", reservedCS )
	MapModData.AH.CultureMap = cultureMap
end


function RevolutionInCity( city, iPlayer, cultureType)
	local bDebug = true
	local player = Players[iPlayer]
	
	Dprint ("            - Revolution started by "..cultureType.." Rebels against " .. player:GetName(), bDebug)

	local reservedCS = LoadData ("ReservedCS")
	local cityCountDown = LoadData ("CityCountDown")

	local cityPlotKey = GetPlotKey ( city:Plot() )


	if cityCountDown[cityPlotKey] then
		Dprint ("            - WARNING: " .. tostring(city:GetName()) .." is already in Revolution ! ", bDebug)
		return false
	end

	-- get available CS slots
	local freeSlots, rebelID = GetFreeSlotsAndRebelID(reservedCS, iPlayer, cultureType)

	-- damage units in city if any
	local isGarisonned = false
	for i = 0, city:Plot():GetNumUnits() - 1, 1 do
    	local unit = city:Plot():GetUnit(i);
		if unit and (unit:GetOwner() == iPlayer) then
			if unit:IsCombatUnit() then
				local damage = UNIT_DAMAGE_REVOLUTION + math.random( 0, UNIT_DAMAGE_REVOLUTION_VAR )
				if damage > unit:GetCurrHitPoints() then
					Players[unit:GetOwner()]:AddNotification(NotificationTypes.NOTIFICATION_UNIT_DIED, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_GARRISON_LOST", tostring(unit:GetName()), GetCultureTypeAdj(cultureType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_GARRISON_LOST_SHORT", city:GetName()), unit:GetX(), unit:GetY(), unit:GetUnitType(), unit:GetUnitType())				
				end
				unit:ChangeDamage(damage)
				isGarisonned = true
			else -- civilian units are killed during the revolution
				unit:Kill()
			end				
		elseif not unit then			
			Dprint ("  - WARNING: unit = nil using city:Plot():GetUnit(i) with i = " .. tostring(i) .. " and city:Plot():GetNumUnits() = ".. tostring(city:Plot():GetNumUnits()) .. " at plot " .. tostring(city:Plot():GetX()) .. " , " .. tostring(city:Plot():GetY()))
		end
	end

	if isGarisonned then	
		Dprint ("            - " .. tostring(city:GetName()) .." has military units preventing the revolution...", bDebug)
		return false
	end

	-- assign rebel slot
	if not rebelID then
		if #freeSlots > 0 then
			
			rebelID = AssignRebelSlot(freeSlots, iPlayer, cultureType)

		else
			Dprint ("              - WARNING : No free slot !!!", bDebug)
			local damage = CITY_DAMAGE_REVOLUTION + math.random( 0, CITY_DAMAGE_REVOLUTION_VAR )
			city:ChangeDamage(damage)
			return false -- can't set rebelID
		end
	end

	-- Flipping city to rebels side...
	
	city:ChangeDamage(math.random( 0, CITY_DAMAGE_REVOLUTION_VAR ))

	local rebel = Players[rebelID]	

	GiveCityToPlayer(city, rebel)

	cityCountDown[cityPlotKey] = {}
	cityCountDown[cityPlotKey].CountDown = REVOLUTION_CHOICE_COUNTDOWN
	cityCountDown[cityPlotKey].RebelID = rebelID

	SaveData( "CityCountDown", cityCountDown )

	return true -- revolution started
end

function InitializeRevolutionFunctions()
	-- replace player:GetName() by custom test function...
	local p = getmetatable(Players[0]).__index
	p.OldGetName = p.GetName
	p.GetName = function(self) return self:OldGetName() end
end


function GetGlobalHappiness(iPlayer, cultureRelations, bDebug)

	local bDebug = bDebug or false

	Dprint ("   - Getting Global happiness for iPlayer = " .. iPlayer, bDebug)

	local globalHappiness = 0
	local globalVariation = 0

	local cultureGroups, totalCulture = GetCultureGroups(iPlayer)

	if cultureRelations[iPlayer] then -- there could be no entries in first turns.

		for i, data in pairs(cultureGroups) do
			if cultureRelations[iPlayer][data.Type] then -- there could be no entries in first turns.
				local relation = cultureRelations[iPlayer][data.Type]
				local variation = GetRelationChange(iPlayer, data.Type)
				local maximumRelation = GetMaximumRelationValue(iPlayer)
				if relation + variation > maximumRelation then
					variation = maximumRelation - relation
				end
				
				if relation + variation < MIN_CULTURE_RELATION then
					variation = MIN_CULTURE_RELATION - relation
				end

				local culturePercent = Round(data.Value / totalCulture * 100)

				local relationRatio = relation*culturePercent/100
				globalHappiness = globalHappiness + relationRatio

				local variationRatio = variation*culturePercent/100
				globalVariation = globalVariation + variationRatio

				Dprint ("     - "..data.Type.." happiness = (" .. relation .."*" .. culturePercent .. "/100) = " .. relationRatio, bDebug)
				Dprint ("     - "..data.Type.." variation = (" .. variation .."*" .. culturePercent .. "/100) = " .. variationRatio, bDebug)
			end
		end	
	end
	Dprint ("     - Global happiness = " .. globalHappiness, bDebug)
	Dprint ("     - Global variation = " .. globalVariation, bDebug)
	return globalHappiness, globalVariation
end

function GetPlotRelationHelpString(plot, cultureMap, cultureRelations)
	
	local plotKey = GetPlotKey ( plot )
	local plotCulture = GetPlotCulture( plotKey, cultureMap )

	table.sort(plotCulture, function(a,b) return a.Value > b.Value end)

	local AddedString = ""
	local bShowRevolutionInfo = false
	local owner = plot:GetOwner()

	if (owner ~= -1) and (cultureRelations ~= nil) and cultureRelations[owner] then
		bShowRevolutionInfo = true
	end

	local totalCulture = 0
	for i = 1, #plotCulture do
		totalCulture = totalCulture + plotCulture[i].Value
	end
	if (totalCulture > 0) then -- don't mess with the universe
		AddedString = AddedString .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RELATIONS_TITLE")
		for i = 1, #plotCulture do
			local cultureID = plotCulture[i].ID
			local civAdj = GetCultureTypeAdj(cultureID)

			AddedString = AddedString .. "[NEWLINE]" .. Round(plotCulture[i].Value / totalCulture * 100) .. "%  " .. civAdj

			if bShowRevolutionInfo and cultureRelations[owner][cultureID] then
				AddedString = AddedString .. "  (" .. GetRelationValueString(cultureRelations[owner][cultureID]) .. ")"
			end

		end
	end
	return AddedString
end

function GetRelationChange(iPlayer, cultureType, bDebug)
	
	local bDebug = bDebug or false

	Dprint ("- Get Relation change for iPlayer = " .. iPlayer, bDebug)

	local data = {}
	local from = {}
	
	data.iPlayer = iPlayer
	data.cultureType = cultureType
	data.player = Players[iPlayer]
	data.teamID = data.player:GetTeam()
	data.playerCultureID = GetCivTypeFromPlayer(iPlayer)
	if cultureType ~= SEPARATIST_TYPE then
		data.otherPlayer = Players[ GetiPlayerFromCivType (cultureType, true) ]
		data.otherTeam = Teams[data.otherPlayer:GetTeam()]
	end
	data.happiness = data.player:GetHappiness() - data.player:GetUnhappiness()
		
	local globalChange = 0

	for textKey, relationChange in pairs(g_RelationChange) do		
		Dprint ("  - Testing " .. tostring(textKey) .. ", condition = " .. tostring(relationChange.Condition(data)) , bDebug)
		if relationChange.Condition(data) then
			local change = relationChange.Change(data)
			globalChange = globalChange + change
			table.insert (from, { TextKey = textKey, Change = change } )
		end
	end
	
	return globalChange, from
end

g_RelationChange = {
	["TXT_KEY_RELATION_CHANGE_FROM_GLOBAL_HAPPINESS"] = {	
		Change = (function(data)
			return data.happiness
		end),
		Condition = (function(data)
			if data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_SEPARATIST_BASE"] = {	
		Change = (function(data)
			return SEPARATIST_RELATION_CHANGE
		end),
		Condition = (function(data)
			if data.cultureType == SEPARATIST_TYPE then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_OWN_BASE"] = {	
		Change = (function(data)
			return OWN_CULTURE_RELATION_CHANGE
		end),
		Condition = (function(data)
			if data.cultureType == data.playerCultureID then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_FOREIGN_BASE"] = {	
		Change = (function(data)
			return FOREIGN_CULTURE_RELATION_CHANGE
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and data.otherPlayer:IsAlive() then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_HAPPINESS_DIFFERENCE"] = {	
		Change = (function(data)
			return data.happiness - (data.otherPlayer:GetHappiness() - data.otherPlayer:GetUnhappiness())
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and data.otherPlayer:IsAlive() then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_WAR"] = {	
		Change = (function(data)
			return WAR_MALUS_RELATION_CHANGE
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and data.otherPlayer:IsAlive()
			   and data.otherTeam:IsAtWar(data.teamID) then
				return true
			else
				return false
			end
		end),
	},
	---[[
	["TXT_KEY_RELATION_CHANGE_FROM_DOF"] = {	
		Change = (function(data)
			return DOF_BONUS_RELATION_CHANGE
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and data.otherPlayer:IsAlive() then
				if data.otherPlayer:IsDoF(data.iPlayer) then
					return true
				elseif data.otherPlayer:IsMinorCiv() and (data.otherPlayer:GetMinorCivFriendshipWithMajor(data.iPlayer) > GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"]) then
					return true
				end
			end
			return false
		end),
	}, --]]
	---[[
	["TXT_KEY_RELATION_CHANGE_FROM_DENOUNCED"] = {	
		Change = (function(data)
			return DENOUNCED_MALUS_RELATION_CHANGE
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and data.otherPlayer:IsAlive() then
				if data.otherPlayer:IsDenouncedPlayer(data.iPlayer) then
					return true
				elseif data.otherPlayer:IsMinorCiv() and (data.otherPlayer:GetMinorCivFriendshipWithMajor(data.iPlayer) < GameDefines["FRIENDSHIP_THRESHOLD_NEUTRAL"]) then
					return true
				end
			end
			return false
		end),
	}, --]]
	["TXT_KEY_RELATION_CHANGE_FROM_DEAD_CIV"] = {	
		Change = (function(data)
			return data.happiness
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID)
			   and not data.otherPlayer:IsAlive() then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_LIBERTY"] = {	
		Change = (function(data)
			return LIBERTY_SEPARATIST_RELATION_CHANGE
		end),
		Condition = (function(data)
			if (data.cultureType == SEPARATIST_TYPE)
			   and data.player:HasPolicy(GameInfo.Policies["POLICY_LIBERTY"].ID) then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_LIBERTY_FINISHER"] = {	
		Change = (function(data)
			return LIBERTY_FINISHER_SEPARATIST_RELATION_CHANGE
		end),
		Condition = (function(data)
			if (data.cultureType == SEPARATIST_TYPE)
			   and data.player:HasPolicy(GameInfo.Policies["POLICY_LIBERTY_FINISHER"].ID) then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_CITIZENSHIP"] = {	
		Change = (function(data)
			return CITIZENSHIP_FOREIGN_RELATION_CHANGE
		end),
		Condition = (function(data)
			if not (data.cultureType == SEPARATIST_TYPE or data.cultureType == data.playerCultureID) -- Foreign CG
			   and data.otherPlayer:IsAlive()
			   and data.player:HasPolicy(GameInfo.Policies["POLICY_CITIZENSHIP"].ID) then
				return true
			else
				return false
			end
		end),
	},
	["TXT_KEY_RELATION_CHANGE_FROM_REPRESENTATION"] = {	
		Change = (function(data)
			return REPRESENTATION_ALL_RELATION_CHANGE
		end),
		Condition = (function(data)
			if data.player:HasPolicy(GameInfo.Policies["POLICY_REPRESENTATION"].ID) then
				return true
			else
				return false
			end
		end),
	},
}

function GetMaximumRelationValue(iPlayer)
	player = Players[iPlayer]
	local maximumRelation = MAX_CULTURE_RELATION
	if player:HasPolicy(GameInfo.Policies["POLICY_MERITOCRACY"].ID) then
		maximumRelation = maximumRelation + MAX_CULTURE_RELATION_MERITOCRACY_CHANGE
	end
	return maximumRelation
end

function RevolutionOutcome()

	local t1 = os.clock()
	local bDebug = true
	Dprint ("------------------ ", bDebug)
	Dprint ("Check for Revolutions Outcome...", bDebug)
	
	local cultureMap = MapModData.AH.CultureMap
	local cityCountDown = LoadData ("CityCountDown")
	local reservedCS = LoadData ("ReservedCS")

	local toRemove = {}

	for plotKey, data in pairs(cityCountDown) do

		local possibleChoice = {}

		cityPlot = GetPlotFromKey ( plotKey )
		city = cityPlot:GetPlotCity()
		if city then
			if data.CountDown < 1 then -- now we can make a choice...
				local rebelID = city:GetOwner()
				if rebelID == data.RebelID then
					Dprint ("- " ..tostring(city:GetName()) .. " can make a choice...", bDebug)

					local civsCulture = GetPlotCulturePercent( plotKey, cultureMap )
					local masterID = reservedCS[rebelID].Reference
					local originalType = reservedCS[rebelID].Type
					local masterType = GetCivTypeFromPlayer(masterID)
					local rebelType = GetCivTypeFromPlayer(rebelID)
					local minimum_happiness = MINIMUM_HAPPINESS_TO_JOIN * Game:GetCurrentEra()

					Dprint ("    - Minimum happiness value to join = " ..tostring(minimum_happiness), bDebug)

					--table.sort(civsCulture, function(a,b) return a.Value > b.Value end)
					
					for i = 1, #civsCulture do
						local cultureType = civsCulture[i].ID
						Dprint ("      - checking " ..tostring(cultureType), bDebug)
						if cultureType ~= SEPARATIST_TYPE and cultureType ~= rebelType then
							local player = Players[GetiPlayerFromCivType (cultureType)]
							if player then -- don't check for alive here, could be great to revive dead player !
								local happiness = player:GetHappiness() - player:GetUnhappiness()
								if player:IsAlive() then
									happiness = player:GetHappiness() - player:GetUnhappiness()
									local team = Teams[player:GetTeam()]
									local rebelTeamID = Players[rebelID]:GetTeam()
									if team:IsAtWar(rebelTeamID) then
										happiness = happiness - AT_WAR_HAPPINESS_MALUS
									end
								else
									happiness = DEAD_PLAYER_HAPPINESS
								end
								if (cultureType == originalType and cultureType ~= masterType) then -- the rebels are not separatists from the master civilization culture, but have emerged from the civilization culture we are checking
									happiness = happiness + SAME_CULTURE_HAPPINESS_BONUS
								end						
								if (cultureType == masterType) then -- the rebels are separatists from the master civilization, they may decide to rejoin it, but they must have enough motivation !
									happiness = happiness - MASTER_CULTURE_HAPPINESS_MALUS
								end
								local cultureStrength = GetCivPlotCulture ( plotKey, cultureMap, cultureType )
								-- To do: add other factor in the "joining value"
								local joiningValue =  ( cultureStrength / 2 ) * happiness
								Dprint ("      - culture value = " ..tostring(cultureStrength) .. ", 'happiness' value = " ..tostring(happiness).. ", joigning value = " ..tostring(joiningValue), bDebug)
								if (happiness >= minimum_happiness) then
									table.insert(possibleChoice, {ID = cultureType, Value = cultureStrength, Happy = joiningValue})
								end
							end
						end
					end
					table.sort(possibleChoice, function(a,b) return a.Happy > b.Happy end)
					
					Dprint ("   - # possible choice = " ..tostring(#possibleChoice), bDebug)

					local rebelValue = GetCivPlotCulture ( plotKey, cultureMap, rebelType ) or 0
					Dprint ("   - rebel culture value = " ..tostring(rebelValue), bDebug)					

					local separatistValue = GetCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE ) or 0
					Dprint ("   - separatist culture value = " ..tostring(separatistValue), bDebug)

					local bestChoice = nil
					local bestChoiceValue = 0
					for i = 1, #possibleChoice do
						local cultureType = possibleChoice[i].ID
						if bestChoice then
							if possibleChoice[i].Value > bestChoiceValue + rebelValue + separatistValue then
								bestChoice = cultureType
							end
						else
							bestChoice = cultureType
							bestChoiceValue = possibleChoice[i].Value
						end
					end

					if bestChoice then
						Dprint ("   - The revolutionnary comite has decided, the city will join : " ..tostring(bestChoice), bDebug)
						local iPlayer = GetiPlayerFromCivType (bestChoice)
						local player = Players[iPlayer]
						
						-- Update culture map
						cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, bestChoice, rebelValue + separatistValue )
						cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, rebelType, - rebelValue )
						cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE, - separatistValue )

						-- Random crash reports here, to check !

						MapModData.AH.CultureMap = cultureMap -- before changing city owner !

						GiveCityToPlayer(city, player)

						table.insert(toRemove, plotKey)

						
						player:AddNotification(NotificationTypes.NOTIFICATION_CAPITAL_RECOVERED, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_TO_PLAYER", GetCultureTypeAdj(rebelType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_TO_PLAYER_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())

						Players[masterID]:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_FROM_PLAYER", GetCultureTypeAdj(rebelType), city:GetName(), tostring(player:GetName())), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_FROM_PLAYER_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())

					elseif (REVOLUTION_SPAWN_NEW_CS) and (math.random( 0, 100 ) < NEW_CS_PERCENT_CHANCE ) then -- can spawn new CS ?
						Dprint ("   - The revolutionnary comite is looking at the possibility of a declaration of independance...", bDebug)

						local freeSlots = GetFreeSlotsAndRebelID(reservedCS, masterID, rebelType)
						if #freeSlots > MIN_FREE_SLOTS_FOR_NEW_CS then
							local newCivID = GetRebelIDForArtStyle(freeSlots, masterID, rebelType)
							if newCivID then
								player = Players[newCivID]
								playerType = GetCivTypeFromPlayer(newCivID)
								Dprint ("   - ".. tostring(city:GetName()) .." is making a declaration of independance !", bDebug)

								-- Update culture map
								cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, playerType, rebelValue + separatistValue )
								cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, rebelType, - rebelValue )
								cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE, - separatistValue )
								MapModData.AH.CultureMap = cultureMap -- before changing city owner !

								GiveCityToPlayer(city, player)

								table.insert(toRemove, plotKey)

																
								Players[masterID]:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_INDEPENDENCE", GetCultureTypeAdj(rebelType), city:GetName(), tostring(player:GetName())), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_INDEPENDENCE_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())
								city:SetName(player:GetName())
							else
								Dprint ("   - But no available CS was found.", bDebug)
							end
						else						
							Dprint ("   - But there are not enough free slots. #left = " .. tostring(#freeSlots) .. ", #required = ".. tostring(MIN_FREE_SLOTS_FOR_NEW_CS), bDebug)
						end
					elseif data.CountDown < -REVOLUTION_FORCE_CHOICE_COUNTDOWN then -- must make a choice now !

						local closeCityDistance = 1000
						local closeiPlayer = nil
						for id = 0, GameDefines.MAX_PLAYERS do
							if (id ~= masterID) and (id ~= rebelID) then
								local closeCity, distance = GetCloseCity ( id, cityPlot , true)
								if closeCity then
									if distance < closeCityDistance then
										closeCityDistance = distance
										closeiPlayer = id
									end
								end
							end
						end
						if closeiPlayer then
							local player = Players[closeiPlayer]
							local playerType = GetCivTypeFromPlayer(closeiPlayer)
							Dprint ("   - The revolutionnary comite has finally decided, the city will join : " ..tostring(player:GetName()), bDebug)

							-- Update culture map
							cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, playerType, rebelValue + separatistValue )
							cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, rebelType, - rebelValue )
							cultureMap = ChangeCivPlotCulture ( plotKey, cultureMap, SEPARATIST_TYPE, - separatistValue )
							MapModData.AH.CultureMap = cultureMap -- before changing city owner !

							GiveCityToPlayer(city, player)

							table.insert(toRemove, plotKey)

							player:AddNotification(NotificationTypes.NOTIFICATION_CAPITAL_RECOVERED, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_TO_PLAYER", GetCultureTypeAdj(rebelType), city:GetName()), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_TO_PLAYER_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())

							Players[masterID]:AddNotification(NotificationTypes.NOTIFICATION_CITY_LOST, Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_FROM_PLAYER", GetCultureTypeAdj(rebelType), city:GetName(), tostring(player:GetName())), Locale.ConvertTextKey("TXT_KEY_REVOLUTION_NOTIFICATION_CITY_FLIPPED_FROM_PLAYER_SHORT", city:GetName()), cityPlot:GetX(), cityPlot:GetY())							
							
						end

					else
						Dprint ("   - The revolutionnary comite can't decide yet. CountDown is " .. tostring(data.CountDown) .. ", forced choice at " .. tostring(-REVOLUTION_FORCE_CHOICE_COUNTDOWN), bDebug)
						data.CountDown = data.CountDown - 1
					end

				else -- city is not owned by rebels anymore... 
					Dprint ("- " ..tostring(city:GetName()) .. " is not in the hands of rebels anymore, removing...", bDebug)
					table.insert(toRemove, plotKey)
				end
			else
				Dprint ("- " ..tostring(city:GetName()) .. " is still in revolutionnary unrest for " .. tostring(data.CountDown) .. " turns", bDebug)
				data.CountDown = data.CountDown - 1 -- wait ? no bug ? I'm really modifying cityCountDown table here ? I'm learning everyday...
			end
		else
			Dprint ("- ERROR : city is nil in RevolutionOutcome() for plot " .. tostring(plotKey))
		end
	end
	
	for i, plotKey in pairs(toRemove) do -- remove cities that are no more owned by rebels from the table
		cityCountDown[plotKey] = nil
	end
	local t2 = os.clock()
	SaveData( "CityCountDown", cityCountDown )	
	local t3 = os.clock()
	Dprint ("" , bDebug)
	Dprint ("Revolution Outcome Updating time = " .. t3-t1 .." (saving time = ".. t3-t2 ..")" , bDebug)
	Dprint ("" , bDebug)
	
	Dprint ("------------------ ", bDebug)
end


function GiveCityToPlayer(city, player)
	local bDebug = true
	Dprint ("--- Giving " .. tostring(city:GetName()) .. " to " .. tostring(player:GetName()), bDebug)
	player:AcquireCity(city, false, true)

	Dprint ("--- Remove resistance", bDebug)
	if city:GetResistanceTurns() > 0 then
		city:ChangeResistanceTurns(-city:GetResistanceTurns())
	end

	Dprint ("--- Remove Puppet and Razing for AI", bDebug)
	if not player:IsHuman() then
		city:SetPuppet(false)
		if city:IsRazing() then
			city:DoTask(TaskTypes.TASK_UNRAZE, -1, -1, -1)
		end
	end

	Dprint ("--- Remove Occupied flag", bDebug)
	if city:IsOccupied() then
		city:SetOccupied(false)
	end
end

function OnCityCapture(iOldOwner, bIsCapital, x, y, iNewOwner, iPop, bConquest)

	if not IsRebellingAgainst(iNewOwner, iOldOwner) then -- to do: case when rebels take a city from another civ than the original civ...
		return
	end

	if not bConquest then -- to do: case when a city is given to rebels...
		return
	end
	
	local bDebug = true

	local cityCountDown = LoadData ("CityCountDown")

	local cityPlot = GetPlot (x,y)
	local cityPlotKey = GetPlotKey ( cityPlot )

	if cityCountDown[cityPlotKey] then -- already in revolution
		return false
	end
	
	Dprint ("------------------ ", bDebug)
	Dprint ("Revolutionnary troops have captured a city !", bDebug)
	
	cityCountDown[cityPlotKey] = {}
	cityCountDown[cityPlotKey].CountDown = REVOLUTION_CHOICE_COUNTDOWN
	cityCountDown[cityPlotKey].RebelID = iNewOwner

	local city = cityPlot:GetPlotCity()
	if city and city:IsRazing() then
		city:DoTask(TaskTypes.TASK_UNRAZE, -1, -1, -1)
	end

	SaveData( "CityCountDown", cityCountDown )

end

function UpdateRebelsTextOnLoad()

	local reservedCS = LoadData ("ReservedCS")

	for rebelID, data in pairs(reservedCS) do
		if data.Action then
			SetRebelsText(rebelID, reservedCS)
		end
	end

	RefreshText()
end

function SetRebelsText(rebelID, reservedCS)

	local CityStateType = GetCivTypeFromPlayer (rebelID)
	local cultureType = reservedCS[rebelID].Type
	local adj = ""
	local adj = ""

	if cultureType == SEPARATIST_TYPE then

		local masterID = reservedCS[rebelID].Reference
		local masterType = GetCivTypeFromPlayer(masterID)

		adj = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_REBELS_TYPE_SEPARATIST", GetCultureTypeAdj(masterType))
		tagStr = string.gsub (CityStateType, "MINOR_CIV_", "")

	else
		adj = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_REBELS_TYPE_REBEL", GetCultureTypeAdj(cultureType))
		tagStr = string.gsub (CityStateType, "MINOR_CIV_", "")
	end
			
	SetText (adj, "TXT_KEY_CITYSTATE_" .. tagStr)
	SetText (adj, "TXT_KEY_CITYSTATE_" .. tagStr .. "_ADJ")
	SetText ("Rebels Cities", "TXT_KEY_CIV5_" .. tagStr .. "_TEXT")

	PreGame.SetCivilizationAdjective(rebelID, adj)
	PreGame.SetCivilizationDescription(rebelID, adj)
end

function GetMaxRebelUnits(iPlayer, rebelCultureType)

	local bDebug = true

	local player = Players[iPlayer]
	local totalPopulation = player:GetTotalPopulation()
	local rebelPopulation = 0
	local cultureGroups, totalCulture = GetCultureGroups(iPlayer)
	for i, data in pairs(cultureGroups) do
		if (data.Type == rebelCultureType) then
			local culturePercent = data.Value / totalCulture * 100
			rebelPopulation = Round( totalPopulation  /  100 * culturePercent)
		end
	end
	local maxRebelUnits = Round (rebelPopulation * MAX_REBELS_UNITS_PER_POPULATION)
	Dprint ("- Max units for " .. tostring(rebelCultureType) .. " rebels in ".. tostring(player:GetName()) .." territory = " .. tostring(maxRebelUnits), bDebug)

	return maxRebelUnits
end

function AssignRebelSlot(freeSlots, iPlayer, rebelCultureType)
	local bDebug = true
	Dprint ("              - Preparing new slot for " .. tostring(rebelCultureType), bDebug)

	local reservedCS = LoadData ("ReservedCS")
	local rebelID = GetRebelIDForArtStyle(freeSlots, iPlayer, rebelCultureType)	
			
	reservedCS[rebelID].Action = "REVOLT"
	reservedCS[rebelID].Type = rebelCultureType
	reservedCS[rebelID].Reference = iPlayer

	SetRebelsText(rebelID, reservedCS)
	RefreshText()

	-- Set very bad relation with everyone
	local rebel = Players[rebelID]
	for player_num = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local player = Players[player_num]
		if ( player:IsEverAlive() ) then
			rebel:ChangeMinorCivFriendshipWithMajor(player_num, - rebel:GetMinorCivFriendshipWithMajor(player_num) + INITIAL_REBELS_RELATION)
		end
	end

	DeclarePermanentWar(rebelID, iPlayer)

	SaveData( "ReservedCS", reservedCS )

	return rebelID
end



function GetRebelIDForArtStyle(freeSlots, iPlayer, rebelCultureType)

	local bDebug = true
	
	local rebelID = freeSlots[1] -- take the first free slot

	-- Find art style of rebel culture group
	local rebelCiv = GetCivIDFromiPlayer (rebelID)
	local playerCiv = GetCivIDFromiPlayer (iPlayer)

	local playerArtStyle = "ARTSTYLE_EUROPEAN" -- default	
	if Players[iPlayer]:IsMinorCiv() then
		playerArtStyle = GameInfo.MinorCivilizations[playerCiv].ArtStyleType
	else
		playerArtStyle = GameInfo.Civilizations[playerCiv].ArtStyleType
	end
	Dprint ("              - master civ ArtStyle : " .. tostring(playerArtStyle), bDebug)

	local rebelArtStyle = playerArtStyle -- Separatist will use player style
	if GameInfo.MinorCivilizations[rebelCultureType] then
		rebelArtStyle = GameInfo.MinorCivilizations[rebelCultureType].ArtStyleType
	elseif GameInfo.Civilizations[rebelCultureType] then
		rebelArtStyle = GameInfo.Civilizations[rebelCultureType].ArtStyleType
	end
	Dprint ("              - rebel culture ArtStyle : " .. tostring(rebelArtStyle), bDebug)

	Dprint ("              - First loop civ ArtStyle : " .. tostring(GameInfo.MinorCivilizations[rebelCiv].ArtStyleType), bDebug)

	-- Now try to find a corresponding artstyle in the available CS if the first one didn't match...
	if rebelArtStyle ~= GameInfo.MinorCivilizations[rebelCiv].ArtStyleType then
		Dprint ("              - try to find corresponding ArtStyle : " .. tostring(rebelArtStyle), bDebug)
		for i, id in pairs(freeSlots) do 
			local civID = GetCivIDFromiPlayer (id)
			if GameInfo.MinorCivilizations[civID] then
				Dprint ("                  - loop civ ArtStyle : " .. tostring(GameInfo.MinorCivilizations[civID].ArtStyleType) .. " for minorciv " .. tostring(GameInfo.MinorCivilizations[civID].Type), bDebug)
				if rebelArtStyle == GameInfo.MinorCivilizations[civID].ArtStyleType then
					rebelID = id
				end
			end
		end
	end
	return rebelID
end

function RebelAttrition(iPlayer)
	local reservedCS = LoadData ("ReservedCS")
	if reservedCS[iPlayer] and reservedCS[iPlayer].Action == "REVOLT" then
		local player = Players[iPlayer]
		if not player:IsAlive() then
			return
		end
		local bDebug = true
		Dprint ("------------------ ", bDebug)
		Dprint ("Apply Revolution Attrition on Rebels units for " .. tostring (player:GetName()), bDebug)
		for unit in player:Units() do
			unit:ChangeDamage(REBELS_UNITS_ATTRITION)
		end
	end
end

function InitializeGameOption()
	if not OVERRIDE_OPTION_MENU then
		-- initialize rules based on selected options
		if(PreGame.GetGameOption("GAMEOPTION_REVOLUTION_SPAWN_NEW_CS") ~= nil) then
			if (PreGame.GetGameOption("GAMEOPTION_REVOLUTION_SPAWN_NEW_CS") > 0) then
				REVOLUTION_SPAWN_NEW_CS = true
			else
				REVOLUTION_SPAWN_NEW_CS = false
			end
		end
		if(PreGame.GetGameOption("GAMEOPTION_REVOLUTION_RAGING_REBELS") ~= nil) then
			if (PreGame.GetGameOption("GAMEOPTION_REVOLUTION_RAGING_REBELS") > 0) then
				MIN_CULTURE_REBELS_SPAWN		= RAGING_MIN_CULTURE_SPAWN		
				MIN_RELATION_BEFORE_REBELLION	= RAGING_MIN_RELATION_REBELLION	
				REVOLUTION_VALUE				= RAGING_REVOLUTION_VALUE			
				REBELLION_VALUE					= RAGING_REBELLION_VALUE			
				REVOLT_VALUE					= RAGING_REVOLT_VALUE
			end
		end
	end
end