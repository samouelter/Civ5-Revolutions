-- Revolutions Defines
-- Author: Gedemon
-- DateCreated: 3/30/2011 5:22:00 PM
--------------------------------------------------------------

print("Loading Revolutions Defines...")
print("-------------------------------------")



--------------------------------------------------------------
-- Mod related initialization
--------------------------------------------------------------
local DynHistModID = "97837c72-d198-49d2-accd-31101cfc048a"

--------------------------------------------------------------
-- use mod data to save / load data between game initialisation phases
--------------------------------------------------------------
local DynHistModVersion = Modding.GetLatestInstalledModVersion(DynHistModID)
modUserData = Modding.OpenUserData(DynHistModID, DynHistModVersion) -- global

--------------------------------------------------------------
-- Saveutils
--------------------------------------------------------------
WARN_NOT_SHARED = true
include( "ShareData.lua" )
include( "SaveUtils" )
MY_MOD_NAME = DynHistModID -- To share data between all DynHist mod components

PLAYER_SAVE_SLOT = 0 -- Player slot used by saveutils
DEFAULT_SAVE_KEY = "1,1" -- "0,0" used by HSD -- "0,1" used by Cultural diffusion


--------------------------------------------------------------
-- Debug settings
--------------------------------------------------------------
OVERRIDE_OPTION_MENU	= false	-- if true, the values from the option panel will be overriden by the values of the define file. Used to debug savegame only.
DEBUG_REVOLUTION		= true	-- if true will output debug text in the lua.log / firetuner console.
DEBUG_PERFORMANCE		= false	-- display running time of some functions

----------------------------------------------------------------------------------------------------------------------------
--
-- Revolution
--
----------------------------------------------------------------------------------------------------------------------------


-- Shared 
MapModData.AH = MapModData.AH or {}
MapModData.AH.CultureRelations = MapModData.AH.CultureRelations or {}
MapModData.AH.CultureMap = MapModData.AH.CultureMap or {}
--

--
RESERVED_CITY_STATES = 10 -- number of city states reserved for revolution functions
TURN_BEFORE_CHECK_INDEPENDENCE = 10 -- new cities won't produce separatist until this turn
SEPARATIST_TYPE = "SEPARATIST" -- culture type used for separatist

INITIAL_REBELS_RELATION = -120 -- Relation value with all major civs for a spawning Rebel CS

-- base relations change, applied each turn to culture groups that are represented in the player cities
SEPARATIST_RELATION_CHANGE					= -15
OWN_CULTURE_RELATION_CHANGE					= 0
FOREIGN_CULTURE_RELATION_CHANGE				= -5
WAR_MALUS_RELATION_CHANGE					= -20
DOF_BONUS_RELATION_CHANGE					= 10
DENOUNCED_MALUS_RELATION_CHANGE				= -10
LIBERTY_SEPARATIST_RELATION_CHANGE			= 2
LIBERTY_FINISHER_SEPARATIST_RELATION_CHANGE = 3
CITIZENSHIP_FOREIGN_RELATION_CHANGE			= 2
REPRESENTATION_ALL_RELATION_CHANGE			= 1

--
MAX_REBELS_GROUPS				= 3 -- maximum number of separate culture groups that can spawn rebels on a plot
MAX_REBELS_UNITS_PER_POPULATION = 2 -- maximum number of units a culture groups can spawn per population of that group (which is a percentage of total population)
REBELS_UNITS_ATTRITION			= 15 -- damage added each turn to rebel units (should be superior to the value of damage healed outside friendly territory)
MIN_RATIO_REBELS_SPAWN			= 15 -- minimum percentage of culture for a group to spawn rebels on a plot

CITY_DAMAGE_PERCENT_REBELS = 10 -- damage added to a city when rebels can't spawn because of number limitation

CITY_DAMAGE_REVOLUTION		= 30 -- base damage added to a city when a revolution can't occur because of number limitation
CITY_DAMAGE_REVOLUTION_VAR	= 45 -- max additionnal damage added during revolution, also used when the city is conquered by the revolutionnary movement

UNIT_DAMAGE_REVOLUTION = 25 -- base damage added to all military units in a city when a revolution can't occur because the city is garrisoned
UNIT_DAMAGE_REVOLUTION_VAR = 35 -- max additionnal damage added during revolution

