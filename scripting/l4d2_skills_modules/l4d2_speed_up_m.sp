#pragma newdecls required	
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>
#include <left4dhooks>

#define SKILL_NAME "Speed Boost"
#define MAX_LEVELS 16

enum struct ExportedInfo
{
	int numLevels;
	
	float upgradePowers[MAX_LEVELS];
	float upgradeCost[MAX_LEVELS];
	float buyCost;
}

ExportedInfo g_ExportedInfo;
int g_iSkillLevel[MAXPLAYERS + 1];
int g_iID;

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_PASSIVE, true);
}

public Action L4D_OnGetCrouchTopSpeed( int target, float &retVal )
{
	return GetClientSpeed(target, retVal);
}

public Action L4D_OnGetRunTopSpeed( int target, float &retVal )
{
	return GetClientSpeed(target, retVal);
}

public Action L4D_OnGetWalkTopSpeed( int target, float &retVal )
{
	return GetClientSpeed(target, retVal);
}

Action GetClientSpeed( int client, float &reVal )
{
	if ( !IsHaveSkill(client) )
		return Plugin_Continue;
	
	int currentLevel = g_iSkillLevel[client] - 1;
	reVal += g_ExportedInfo.upgradePowers[currentLevel];
	return Plugin_Handled;
}

bool IsHaveSkill( int client )
{
	return g_iSkillLevel[client] > 0;
}

public void Skills_OnSkillStateReset()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_iSkillLevel[i] = 0;
	}
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( state != SS_PURCHASED || g_iID != id )
		return;

	g_iSkillLevel[client] += 1;
}

public bool Skills_OnCanClientUpgradeSkill( int client, int id )
{
	return g_iSkillLevel[client] < g_ExportedInfo.numLevels;
}

public UpgradeImplementation Skills_OnUpgradeMenuRequest( int client, int id, int &nextLevel, float &upgradeCost )
{
	int level = g_iSkillLevel[client];
	
	nextLevel = level + 1;
	upgradeCost = g_ExportedInfo.upgradeCost[level - 1];
	return UI_DEFAULT;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_ExportedInfo.buyCost, 2500.0);
	EXPORT_INT_DEFAULT("levels", g_ExportedInfo.numLevels, 4);
	
	EXPORT_END();

	int costUpgrades = GetUpgradesCost(kv);
	int speedPowers = GetSpeedPowersPerLevel(kv);
	
	if ( costUpgrades != g_ExportedInfo.numLevels )
		LOG("Warning: upgrade_costs and levels count mismatch %i != %i!", costUpgrades, g_ExportedInfo.numLevels);	
		
	if ( speedPowers != costUpgrades )
		LOG("Warning: speed_addition and upgrade_costs count mismatch %i != %i!", speedPowers, costUpgrades);	
}

int GetUpgradesCost( KeyValues kv )
{
	char upgradeCost[64], upgradesCosts[MAX_LEVELS][16];
	int num;
	
	Skills_ExportString(kv, "upgrade_costs", upgradeCost, sizeof upgradeCost, "500.0, 1500.0, 2500.0, 5000.0");
	num = ExplodeString(upgradeCost, ",", upgradesCosts, sizeof upgradesCosts, sizeof upgradesCosts[]);
	
	for( int i; i < num; i++ )
		g_ExportedInfo.upgradeCost[i] = StringToFloat(upgradesCosts[i]);
		
	return num;
}

int GetSpeedPowersPerLevel( KeyValues kv )
{
	char upgradeCost[64], speedPowers[MAX_LEVELS][16];
	int num;
	
	Skills_ExportString(kv, "speed_addition", upgradeCost, sizeof upgradeCost, "10.0, 25.0, 40.0, 60.0");
	num = ExplodeString(upgradeCost, ",", speedPowers, sizeof speedPowers, sizeof speedPowers[]);
	
	for( int i; i < num; i++ )
		g_ExportedInfo.upgradePowers[i] = StringToFloat(speedPowers[i]);
		
	return num;
}
