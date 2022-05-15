#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>

#define SKILL_NAME "Resistance"
#define MAX_LEVELS 4

public Plugin myinfo =
{
	name = "[L4D2] Resistance",
	author = "BHaType",
	description = "Absorbs damage",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct Export
{
	float cost;
	int levels;
	float upgradeCosts[MAX_LEVELS];
	float levelsResistance[MAX_LEVELS];
}

Export g_Export;

int g_iClientLevel[MAXPLAYERS + 1];
int g_iID;

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_PASSIVE, true);
}

public void OnClientPutInServer(int client)
{
	if (IsHaveSkill(client))
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage( int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom ) 
{
	if (damagetype & DMG_FALL)
		return Plugin_Continue;

	if ( GetClientTeam(victim) != 2 || !attacker )
		return Plugin_Continue;

	int i = g_iClientLevel[victim] - 1;
	damage -= damage / 100.0 * g_Export.levelsResistance[i]; 
	return Plugin_Changed;
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( id != g_iID )
		return;

	if (state == SS_PURCHASED)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	else
	{
		g_iClientLevel[client] += 1;
	}
}

public UpgradeImplementation Skills_OnUpgradeMenuRequest( int client, int id, int &nextLevel, float &upgradeCost )
{
	int i = g_iClientLevel[client];
	nextLevel = i + 1;
	upgradeCost = g_Export.upgradeCosts[i];
	return UI_DEFAULT;
}

public bool Skills_OnCanClientUpgradeSkill( int client, int id )
{
	return g_iClientLevel[client] < g_Export.levels;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_Export.cost, 2500.0);
	GetArraysExport(kv);

	EXPORT_END();
}

void GetArraysExport( KeyValues kv )
{
	char buffers[MAX_LEVELS][16];
	char export[64];

	int costs = GetArrayExport(kv, "upgrade_costs", export, sizeof export, buffers, sizeof buffers, sizeof buffers[], "2500.0, 3000.0, 5000.0");
	g_Export.levels = costs;

	for( int i; i < costs; i++ )
		g_Export.upgradeCosts[i] = StringToFloat(buffers[i]);

	int powers = GetArrayExport(kv, "levels_power", export, sizeof export, buffers, sizeof buffers, sizeof buffers[], "10.0, 25.0, 35.0");

	for( int i; i < powers; i++ )
		g_Export.levelsResistance[i] = StringToFloat(buffers[i]);

	if (powers != costs)
	{
		ERROR("upgrade_costs and levels_power count don't match %i != %i", costs, powers);
	}
}

int GetArrayExport( KeyValues kv, const char[] key, char[] export, int exportLength, char[][] buffers, int numBuffers, int bufferLength, const char[] defaultValue )
{
	Skills_ExportString(kv, key, export, exportLength, defaultValue);
	return ExplodeString(export, ",", buffers, numBuffers, bufferLength);
}

bool IsHaveSkill( int client )
{
	return Skills_ClientHaveByID(client, g_iID);
}