MIN_CULTURE_REBELS_SPAWN		= 200 -- minimum level of culture for a group to spawn rebels on a plot
MIN_RELATION_BEFORE_REBELLION	= -75 -- under that threshold rebels can spawn
REVOLUTION_VALUE				= 275 -- if (randNum(0-100) - cityhappiness) is superior to this, then city can flip to revolution. cityhappiness can be negative value
REBELLION_VALUE					= 185 -- if (randNum(0-100) - cityhappiness) is superior to this, then city can spawn rebels.
REVOLT_VALUE					= 100 -- if (randNum(0-100) - cityhappiness) is superior to this, then city can enter resistance

RAGING_MIN_CULTURE_SPAWN		= 150 -- |
RAGING_MIN_RELATION_REBELLION	= -50 -- | 
RAGING_REVOLUTION_VALUE			= 180 -- } same as above, but applied when the "Raging Rebels" option is ON
RAGING_REBELLION_VALUE			= 120 -- | 
RAGING_REVOLT_VALUE				=  75 -- |

MILITARY_BONUS_PER_UNIT = 15 -- each units in the city area will diminish revolt / revolution points by this value

UNIT_REBELLION_POINTS	= 15 -- each UNIT_REBELLION_POINTS of (randNum(0-100) - relation + culturePercentValue)-REBELLION_VALUE will spawn a rebel unit
CITY_REVOLT_POINTS		= 35 -- same as above, for city resistance turns
MAX_TURNS_REVOLT_CITY	= 5 

REVOLT_ABORT_CHANCE		= 80 -- percentage of chance a planed revolt finally aborts. this is used to slow down revolts between turns.
REBELLION_ABORT_CHANCE	= 60 -- percentage of chance a planed rebellion finally aborts. this is used to slow down rebellions between turns.
REVOLUTION_ABORT_CHANCE = 65 -- percentage of chance a planed revolution finally aborts. this is used to slow down revolution between turns.

PUPPET_RATIO	= 45 -- ration (percent) applied to revolt/rebellion point if city is puppeted.
OCCUPIED_RATIO	= 115 -- ration (percent) applied to revolt/rebellion point if city is occupied.

MIN_REVOLUTION_CITY_SIZE	= 6 -- under this size a city won't go into revolution.
MIN_REBELLION_CITY_SIZE		= 3 -- under this size a city won't spawn rebels units.
MIN_REVOLT_CITY_SIZE		= 1 -- under this size a city won't go in revolt (resistance).

REVOLUTION_CHOICE_COUNTDOWN			= 10 -- number of turns before a city spawning a revolution will choose it's new nation
REVOLUTION_FORCE_CHOICE_COUNTDOWN	= 10 -- number of turns after normal countdown when a city spawning a revolution will have to choose it's new nation, even without any culture link.
DEAD_PLAYER_HAPPINESS				= 35 -- used for dead player when comparing happiness for a revolutionnary city choice of new nation
SAME_CULTURE_HAPPINESS_BONUS		= 20 -- added to "happiness value" when choosing a new civ if the civ is of the rebel's culture group  (Chinese rebels in a Russian city have a preference for China)
MASTER_CULTURE_HAPPINESS_MALUS		= 2 -- deducted to "happiness value" when choosing a new civ if the civ is the original master of the rebel's culture group (Russian separatists in a Russian city have a preference for anybody else)
AT_WAR_HAPPINESS_MALUS				= 8 -- deducted to "happiness value" when choosing a new civ if the civ is at war with that rebel group. Note that the master is always at war with the rebels, so this malus is always added to the master malus.
MINIMUM_HAPPINESS_TO_JOIN			= 2 -- minimum "hapiness value" required to join a civ, multiplied by Game.GetCurrentEra() (can be 0) 

REVOLUTION_SPAWN_NEW_CS		= true -- if true, allow spawning of new CS if no Culture Groups are available after REVOLUTION_FORCE_CHOICE_COUNTDOWN (can be overriden by option)
NEW_CS_PERCENT_CHANCE		= 20 -- Percent chance of a new CS to spawn each turn after REVOLUTION_CHOICE_COUNTDOWN and before REVOLUTION_FORCE_CHOICE_COUNTDOWN
MIN_FREE_SLOTS_FOR_NEW_CS	= 5 -- minimum slots left to allow spawning of a new CS

--
MAX_CULTURE_RELATION					= 200 -- maximum relation value between a player and a culture group
MAX_CULTURE_RELATION_MERITOCRACY_CHANGE = 100 -- maximum relation value raised when adopting meritocracy
MIN_CULTURE_RELATION					= -500 -- minimum relation value between a player and a culture group


