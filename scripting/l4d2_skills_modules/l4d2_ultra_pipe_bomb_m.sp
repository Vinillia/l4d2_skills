#pragma newdecls required	
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>
#include <left4dhooks>

#define SKILL_NAME "Ultra Pipe Bomb"
#define MAX_LEVELS 16

public Plugin myinfo =
{
	name = "[L4D2] Ultra Pipe Bomb",
	author = "BHaType",
	description = "Spawns additional pipe bombs after throwing",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct SkillContext
{
	int active_pipebombs;
	int current_level;
}

enum struct ExportedInfo
{
	int numLevels;
	int initialCount;
	int glowRange;
	
	float color[3];
	float upgradeCost[MAX_LEVELS];
	float buyCost;
	float cooldown;
	float power;
	
	int GetColor()
	{
		int r = RoundToNearest(this.color[0]);
		int g = RoundToNearest(this.color[1]);
		int b = RoundToNearest(this.color[2]);
		return r + g * 256 + b * 65536;
	}
}

ExportedInfo g_ExportedInfo;
SkillContext g_PlayerSkill[MAXPLAYERS + 1];
int g_iID = -1;

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_ACTIVATION, true);
		
	if ( g_ExportedInfo.numLevels > MAX_LEVELS )
	{
		LOG("Warning: too many levels, clamped (%i > %i)!", g_ExportedInfo.numLevels, MAX_LEVELS);
		g_ExportedInfo.numLevels = MAX_LEVELS;
	}
	
	HookEvent("grenade_bounce", grenade_bounce);
}

public void grenade_bounce( Event event, const char[] name, bool noReplicate )
{
	int client, entity, hammerid;
	
	client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !IsHaveSkill(client) || IsClientReachedLimit(client) )
		return;
	
	while ((entity = FindEntityByClassname(entity, "pipe_bomb_projectile")) > MaxClients && GetEntPropEnt(entity, Prop_Send, "m_hThrower") == client)
		break;
	
	hammerid = GetPlayerWeaponSlot(client, 2);
	
	if ( hammerid != -1) 
	{ 
		hammerid = GetEntProp(hammerid, Prop_Data, "m_iHammerID"); 

		if ( hammerid > 1 ) 
			return; 
	} 
	
	if ( entity <= MaxClients )
		return;
		
	float vVelocity[3], vOrigin[3];
	float power;
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
	power = g_ExportedInfo.power;
	
	vVelocity[0] = GetRandomFloat(-1.0) * power;
	vVelocity[1] = GetRandomFloat(-1.0) * power;
	vVelocity[2] = GetRandomFloat() * power;
	
	entity = L4D_PipeBombPrj(client, vOrigin, {0.0, 0.0, 0.0});
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	SetEntProp(entity, Prop_Send, "m_nSolidType", 1);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	
	if ( g_ExportedInfo.glowRange > 0 )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_ExportedInfo.glowRange);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_ExportedInfo.GetColor());
	}
	
	g_PlayerSkill[client].active_pipebombs++;
	
	if ( IsClientReachedLimit(client) )
		CreateTimer(g_ExportedInfo.cooldown, timer_cooldown, GetClientUserId(client));
}

public Action timer_cooldown( Handle timer, int client )
{
	if ( (client = GetClientOfUserId(client)) == 0 )
		return Plugin_Continue;
		
	g_PlayerSkill[client].active_pipebombs = 0;
	Skills_PrintToChat(client, "\x05%s \x04can be used \x03again", SKILL_NAME);
	return Plugin_Continue;
}

bool IsClientReachedLimit( int client )
{
	return g_PlayerSkill[client].active_pipebombs >= g_PlayerSkill[client].current_level + g_ExportedInfo.initialCount;
}

bool IsHaveSkill( int client )
{
	return g_PlayerSkill[client].current_level > 0;
}

public void Skills_OnSkillStateReset()
{
	for( int i = 1; i <= MaxClients; i++ )
		g_PlayerSkill[i].current_level = 0;
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( state != SS_PURCHASED || g_iID != id )
		return;

	g_PlayerSkill[client].current_level += 1;
}

public bool Skills_OnCanClientUpgradeSkill( int client, int id )
{
	return g_PlayerSkill[client].current_level < g_ExportedInfo.numLevels;
}

public UpgradeImplementation Skills_OnUpgradeMenuRequest( int client, int id, int &nextLevel, float &upgradeCost )
{
	int level = g_PlayerSkill[client].current_level;
	
	nextLevel = level + 1;
	upgradeCost = g_ExportedInfo.upgradeCost[level - 1];
	return UI_DEFAULT;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);
	
	EXPORT_FLOAT_DEFAULT("cost", g_ExportedInfo.buyCost, 2500.0);
	EXPORT_FLOAT_DEFAULT("cooldown", g_ExportedInfo.cooldown, 15.0);
	EXPORT_FLOAT_DEFAULT("power", g_ExportedInfo.power, 150.0);
	EXPORT_INT_DEFAULT("levels", g_ExportedInfo.numLevels, 4);
	EXPORT_INT_DEFAULT("initial_bombs_count", g_ExportedInfo.initialCount, 4);
	EXPORT_INT_DEFAULT("glow_range", g_ExportedInfo.glowRange, 500);
	EXPORT_VECTOR_DEFAULT("glow_color", g_ExportedInfo.color, {255.0, 255.0, 255.0});
	
	EXPORT_END();

	GetUpgradeCostsLevels(kv);
}

void GetUpgradeCostsLevels( KeyValues kv )
{
	char upgradeCost[64], splitedCosts[MAX_LEVELS][16];
	int num;
	
	Skills_ExportString(kv, "upgrade_costs", upgradeCost, sizeof upgradeCost, "500.0, 1500.0, 2500.0, 5000.0");
	num = ExplodeString(upgradeCost, ",", splitedCosts, sizeof splitedCosts, sizeof splitedCosts[]);
	
	if ( num != g_ExportedInfo.numLevels )
		LOG("Warning: upgrade_costs and levels count mismatch %i != %i!", num, g_ExportedInfo.numLevels);

	for( int i; i < num; i++ )
	{
		g_ExportedInfo.upgradeCost[i] = StringToFloat(splitedCosts[i]);
	}
}
