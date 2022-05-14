#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <l4d2_skills>

#define MY_EXPORT_NAME "Team Upgrades"

#define MAX_UPGRADES 12
#define UPGRADE_NAME_LENGTH 64

public Plugin myinfo =
{
	name = "[L4D2] Team Upgrades",
	author = "BHaType",
	description = "Adds team upgrades to skills menu",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

typedef UpgradeAction = function void(int buyer); 

enum struct SettingsManager
{
	StringMap settings;
	
	void SetValue(const char[] key, any value)
	{
		this.settings.SetValue(key, value);
	}
	
	any GetValue(const char[] key, any defaultValue = 0)
	{
		any value;
		
		if (!this.settings.GetValue(key, value))
			return defaultValue;
		
		return value;
	}

	void ExportInt(KeyValues kv, const char[] key, int defaultValue = 0)
	{
		int value;
		EXPORT_INT_DEFAULT(key, value, defaultValue);
		this.SetValue(key, value);
	}

	void ExportFloat(KeyValues kv, const char[] key, float defaultValue = 0.0)
	{
		float value;		
		EXPORT_FLOAT_DEFAULT(key, value, defaultValue);
		this.SetValue(key, value);
	}
}

enum struct TeamUpgrade
{
	char name[UPGRADE_NAME_LENGTH];
	float cost;

	UpgradeAction action;
}

TeamUpgrade g_TeamUpgrades[MAX_UPGRADES];
int g_iUpgradesCount;

SettingsManager g_SettingsManager;

public void OnPluginStart()
{
	g_SettingsManager.settings = new StringMap();

	RegAdminCmd("sm_teamupgrades_invoke", sm_teamupgrades_invoke, ADMFLAG_CHEATS);
}

public Action sm_teamupgrades_invoke( int client, int args )
{
	char name[UPGRADE_NAME_LENGTH];
	GetCmdArg(1, name, sizeof name);

	for(int i; i < g_iUpgradesCount; i++)
	{
		if (StrContains(g_TeamUpgrades[i].name, name, false) != -1)
		{
			InvokeUpgradeAction(i, client);
			return Plugin_Handled;
		}
	}

	Skills_ReplyToCommand(client, "Failed to find upgrade %s", name);
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	Skills_AddMenuItem("skills_team_upgrades", "Team Upgrades", ItemMenuCallback);
	Skills_RequestConfigReload();
}

public void ItemMenuCallback( int client, const char[] item )
{
	ShowClientShop(client);
}

void ShowClientShop( int client, int selection = 0 )
{
	Menu menu = new Menu(VMenuHandler);
	char temp[4];

	for(int i; i < g_iUpgradesCount; i++)
	{
		IntToString(i, temp, sizeof temp);
		menu.AddItem(temp, g_TeamUpgrades[i].name);
	}

	menu.ExitButton = true;
	menu.SetTitle("Skills: Shop");
	menu.DisplayAt(client, selection, MENU_TIME_FOREVER);
}

public int VMenuHandler( Menu menu, MenuAction action, int client, int index )
{
	switch( action )
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if( index == MenuCancel_ExitBack || index == MenuCancel_NoDisplay )
				FakeClientCommand(client, "sm_skills");
		}
		case MenuAction_Select:
		{	
			ShowClientShop(client, menu.Selection);

			float money, cost;
			int upgradeID;
			char item[8];

			menu.GetItem(index, item, sizeof item);
			upgradeID = StringToInt(item);
			money = Skills_GetTeamMoney(); 
			cost = g_TeamUpgrades[upgradeID].cost;

			if (money - cost < 0)
			{
				Skills_PrintToChat(client, "\x03Not enough \x04team \x5money");
				return 0;
			}

			InvokeUpgradeAction(upgradeID, client);

			Skills_SetTeamMoney(money - cost);
			Skills_PrintToChatAll("\x05%N \x04bought \x03%s \x04team upgrade", client, g_TeamUpgrades[upgradeID].name);
		}
	}
	
	return 0;
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	EXPORT_START(MY_EXPORT_NAME);

	EXPORT_SECTION_START("More Health")
	{
		g_SettingsManager.ExportInt(kv, "more_health_add", 15);
		RegisterUpgrade(kv, "More Health", OnHealthUpgrade);
	}

	EXPORT_END();
}

bool RegisterUpgrade(KeyValues kv, const char[] name, UpgradeAction action)
{
	if (g_iUpgradesCount == MAX_UPGRADES)
	{
		ERROR("Reached limit of upgrades %i/%i", g_iUpgradesCount, MAX_UPGRADES);
		return false;
	}
	
	int i = g_iUpgradesCount++;
	
	strcopy(g_TeamUpgrades[i].name, UPGRADE_NAME_LENGTH, name);
	g_TeamUpgrades[i].action = action;

	EXPORT_FLOAT_DEFAULT("cost", g_TeamUpgrades[i].cost, 5000.0);
	return true;
}

void InvokeUpgradeAction(int upgradeID, int buyer)
{
	Call_StartFunction(null, g_TeamUpgrades[upgradeID].action);
	Call_PushCell(buyer);
	Call_Finish();
}

public void OnHealthUpgrade(int buyer)
{
	int newValue;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		newValue = GetEntProp(i, Prop_Send, "m_iMaxHealth") + g_SettingsManager.GetValue("more_health_add");
		SetEntProp(i, Prop_Send, "m_iMaxHealth", newValue);
	}
}