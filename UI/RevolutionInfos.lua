-- Lua Revolution Infos
-- Author: Gedemon
-- DateCreated: 4/15/2012 4:15:02 PM
--------------------------------------------------------------

print("--------------------------------------------------------------------------------------------------------------")
print("------------------------------------ Loading Revolutions Infos functions -------------------------------------")
print("--------------------------------------------------------------------------------------------------------------")


include("IconSupport")
include("InstanceManager")


--------------------------------------------------------------
-- includes
--------------------------------------------------------------
include ("RevolutionDefines")
include ("RevolutionUtils")
include ("RevolutionDebug")
include ("RevolutionFunctions")
include ("RouteConnections")

-------------------------------------------------
-------------------------------------------------
local m_SortTable;
local ePopulation	= 0
local eName			= 1
local eStrength		= 2
local eRevolution	= 3
local eStability	= 4
local eHappy		= 5
local eNeutral		= 6
local eUnhappy		= 7
local eRevolt		= 8
local eRebellion	= 9

local m_SortMode = ePopulation
local m_bSortReverse = false
-------------------------------------------------
-------------------------------------------------

function OnClose()
	--ContextPtr:SetHide(true)
	UIManager:PopModal(ContextPtr)
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose)

-- press ESC to close window.
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose()
            return true
        end
    end
end
ContextPtr:SetInputHandler( InputHandler )

-- what to do when showing/hidding the window
local oldCursor = 0
function ShowHideHandler( bIsHide, bInitState )
	
	if (not bHide) then
		UpdateDisplay()
		oldCursor = UIManager:SetUICursor(0)   -- remember the cursor state
		CivIconHookup( Game.GetActivePlayer(), 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true ) -- Set player icon at top of screen
	else
		UIManager:SetUICursor(oldCursor)  -- restore the cursor state
	end

end
ContextPtr:SetShowHideHandler( ShowHideHandler )

-------------------------------------------------
-------------------------------------------------
function SortFunction( a, b )
    local valueA, valueB

    local entryA = m_SortTable[ tostring( a ) ]
    local entryB = m_SortTable[ tostring( b ) ]
    
    if (entryA == nil) or (entryB == nil) then 
		if entryA and (entryB == nil) then
			return false
		elseif (entryA == nil) and entryB then
			return true
		else
			if( m_bSortReverse ) then
				return tostring(a) > tostring(b) -- gotta do something deterministic
			else
				return tostring(a) < tostring(b) -- gotta do something deterministic
			end
        end;
    else
		if( m_SortMode == ePopulation ) then
			valueA = entryA.Population
			valueB = entryB.Population
		elseif( m_SortMode == eName ) then
			valueA = entryA.CityName
			valueB = entryB.CityName
		elseif( m_SortMode == eStrength ) then
			valueA = entryA.Strength
			valueB = entryB.Strength
		elseif( m_SortMode == eStability ) then
			valueA = entryA.Stability
			valueB = entryB.Stability
		elseif( m_SortMode == eHappy ) then
			valueA = entryA.Happy
			valueB = entryB.Happy
		elseif( m_SortMode == eNeutral ) then
			valueA = entryA.Neutral
			valueB = entryB.Neutral
		elseif( m_SortMode == eUnhappy ) then
			valueA = entryA.Unhappy
			valueB = entryB.Unhappy
		elseif( m_SortMode == eRevolt ) then
			valueA = tonumber(entryA.Revolt)
			valueB = tonumber(entryB.Revolt)
		elseif( m_SortMode == eRebellion ) then
			valueA = tonumber(entryA.Rebellion)
			valueB = tonumber(entryB.Rebellion)
		else -- SortRevolution
			valueA = entryA.Revolution
			valueB = entryB.Revolution
		end
	    
		if( valueA == valueB ) then
			valueA = entryA.CityName
			valueB = entryB.CityName
		end

		if( m_bSortReverse ) then
			return valueA > valueB
		else
			return valueA < valueB
		end
	end
end

-------------------------------------------------
-------------------------------------------------
function OnSort( type )
    if( m_SortMode == type ) then
        m_bSortReverse = not m_bSortReverse
    else
        m_bSortReverse = false
    end

    m_SortMode = type
    Controls.MainStack:SortChildren( SortFunction )
