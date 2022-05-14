#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>
#include <left4dhooks>

#define SKILL_NAME "Epic Molotov"
#define MAX_LEVELS 16

public Plugin myinfo =
{
	name = "[L4D2] Epic Molotov",
	author = "BHaType",
	description = "Spawns additional molotovs after throwing",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct ExportedInfo
{
	int initialCount;
	int numLevels;
	
	float cost;
	float power;
	float minScale;
	float maxScale;
	float upgradesCost[MAX_LEVELS];
}

ExportedInfo g_ExportedInfo;
int g_iSkillLevel[MAXPLAYERS + 1];
int g_iID;
bool g_bBlockEndlessCycle;

public void OnAllPluginsLoaded()
{
	g_iID = Skills_Register(SKILL_NAME, ST_ACTIVATION, true);
	
	HookEvent("molotov_thrown", molotov_thrown);
}

public void molotov_thrown( Event event, const char[] name, bool noReplicate )
{
	if ( g_bBlockEndlessCycle )
		return;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !IsHaveSkill(client) )
		return;
	
	float vOrigin[3], vAngles[3], vVelocity[3];
	int entity, count;
	
	g_bBlockEndlessCycle = true;
	count = GetClientMolotovCount(client); 
	
	for( int i; i < count; i++ )
	{
		GetMolotovVectors(client, vOrigin, vVelocity);
		ScaleVector(vVelocity, g_ExportedInfo.power * GetRandomFloat(g_ExportedInfo.minScale, g_ExportedInfo.maxScale));
		entity = L4D_MolotovPrj(client, vOrigin, vAngles);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
	}
	
	g_bBlockEndlessCycle = false;
}

void GetMolotovVectors( int client, float origin[3], float velocity[3] )
{
	float vOrigin[3], vAngles[3], vFwd[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	vAngles[0] += GetRandomFloat(-1.0) * 12.0 ;
	vAngles[1] += GetRandomFloat(-1.0) * 12.0;
	
	GetAngleVectors(vAngles, vFwd, NULL_VECTOR, NULL_VECTOR);
	velocity = vFwd;
	ScaleVector(vFwd, 16.0);
	AddVectors(vOrigin, vFwd, origin);
	
	TR_TraceHull(vOrigin, origin, {-5.0, -5.0, -5.0}, {5.0, 5.0, 5.0}, MASK_SHOT);
	TR_GetEndPosition(origin);
}

int GetClientMolotovCount( int client )
{
	return g_iSkillLevel[client] + g_ExportedInfo.initialCount;
}

bool IsHaveSkill( int client )
{
	return g_iSkillLevel[client] > 0;
}

public void Skills_OnSkillStateReset()
{
	for( int i = 1; i <= MaxClients; i++ )
		g_iSkillLevel[i] = 0;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILL_NAME);

	EXPORT_INT_DEFAULT("levels", g_ExportedInfo.numLevels, 6);
	EXPORT_INT_DEFAULT("initial_count", g_ExportedInfo.initialCount, 1);
	EXPORT_FLOAT_DEFAULT("cost", g_ExportedInfo.cost, 5000.0);
	EXPORT_FLOAT_DEFAULT("min_scale", g_ExportedInfo.minScale, 0.8);
	EXPORT_FLOAT_DEFAULT("max_scale", g_ExportedInfo.maxScale, 1.2);
	EXPORT_FLOAT_DEFAULT("power", g_ExportedInfo.power, 750.0);
	
	GetUpgradeCostsLevels(kv);

	EXPORT_END();
}

void GetUpgradeCostsLevels( KeyValues kv )
{
	char upgradeCost[64], splitedCosts[MAX_LEVELS][16];
	int num;
	
	Skills_ExportString(kv, "upgrade_costs", upgradeCost, sizeof upgradeCost, "500.0, 1500.0, 2500.0, 5000.0, 10000.0, 20000.0");
	num = ExplodeString(upgradeCost, ",", splitedCosts, sizeof splitedCosts, sizeof splitedCosts[]);
	
	if ( num != g_ExportedInfo.numLevels )
		LOG("Warning: upgrade_costs and levels count mismatch %i != %i!", num, g_ExportedInfo.numLevels);

	for( int i; i < num; i++ )
	{
		g_ExportedInfo.upgradesCost[i] = StringToFloat(splitedCosts[i]);
	}
}

public void Skills_OnSkillStateChanged( int client, int id, SkillState state )
{
	if ( state != SS_PURCHASED || id != g_iID )
		return;
		
	g_iSkillLevel[client] += 1;
}

public UpgradeImplementation Skills_OnUpgradeMenuRequest( int client, int id, int &nextLevel, float &upgradeCost )
{
	int curLevel = g_iSkillLevel[client];
	nextLevel = curLevel + 1;
	upgradeCost = g_ExportedInfo.upgradesCost[curLevel - 1];
	return UI_DEFAULT;
}

public bool Skills_OnCanClientUpgradeSkill( int client, int id )
{
	return g_iSkillLevel[client] < g_ExportedInfo.numLevels;
}