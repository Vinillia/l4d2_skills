#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <l4d2_skills>

public Plugin myinfo =
{
	name = "[L4D2] Skills Shop",
	author = "BHaType",
	description = "Simple shop module for skills",
	version = "1.0",
	url = "https://github.com/Vinillia/l4d2_skills"
};

enum struct Item
{
	char classname[36];
	char display[36];
	float cost;
}

Item g_shopList[] =
{
	{ "laser_sight"					  , "Laser sight" 			, 0.0 },					
	{ "weapon_upgradepack_explosive"  , "Explosive ammo pack" 	, 0.0 },	
	{ "weapon_upgradepack_incendiary" , "Incendiary ammo pack"	, 0.0 },	
	{ "weapon_pain_pills"			  , "Pain pills"			, 0.0 }, 				
	{ "weapon_adrenaline"			  , "Adrenaline"			, 0.0 },    			
	{ "weapon_defibrillator"		  , "Defibrillator"			, 0.0 }, 			
	{ "weapon_first_aid_kit"		  , "First aid kit"			, 0.0 },			
	{ "weapon_molotov"				  , "Molotov"				, 0.0 },			
	{ "weapon_pipe_bomb"			  , "Pipe bomb" 			, 0.0 },			
	{ "weapon_vomitjar"				  , "Vomitjar"				, 0.0 }				
};

public void OnAllPluginsLoaded()
{
	Skills_AddMenuItem("skills_shop", "Shop", ItemMenuCallback);
	Skills_RequestConfigReload();
}

public void ItemMenuCallback( int client, const char[] item )
{
	ShowClientShop(client);
}

void ShowClientShop( int client, int selection = 0 )
{
	Menu menu = new Menu(VMenuHandler);
	char display[64];
	Item item;
	
	for( int i; i < sizeof g_shopList; i++ )
	{
		item = g_shopList[i];
		FormatEx(display, sizeof display, "%s (%.0f)", item.display, item.cost);
		menu.AddItem(item.classname, display);
	}
	
	menu.SetTitle("Skills: Shop");
	menu.ExitButton = true;
	
	menu.DisplayAt(client, selection, MENU_TIME_FOREVER);
}

public int VMenuHandler( Menu menu, MenuAction action, int client, int index )
{
	switch( action )
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if( index == MenuCancel_NoDisplay )
				FakeClientCommand(client, "sm_skills");
		}
		case MenuAction_Select:
		{
			ShowClientShop(client, menu.Selection);
			
			char item[64];
			int itemIndex = -1;
			
			menu.GetItem(index, item, sizeof item);
	
			for( int i; i < sizeof g_shopList; i++ )
			{
				if ( strcmp(g_shopList[i].classname, item) == 0 )
				{
					itemIndex = i;
					break;
				}
			}
	
			if ( itemIndex == -1 )
				return 0;
			
			float money = Skills_GetClientMoney(client);
			
			if ( money < g_shopList[itemIndex].cost )
			{
				Skills_PrintToChat(client, "\x05You \x04don't \x05have enough \x03money");
				return 0;
			}
			
			if ( IsUpgrade(item) )
			{
				GiveUpgrade(client, "laser_sight");
			}
			else
			{
				GivePlayerItem(client, g_shopList[itemIndex].classname);
			}
			
			Skills_AddClientMoney(client, -g_shopList[itemIndex].cost);
		}
	}
	
	return 0;
}

bool IsUpgrade( const char[] item )
{
	return strcmp(item, "laser_sight") == 0;
}

void GiveUpgrade( int client, const char[] upgrade )
{
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", 0);
	FakeClientCommandEx(client, "upgrade_add %s", upgrade);
	SetCommandFlags("upgrade_add", flags);
}

public void Skills_OnGetSkillSettings( KeyValues kv )
{
	kv.Rewind();
	kv.JumpToKey("Skills Shop", true);
	
	char buffer[64];
	for( int i; i < sizeof g_shopList; i++ )
	{
		FormatEx(buffer, sizeof buffer, "%s_cost", g_shopList[i].classname);
		Skills_ExportFloat(kv, buffer, g_shopList[i].cost, 250.0);
	}
}