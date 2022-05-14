#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>

#define SKILL_NAME "Sticky Pipe Bombs"

float g_flCost;

public void OnAllPluginsLoaded()
{
	Skills_Register(SKILL_NAME, ST_PASSIVE);
}

public void OnEntityCreated( int entity, const char[] name )
{
	if ( strcmp(name, "pipe_bomb_projectile") == 0 )
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned( int entity )
{
	RequestFrame(NextFrame, EntIndexToEntRef(entity)); 
}

public void NextFrame( int entity )
{
	if ( (entity = EntRefToEntIndex(entity)) <= MaxClients )
		return;
		
	int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
	
	if ( client <= 0 || client > MaxClients || !IsHaveSkill(client) )
		return;
	
	SDKHook(entity, SDKHook_Touch, OnTouch);
}

public void OnTouch( int entity, int other )
{
	if ( other > 0 )
	{
		SetVariantString("!activator");
		AcceptEntityInput(other, "SetParent", other);
	}
	else
	{
		SetEntityMoveType(entity, MOVETYPE_NONE);
	}
}

bool IsHaveSkill( int client )
{
	return Skills_ClientHaveByName(client, SKILL_NAME);
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_flCost, 750.0);

	EXPORT_END();
}