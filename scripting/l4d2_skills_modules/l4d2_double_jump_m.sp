#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include <l4d2_skills>

#define SKILL_NAME "Double Jump"

public Plugin myinfo =
{
	name = "[L4D2] Skills Double Jump",
	author = "BHaType",
	description = "Adds additional jump",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct SkillContext
{
	int lastButtons;
	int lastFlags;
	int jumps;
}

enum struct ExportInfo
{
	float cost;
	float power;
}

ExportInfo g_ExportedInfo;

SkillContext g_SkillContext[MAXPLAYERS + 1];
bool g_bHaveSkill[MAXPLAYERS + 1];
int g_iID;

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_INPUT, false);
}

public Action OnPlayerRunCmd( int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon )
{
	if ( g_bHaveSkill[client] )
	{
		Jump(client);
	}
	
	return Plugin_Continue;
}

stock void Jump(int client)
{
	int curFlags = GetEntityFlags(client);
	int curButtons = GetClientButtons(client);
	int lastFlags = g_SkillContext[client].lastFlags;
	int lastButtons = g_SkillContext[client].lastButtons;
	
	if ( lastFlags & FL_ONGROUND )
	{
		if (!(curFlags & FL_ONGROUND) && !(lastButtons & IN_JUMP) && curButtons & IN_JUMP)
		{
			OriginalJump(client);
		}
	}
	else if ( curFlags & FL_ONGROUND )
	{
		Landed(client);
	}
	else if ( !(lastButtons & IN_JUMP) && curButtons & IN_JUMP )
	{
		ReJump(client);
	}

	g_SkillContext[client].lastFlags = curFlags;
	g_SkillContext[client].lastButtons = curButtons;
}

stock void OriginalJump( int client )
{
	g_SkillContext[client].jumps++;
}

stock void Landed( int client )
{
	g_SkillContext[client].jumps = 0;
}

stock void ReJump( int client )
{
	int jumps = g_SkillContext[client].jumps;
	
	if ( jumps >= 1 && jumps < 2 )
	{
		g_SkillContext[client].jumps++;
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		
		vVel[2] = g_ExportedInfo.power;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}

public void Skills_OnSkillStateReset()
{
	for( int i = 1; i <= MaxClients; i++ )
		g_bHaveSkill[i] = false;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_ExportedInfo.cost, 2500.0);
	EXPORT_FLOAT_DEFAULT("power", g_ExportedInfo.power, 300.0);
	
	EXPORT_END();
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( state != SS_PURCHASED || g_iID != id )
		return;
	
	g_bHaveSkill[client] = true;
}



