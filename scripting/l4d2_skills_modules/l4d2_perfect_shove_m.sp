#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>

#define SKILL_NAME "Perfect Shove"

public Plugin myinfo =
{
	name = "[L4D2] Perfect Shove",
	author = "BHaType",
	description = "Deals damage to shoved specials",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct ExportedInfo
{
	float cost;
	float damage_for_specials;
	float damage_for_infected;
}

ExportedInfo g_ExportedInfo;
int g_iID = -1;

public void OnPluginStart()
{
	HookEvent("player_shoved", player_shoved);
	HookEvent("entity_shoved", entity_shoved);
}

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_ACTIVATION, false);
}

public void player_shoved( Event event, const char[] name, bool noReplicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if ( !attacker || attacker > MaxClients || !IsHaveSkill(attacker) || !IsClientInGame(attacker) )
		return;

	if ( !client || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 )
		return;
	
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");

	if ( class == 4 || class == 2 )
		return;
	
	SDKHooks_TakeDamage(client, attacker, attacker, g_ExportedInfo.damage_for_specials);
}

public void entity_shoved( Event event, const char[] name, bool noReplicate )
{
	int entity = event.GetInt("entityid");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if ( !attacker || attacker > MaxClients || !IsHaveSkill(attacker) )
		return;
	
	if ( entity > MaxClients && ClassMatchesComplex(entity, "infected") )
		SDKHooks_TakeDamage(entity, attacker, attacker, g_ExportedInfo.damage_for_infected);
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_ExportedInfo.cost, 2500.0);
	EXPORT_FLOAT_DEFAULT("damage_for_specials", g_ExportedInfo.damage_for_specials, 250.0);
	EXPORT_FLOAT_DEFAULT("damage_for_infected", g_ExportedInfo.damage_for_infected, 25.0);

	EXPORT_END();
}

bool IsHaveSkill( int client )
{
	return Skills_ClientHaveByID(client, g_iID);
}