end
Controls.SortPopulation:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortCityName:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortStrength:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortRevolution:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortStability:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortHappy:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortNeutral:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortUnhappy:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortRevolt:RegisterCallback( Mouse.eLClick, OnSort )
Controls.SortRebellion:RegisterCallback( Mouse.eLClick, OnSort )

Controls.SortPopulation:SetVoid1( ePopulation )
Controls.SortCityName:SetVoid1( eName )
Controls.SortStrength:SetVoid1( eStrength )
Controls.SortRevolution:SetVoid1( eRevolution )
Controls.SortStability:SetVoid1( eStability )
Controls.SortHappy:SetVoid1( eHappy )
Controls.SortNeutral:SetVoid1( eNeutral )
Controls.SortUnhappy:SetVoid1( eUnhappy )
Controls.SortRevolt:SetVoid1( eRevolt )
Controls.SortRebellion:SetVoid1( eRebellion )

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function UpdateDisplay()
    
    local player = Players[ Game.GetActivePlayer() ]
    if( player == nil ) then
        -- shouldn't be there...
        return
    end

	UpdateRelationPanel()
    
    m_SortTable = {}

    Controls.MainStack:DestroyAllChildren()
	
	local cultureMap = MapModData.AH.CultureMap
	--local cultureRelations = LoadData("CultureRelations")
	local cultureRelations = MapModData.AH.CultureRelations

	if #cultureRelations == 0 then
		return
	end

	local maxTrouble = 0
      
    for city in player:Cities() do
		local instance = {}
        ContextPtr:BuildInstanceForControl( "CityInstance", instance, Controls.MainStack )
        
        local sortEntry = {}
		m_SortTable[ tostring( instance.Root ) ] = sortEntry		

		local stability, revolt, rebellion, revolution, from = GetCityRebellion(city, cultureMap, cultureRelations)
		local happiness, happy, neutral, unhappy = GetCityHappiness(city, cultureMap, cultureRelations)
		
		if stability > maxTrouble then
			maxTrouble = stability
		end

		local unrestToolTipStr = ""
		if (from.Maximum > REVOLT_VALUE) or (from.Maximum > REBELLION_VALUE) or (from.Maximum > REVOLUTION_VALUE) then
			unrestToolTipStr = unrestToolTipStr .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_CITY_MAX", "COLOR_NEGATIVE_TEXT", from.Maximum)
		elseif (from.Maximum > 0) then
			unrestToolTipStr = unrestToolTipStr .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_CITY_MAX", "COLOR_PLAYER_ORANGE_TEXT", from.Maximum)
		else
			unrestToolTipStr = unrestToolTipStr .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_CITY_MAX", "COLOR_POSITIVE_TEXT", from.Maximum)
		end

		if from.Random > 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_INITIAL", "COLOR_NEGATIVE_TEXT", from.Random)
		elseif from.Random < 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_INITIAL", "COLOR_POSITIVE_TEXT", from.Random)
		end

		if from.MartialLaw > 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_MARTIAL_LAW", "COLOR_NEGATIVE_TEXT", from.MartialLaw, from.MilitaryUnits)
		elseif from.MartialLaw < 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_MARTIAL_LAW", "COLOR_POSITIVE_TEXT", from.MartialLaw, from.MilitaryUnits)
		end
		
		if from.Affinity > 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_AFFINITY", "COLOR_NEGATIVE_TEXT", from.Affinity)			
		elseif from.Affinity < 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_AFFINITY", "COLOR_POSITIVE_TEXT", from.Affinity)			
		end
		
		if from.IsPuppet > 100 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_AUTONOMY", "COLOR_NEGATIVE_TEXT", from.IsPuppet)	
		elseif (from.IsPuppet < 100) and (from.IsPuppet > 0) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_AUTONOMY", "COLOR_POSITIVE_TEXT", from.IsPuppet)	
		end
		
		if from.IsOccupied > 100 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_OCCUPATION", "COLOR_NEGATIVE_TEXT", from.IsOccupied)	
		elseif (from.IsOccupied < 100) and (from.IsOccupied > 0) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_FROM_OCCUPATION", "COLOR_POSITIVE_TEXT", from.IsOccupied)	
		end
	
		--unrestToolTipStr = unrestToolTipStr .. "[NEWLINE][NEWLINE]" .. REVOLT_VALUE .. " points are needed to resist, " .. REBELLION_VALUE .. " to generate rebels, " .. REVOLUTION_VALUE .. " to start revolution."

		if (from.Maximum > REVOLT_VALUE) or (from.Maximum > REBELLION_VALUE) or (from.Maximum > REVOLUTION_VALUE) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]"
		end
		local cityPopulation = city:GetPopulation()
		if (from.Maximum > REVOLT_VALUE) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_RISK_REVOLT", revolt, REVOLT_VALUE)
			if cityPopulation < MIN_REVOLT_CITY_SIZE then
				unrestToolTipStr = unrestToolTipStr .. " [COLOR_POSITIVE_TEXT](" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REVOLT") .. ")[ENDCOLOR]"
			end
		end
		if (from.Maximum > REBELLION_VALUE) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_RISK_REBEL", rebellion, REBELLION_VALUE)
			if cityPopulation < MIN_REBELLION_CITY_SIZE then
				unrestToolTipStr = unrestToolTipStr .. " [COLOR_POSITIVE_TEXT](" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REBELLION") .. ")[ENDCOLOR]"
			end
		end
		if (from.Maximum > REVOLUTION_VALUE) then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_RISK_REVOLUTION", revolution, REVOLUTION_VALUE)
			if cityPopulation < MIN_REBELLION_CITY_SIZE then
				unrestToolTipStr = unrestToolTipStr .. " [COLOR_POSITIVE_TEXT](" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_HINT_NO_SMALL_CITY_REVOLUTION") .. ")[ENDCOLOR]"
			end
		end

		if from.Representation == 0 and from.Relation ~= 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_REPRESENTATION", MIN_RATIO_REBELS_SPAWN)
		elseif from.Relation == 0 then
			unrestToolTipStr = unrestToolTipStr .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_REVOLUTION_UNREST_RELATION", MIN_RELATION_BEFORE_REBELLION)
		end

		sortEntry.Stability = from.Maximum

		if stability == 0 then
			instance.Stability:SetText( "[ICON_HAPPINESS_1]" )
		elseif stability == 1 then
			instance.Stability:SetText( "[ICON_HAPPINESS_3]" )
		else
			instance.Stability:SetText( "[ICON_HAPPINESS_4]" )
		end
		instance.Stability:SetToolTipString( unrestToolTipStr )


		sortEntry.Revolt = Round(revolt)
		if revolt > 0 then
			instance.Revolt:SetText( "[COLOR_NEGATIVE_TEXT]" .. sortEntry.Revolt .. "%[ENDCOLOR]" )
			local maxRevoltPoints = from.Maximum-REVOLT_VALUE
			local MaxCityResistanceTurns = math.min(Round (maxRevoltPoints/CITY_REVOLT_POINTS), MAX_TURNS_REVOLT_CITY, cityPopulation)
			instance.Revolt:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_RESISTANCE_TURNS_MAX", MaxCityResistanceTurns) )
		else		
			instance.Revolt:SetText( sortEntry.Revolt .. "%" )
		end

		sortEntry.Rebellion = Round(rebellion)
		if rebellion > 0 then
			instance.Rebellion:SetText( "[COLOR_NEGATIVE_TEXT]" .. sortEntry.Rebellion .. "%[ENDCOLOR]" )
			local maxRebellionPoints = from.Maximum-REBELLION_VALUE
			local rebelUnits = Round(maxRebellionPoints / UNIT_REBELLION_POINTS)
			local spawnableRebels = Round(cityPopulation*unhappy/100)
			local maxNumRebelUnits = math.min(rebelUnits, spawnableRebels)
			instance.Rebellion:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_REBEL_UNITS_MAX", maxNumRebelUnits) )
		else		
			instance.Rebellion:SetText( sortEntry.Rebellion .. "%" )
		end		

		sortEntry.Revolution = Round(revolution)
		if revolution > 0 then
			instance.Revolution:SetText( "[COLOR_NEGATIVE_TEXT]" .. sortEntry.Revolution .. "%[ENDCOLOR]" )
		else		
			instance.Revolution:SetText( sortEntry.Revolution .. "%" )
		end
		
		
		local cityRelationStr = GetPlotRelationHelpString(city:Plot(), cultureMap, cultureRelations)

		sortEntry.Happy = Round(happy)
		if happy > 0 then
			instance.Happy:SetText( "[COLOR_POSITIVE_TEXT]" .. sortEntry.Happy .. "%[ENDCOLOR]" )
		else
			instance.Happy:SetText( sortEntry.Happy .. "%" )
		end
		instance.Happy:SetToolTipString( cityRelationStr )
		
		sortEntry.Neutral = Round(neutral)
        instance.Neutral:SetText( sortEntry.Neutral .. "%" )
		instance.Neutral:SetToolTipString( cityRelationStr )
		
		sortEntry.Unhappy = Round(unhappy)
		if unhappy > 0 then
			instance.Unhappy:SetText( "[COLOR_NEGATIVE_TEXT]" .. sortEntry.Unhappy .. "%[ENDCOLOR]" )
		else		
			instance.Unhappy:SetText( sortEntry.Unhappy .. "%" )
		end
		instance.Unhappy:SetToolTipString( cityRelationStr )
			
		sortEntry.Strength = math.floor( city:GetStrengthValue() / 100 )
        instance.Defense:SetText( sortEntry.Strength )       


		sortEntry.CityName = city:GetName()
        instance.CityName:SetText( sortEntry.CityName )        
		instance.CityName:SetToolTipString( unrestToolTipStr )

        if(city:IsCapital())then
			instance.IconCapital:SetText("[ICON_CAPITAL]")
	        instance.IconCapital:SetHide( false )  
		elseif(city:IsPuppet()) then
			instance.IconCapital:SetText("[ICON_PUPPET]")
			instance.IconCapital:SetHide(false)
		elseif(city:IsOccupied() and not city:IsNoOccupiedUnhappiness()) then
			instance.IconCapital:SetText("[ICON_OCCUPIED]")
			instance.IconCapital:SetHide(false)
		else
			instance.IconCapital:SetHide(true)
		end
        
    	local pct = 1 - (city:GetDamage() / GameDefines.MAX_CITY_HIT_POINTS);
    	if( pct ~= 1 ) then
    	
            if pct > 0.66 then
                instance.HealthBar:SetFGColor( { x = 0, y = 1, z = 0, w = 1 } );
            elseif pct > 0.33 then
                instance.HealthBar:SetFGColor( { x = 1, y = 1, z = 0, w = 1 } );
            else
                instance.HealthBar:SetFGColor( { x = 1, y = 0, z = 0, w = 1 } );
            end
            
        	instance.HealthBar:SetPercent( pct );
        	instance.HealthBarBox:SetHide( false );
    	else
        	instance.HealthBarBox:SetHide( true );
    	end
        
        sortEntry.Population = city:GetPopulation();
        instance.Population:SetText( sortEntry.Population );
        
	    -- Update Growth Meter
		if (instance.GrowthBar) then
			
			local iCurrentFood = city:GetFood();
			local iFoodNeeded = city:GrowthThreshold();
			local iFoodPerTurn = city:FoodDifference();
			local iCurrentFoodPlusThisTurn = iCurrentFood + iFoodPerTurn;
			
			local fGrowthProgressPercent = iCurrentFood / iFoodNeeded;
			local fGrowthProgressPlusThisTurnPercent = iCurrentFoodPlusThisTurn / iFoodNeeded;
			if (fGrowthProgressPlusThisTurnPercent > 1) then
				fGrowthProgressPlusThisTurnPercent = 1
			end
			
			instance.GrowthBar:SetPercent( fGrowthProgressPercent );
			instance.GrowthBarShadow:SetPercent( fGrowthProgressPlusThisTurnPercent );
		end
		
		-- Update Growth Time
		if(instance.CityGrowth) then
			local cityGrowth = city:GetFoodTurnsLeft();
			
			if (city:IsFoodProduction() or city:FoodDifferenceTimes100() == 0) then
				cityGrowth = "-";
				--instance.CityBannerRightBackground:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_CITY_STOPPED_GROWING_TT", localizedCityName, cityPopulation));
			elseif city:FoodDifferenceTimes100() < 0 then
				cityGrowth = "[COLOR_WARNING_TEXT]-[ENDCOLOR]";
				--instance.CityBannerRightBackground:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_CITY_STARVING_TT",localizedCityName ));
			else
				--instance.CityBannerRightBackground:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_CITY_WILL_GROW_TT", localizedCityName, cityPopulation, cityPopulation+1, cityGrowth));
			end
			
			instance.CityGrowth:SetText(cityGrowth);
		end       

    end	
			
	Controls.StabilityStatutStr:SetText(Locale.ConvertTextKey("TXT_KEY_REVOLUTION_INFO_ACTUAL_STATUS", GetTroubleValueString(maxTrouble)))
    
    Controls.MainStack:CalculateSize();
    Controls.MainStack:ReprocessAnchoring();
    Controls.MainScroll:CalculateInternalSize();
