#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <l4d2_skills>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "[L4D2] Skills Job",
	author = "BHaType",
	description = "Gives player money for killing specials",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

#define ZC_CLASSES 9

enum struct ExportedInfo
{
	float bossesRewards[ZC_CLASSES];
	float witchOneshotReward;
	float team_reward_factor;
	
	bool print;
}

ExportedInfo g_Export;

public void OnAllPluginsLoaded()
{	
	Skills_RequestConfigReload();
	
	HookEvent("player_death", player_death);
	HookEvent("witch_killed", witch_killed);
	
	RegConsoleCmd("sm_skills_job_info", sm_skills_job_info);
}

public Action sm_skills_job_info( int client, int args )
{
	Skills_PrintToChat(client, "Reward for \x04witch \x01oneshot: \x03%.0f", g_Export.witchOneshotReward);
	Skills_PrintToChat(client, "Team \x04reward \x01factor: \x03%.2f", g_Export.team_reward_factor);
	
	Skills_PrintToChat(client, "Boss rewards:\n" ...											\
	"\x04Smoker: \x03%.0f\x01, \x04Booomer: \x03%.0f\x01, \x04Hunter: \x03%.0f\x01, \n" ...	\
	"\x04Spitter: \x03%.0f\x01, \x04Jockey: \x03%.0f\x01, \x04Charger: \x03%.0f\x01, \n" ...	\
	"\x04Witch: \x03%.0f\x01, \x04Tank: \x03%.0f",											\
	g_Export.bossesRewards[1], g_Export.bossesRewards[2], g_Export.bossesRewards[3],				\
	g_Export.bossesRewards[4], g_Export.bossesRewards[5], g_Export.bossesRewards[6],				\
	g_Export.bossesRewards[7], g_Export.bossesRewards[8]);
	return Plugin_Handled;
}

public void witch_killed( Event event, const char[] name, bool noReplicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !client || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 )
		return;
	
	float reward = event.GetBool("oneshot") ? g_Export.witchOneshotReward : g_Export.bossesRewards[L4D2ZombieClass_Witch];
	AddMoneyWrapper(client, reward);
}

public void player_death( Event event, const char[] name, bool noReplicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !client || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 )
		return;
		
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if ( !attacker || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2 )
		return;
	
	L4D2ZombieClassType class = L4D2_GetPlayerZombieClass(client);
	float reward = g_Export.bossesRewards[class];
	AddMoneyWrapper(attacker, reward);
}

void AddMoneyWrapper( int client, float reward )
{
	Skills_AddClientMoney(client, reward, .print = g_Export.print);
	Skills_AddTeamMoney(reward * g_Export.team_reward_factor);
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(SKILLS_GLOBALS);
	
	EXPORT_FLOAT_DEFAULT("smoker_reward", g_Export.bossesRewards[L4D2ZombieClass_Smoker], 60.0);
	EXPORT_FLOAT_DEFAULT("boomer_reward", g_Export.bossesRewards[L4D2ZombieClass_Boomer], 35.0);
	EXPORT_FLOAT_DEFAULT("hunter_reward", g_Export.bossesRewards[L4D2ZombieClass_Hunter], 45.0);
	EXPORT_FLOAT_DEFAULT("spitter_reward", g_Export.bossesRewards[L4D2ZombieClass_Spitter], 35.0);
	EXPORT_FLOAT_DEFAULT("jockey_reward", g_Export.bossesRewards[L4D2ZombieClass_Jockey], 100.0);
	EXPORT_FLOAT_DEFAULT("charger_reward", g_Export.bossesRewards[L4D2ZombieClass_Charger], 150.0);
	EXPORT_FLOAT_DEFAULT("witch_reward", g_Export.bossesRewards[L4D2ZombieClass_Witch], 500.0);
	EXPORT_FLOAT_DEFAULT("tank_reward", g_Export.bossesRewards[L4D2ZombieClass_Tank], 1500.0);
	
	EXPORT_FLOAT_DEFAULT("witch_one_shot_reward", g_Export.witchOneshotReward, 1000.0);
	EXPORT_FLOAT_DEFAULT("team_reward_factor", g_Export.team_reward_factor, 0.5);
	EXPORT_INT_DEFAULT("print_reward", g_Export.print, 1);

	EXPORT_END();
}