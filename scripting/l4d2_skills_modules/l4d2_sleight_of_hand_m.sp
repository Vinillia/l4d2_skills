#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <l4d2_skills>
#include <weaponhandling>

#define SKILL_NAME "Sleight of hand"

public Plugin myinfo =
{
	name = "[L4D2] Sleight of hand",
	author = "BHaType",
	description = "Increases weapon reload and deploy speed",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

bool g_bHaveSkill[MAXPLAYERS + 1];
float g_flPower, g_flCost;
int g_iID;

public void WH_OnMeleeSwing( int client, int weapon, float &speedmodifier )
{
	GetClientSpeed(client, speedmodifier);
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	GetClientSpeed(client, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	GetClientSpeed(client, speedmodifier);
}

void GetClientSpeed( int client, float &speed )
{
	if ( !g_bHaveSkill[client] )
		return;
	
	speed *= g_flPower;
}

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_PASSIVE);
	
	for( int i = 1; i <= MaxClients; i++ )
		g_bHaveSkill[i] = Skills_ClientHaveByID(i, g_iID);
}

public void Skills_OnSkillStateReset()
{
	for( int i = 1; i <= MaxClients; i++ )
		g_bHaveSkill[i] = false;
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( state != SS_PURCHASED || g_iID != id )
		return;

	g_bHaveSkill[client] = true;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_flCost, 2500.0);
	EXPORT_FLOAT_DEFAULT("power", g_flPower, 1.25);

	EXPORT_END();
}