end


function UpdateRelationPanel()

	-- Inner Empire relations
	  
    local bFoundRelation = false
    Controls.InnerRelationStack:DestroyAllChildren()
	
	local iPlayer = Game.GetActivePlayer()
	local player = Players[iPlayer]
	local team = Teams[player:GetTeam()]
	local cultureMap = MapModData.AH.CultureMap	

	--local cultureRelations = LoadData("CultureRelations") -- Why this has stopped working correctly ???
	local cultureRelations = MapModData.AH.CultureRelations	

	if (cultureRelations and cultureRelations[iPlayer]) then

		local globalHappiness, globalVariation = GetGlobalHappiness(iPlayer, cultureRelations)
		if globalVariation > 0 then
			Controls.StabilityVariationStr:SetText( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TENDENCY_STABILITY") ) 
			if globalHappiness < 0 then
				Controls.InnerRelationValue:SetText( "[COLOR_PLAYER_ORANGE_TEXT]" .. globalHappiness .. "[ENDCOLOR]" )
			else
				Controls.InnerRelationValue:SetText( "[COLOR_POSITIVE_TEXT]" .. globalHappiness .. "[ENDCOLOR]" )
			end
			Controls.InnerRelationValue:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_WEIGHTED_VARIATION", "COLOR_POSITIVE_TEXT", globalVariation))
		elseif globalVariation < 0 then
			Controls.StabilityVariationStr:SetText( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TENDENCY_UNREST") ) 
			if globalHappiness > 0 then
				Controls.InnerRelationValue:SetText( "[COLOR_PLAYER_YELLOW_TEXT]" .. globalHappiness .. "[ENDCOLOR]" ) 
			else
				Controls.InnerRelationValue:SetText( "[COLOR_NEGATIVE_TEXT]" .. globalHappiness .. "[ENDCOLOR]" ) 
			end
			Controls.InnerRelationValue:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_WEIGHTED_VARIATION", "COLOR_NEGATIVE_TEXT", globalVariation))
		else
			Controls.StabilityVariationStr:SetText( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_TENDENCY_NO") )
			Controls.InnerRelationValue:SetText( globalHappiness ) 
			Controls.InnerRelationValue:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_WEIGHTED_VARIATION", "COLOR_WHITE", globalVariation))
		end

		local cultureGroups, totalCulture = GetCultureGroups(iPlayer)
		if cultureGroups then
			bFoundRelation = true
		end

		for i, data in pairs(cultureGroups) do

			local instance = {}
            ContextPtr:BuildInstanceForControl( "InnerRelationEntry", instance, Controls.InnerRelationStack )

			local innerRelationGroupStr = ""
			local civAdj = GetCultureTypeAdj(data.Type)
			local relation = cultureRelations[iPlayer][data.Type]
			local culturePercent = Round(data.Value / totalCulture * 100)

			if not relation then relation = 0 end -- relation can be nil on first turns

			if relation < THRESHOLD_WOEFUL then
				innerRelationGroupStr = innerRelationGroupStr.."[ICON_HAPPINESS_4]"..civAdj
			elseif relation < THRESHOLD_JOYFUL then
				innerRelationGroupStr = innerRelationGroupStr.."[ICON_HAPPINESS_3]"..civAdj
			else
				innerRelationGroupStr = innerRelationGroupStr.."[ICON_HAPPINESS_1]"..civAdj
			end
                
            instance.InnerRelationGroupStr:SetText( innerRelationGroupStr )
			instance.InnerRelationGroupStr:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_REVOLUTION_CULTURE_GROUP_RELATION", culturePercent, GetRelationValueString(relation)) )
						
			local relationChange, from = GetRelationChange(iPlayer, data.Type)

			local strtooltip
			if relationChange > 0 then
				if relation > 0 then
					instance.InnerRelationChangeValue:SetText( "[COLOR_POSITIVE_TEXT]" .. relation .. "[ENDCOLOR]" )
				elseif relation < 0 then
					instance.InnerRelationChangeValue:SetText( "[COLOR_PLAYER_ORANGE_TEXT]" .. relation .. "[ENDCOLOR]" )
				else
					instance.InnerRelationChangeValue:SetText( "[COLOR_POSITIVE_TEXT]" .. relation .. "[ENDCOLOR]" )
				end
				strtooltip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_CULTURE_GROUP_RELATION_VARIATION", "COLOR_POSITIVE_TEXT", relationChange)
			elseif relationChange < 0 then
				if relation > 0 then
					instance.InnerRelationChangeValue:SetText( "[COLOR_PLAYER_YELLOW_TEXT]" .. relation .. "[ENDCOLOR]" ) 
				elseif relation < 0 then
					instance.InnerRelationChangeValue:SetText( "[COLOR_NEGATIVE_TEXT]" .. relation .. "[ENDCOLOR]" ) 
				else
					instance.InnerRelationChangeValue:SetText( "[COLOR_NEGATIVE_TEXT]" .. relation .. "[ENDCOLOR]" ) 
				end
				strtooltip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_CULTURE_GROUP_RELATION_VARIATION", "COLOR_NEGATIVE_TEXT", relationChange)
			else
				instance.InnerRelationChangeValue:SetText( relation ) 
				strtooltip = Locale.ConvertTextKey("TXT_KEY_REVOLUTION_CULTURE_GROUP_RELATION_VARIATION", "COLOR_WHITE", relationChange)
			end

			table.sort(from, function(a,b) return a.Change > b.Change end)
			for i, data in pairs(from) do
				if data.Change > 0 then
					strtooltip = strtooltip.."[NEWLINE][COLOR_POSITIVE_TEXT]+"..data.Change.."[ENDCOLOR] " .. Locale.ConvertTextKey(data.TextKey)
				elseif data.Change < 0 then
					strtooltip = strtooltip.."[NEWLINE][COLOR_NEGATIVE_TEXT]"..data.Change.."[ENDCOLOR] " .. Locale.ConvertTextKey(data.TextKey)
				end
			end
            instance.InnerRelationChangeValue:SetToolTipString( strtooltip )
		end
		Controls.StabilityStatut:SetHide( false )
		Controls.StabilityVariation:SetHide( false )
	else
		Controls.StabilityStatut:SetHide( true )
		Controls.StabilityVariation:SetHide( true )
	end
    
    if( bFoundRelation ) then
        Controls.InnerRelationToggle:SetDisabled( false )
        Controls.InnerRelationToggle:SetAlpha( 1.0 )
    else
        Controls.InnerRelationToggle:SetDisabled( true )
        Controls.InnerRelationToggle:SetAlpha( 0.5 )
    end
    Controls.InnerRelationStack:CalculateSize()
    Controls.InnerRelationStack:ReprocessAnchoring()

end


function OnInnerRelationToggle()
    local bWasHidden = Controls.InnerRelationStack:IsHidden()
    Controls.InnerRelationStack:SetHide( not bWasHidden )
    if( bWasHidden ) then
        Controls.InnerRelationToggle:LocalizeAndSetText("TXT_KEY_RELATION_INNER_EMPIRE_DETAILS_COLLAPSE")
    else
        Controls.InnerRelationToggle:LocalizeAndSetText("TXT_KEY_RELATION_INNER_EMPIRE_DETAILS")
    end
    Controls.RelationStack:CalculateSize()
    Controls.RelationStack:ReprocessAnchoring()
    Controls.RelationScroll:CalculateInternalSize()
end
Controls.InnerRelationToggle:RegisterCallback( Mouse.eLClick, OnInnerRelationToggle )