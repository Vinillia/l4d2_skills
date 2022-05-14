#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <l4d2_skills>

#define SKILL_NAME "Assistant"

public Plugin myinfo =
{
	name = "[L4D2] Assistant",
	author = "BHaType",
	description = "Speed ups revie and healing process",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

ConVar survivor_revive_duration;
float survivor_revive_duration_base, g_flCost, g_flPower;
int m_isDualWielding;

public void OnAllPluginsLoaded()
{
	Skills_Register(SKILL_NAME, ST_ACTIVATION);
	Skills_RequestConfigReload(true);

	m_isDualWielding = FindSendPropInfo("CBaseRifle", "m_isDualWielding") + 4;
	
	survivor_revive_duration = FindConVar("survivor_revive_duration");
	survivor_revive_duration_base = survivor_revive_duration.FloatValue;
	
	HookEvent("revive_begin", revive_begin);
	HookEvent("heal_begin", heal_begin);
}

public void revive_begin( Event event, const char[] name, bool dontBroadcast )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	float duration = survivor_revive_duration_base;
	
	if ( IsHaveSkill(client) )
		duration *= g_flPower;
	
	survivor_revive_duration.FloatValue = duration;
}

public void heal_begin( Event event, const char[] name, bool dontBroadcast )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !IsHaveSkill(client) )
		return;
	
	int kit = GetPlayerWeaponSlot(client, 3);
	float duration;
	
	if ( kit == -1 )
		return;
	
	duration = GetEntDataFloat(kit, m_isDualWielding) * g_flPower;
	
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", duration);
	
	SetEntDataFloat(kit, m_isDualWielding, duration); 
	SetEntDataFloat(kit, m_isDualWielding + 4, GetGameTime() + duration); 
}

bool IsHaveSkill( int client )
{
	return Skills_ClientHaveByName(client, SKILL_NAME);
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_flCost, 1500.0);
	EXPORT_FLOAT_DEFAULT("power", g_flPower, 0.5);

	EXPORT_END();
}