-- Relation thresholds (defined in Rules.sql, shared with Cultural Diffusion component)
THRESHOLD_JOYFUL		= GameDefines.THRESHOLD_JOYFUL
THRESHOLD_HAPPY			= GameDefines.THRESHOLD_HAPPY
THRESHOLD_CONTENT		= GameDefines.THRESHOLD_CONTENT
THRESHOLD_UNHAPPY		= GameDefines.THRESHOLD_UNHAPPY
THRESHOLD_WOEFUL		= GameDefines.THRESHOLD_WOEFUL
THRESHOLD_EXASPERATED	= GameDefines.THRESHOLD_EXASPERATED

-- UI
MAX_LINE_REVOLUTION_TOOLTIP = 5 -- max number of rebellious cities shown on tooltip

-- Era
ERA_ANCIENT		= GameInfo.Eras.ERA_ANCIENT.ID
ERA_CLASSICAL	= GameInfo.Eras.ERA_CLASSICAL.ID
ERA_MEDIEVAL	= GameInfo.Eras.ERA_MEDIEVAL.ID
ERA_RENAISSANCE = GameInfo.Eras.ERA_RENAISSANCE.ID
ERA_INDUSTRIAL	= GameInfo.Eras.ERA_INDUSTRIAL.ID
ERA_MODERN		= GameInfo.Eras.ERA_MODERN.ID
ERA_POST_MODERN = 6 --GameInfo.Eras.ERA_POSTMODERN.ID -- How to keep compatibility with Vanilla without starting to make conditionnal defines ?
ERA_FUTURE		= GameInfo.Eras.ERA_FUTURE.ID

-- Route types
AIR		= 1
LAND	= 2
SEA		= 3
ROAD	= 4
RAIL	= 5

-- Route Separatist Factor
AIR_DIST_FACTOR		= 200
LAND_DIST_FACTOR	= 150
SEA_DIST_FACTOR		= 100
ROAD_DIST_FACTOR	= 50
RAIL_DIST_FACTOR	= 25

INDIRECT_ROUTE_FACTOR	= 25 -- bonus for being connected to capital indirectly (air distance used, but road+sea route exist)
ANOTHER_LAND_FACTOR		= 33 -- malus for being on another landmass

DISTANCE_MAX_RATIO = 200 -- default distance ratio for a non-connected route


-- Maximum distance before a city can create separatist
g_MaximumDistance = {
[AIR] = 5,
[LAND] = 6,
[SEA] = 8,
[ROAD] = 9,
[RAIL] = 12,
}

-- Ratio from era for g_MaximumDistance (percent)
g_EraDistanceRatio = {
[ERA_ANCIENT] = 65,
[ERA_CLASSICAL] = 75,
[ERA_MEDIEVAL] = 100,
[ERA_RENAISSANCE] = 125,
[ERA_INDUSTRIAL] = 175,
[ERA_MODERN] = 200,
[ERA_POST_MODERN] = 200,
[ERA_FUTURE] = 200,
}

-- Rebel unit type per Era
g_EraRebels = {
[ERA_ANCIENT] =		GameInfo.Units.UNIT_WARRIOR.ID,
[ERA_CLASSICAL] =	GameInfo.Units.UNIT_SPEARMAN.ID,
[ERA_MEDIEVAL] =	GameInfo.Units.UNIT_PIKEMAN.ID,
[ERA_RENAISSANCE] = GameInfo.Units.UNIT_MUSKETMAN.ID,
[ERA_INDUSTRIAL] =	GameInfo.Units.UNIT_RIFLEMAN.ID,
[ERA_MODERN] =		GameInfo.Units.UNIT_INFANTRY.ID,
[ERA_POST_MODERN] =	GameInfo.Units.UNIT_INFANTRY.ID,
[ERA_FUTURE] =		GameInfo.Units.UNIT_INFANTRY.ID,
}

--
g_EraRebelsBackground = {
[ERA_ANCIENT] =		"ancient_revolution.dds",
[ERA_CLASSICAL] =	"ancient_revolution.dds",
[ERA_MEDIEVAL] =	"ancient_revolution.dds",
[ERA_RENAISSANCE] = "renaissance_revolution.dds",
[ERA_INDUSTRIAL] =	"industrial_revolution.dds",
[ERA_MODERN] =		"industrial_revolution.dds",
[ERA_POST_MODERN] =	"modern_revolution.dds",
[ERA_FUTURE] =		"modern_revolution.dds",
}