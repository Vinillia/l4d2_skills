#if defined _l4d2_skills_included
	#endinput
#endif

#define _l4d2_skills_included

#define SKILLS_CONFIG "data/skills.cfg"
#define SKILLS_GLOBALS "Skills Globals"

#define SKILLS_TAG "\x04[\x05Skills\x04]\x01"
#define SKILLS_TAG_NO_COLOR "[Skills]"

#define MAX_SKILL_NAME_LENGTH 64
#define MAX_SKILLS_COUNT 30

#define ERROR(%0) LogError(%0)

//#if defined DEBUG
	#define LOG(%0) LogMessage(%0)
//#else
//	#define LOG(%0) (0)	warning 215: expression has no effect
//#endif

#define EXPORT_START(%1) kv.Rewind(); kv.JumpToKey(%1, true)
#define EXPORT_END() KeyValueExportToFile(kv)

#define EXPORT_SECTION_START(%1) if (kv.JumpToKey(%1, true))
#define EXPORT_SECTION_END() kv.GoBack();

#define EXPORT_INT_DEFAULT(%1,%2,%3) Skills_ExportInt(kv, %1, %2, %3)
#define EXPORT_FLOAT_DEFAULT(%1,%2,%3) Skills_ExportFloat(kv, %1, %2, %3)
#define EXPORT_VECTOR_DEFAULT(%1,%2,%3) Skills_ExportVector(kv, %1, %2, %3)
#define EXPORT_STRING_DEFAULT(%1,%2,%3,%4) Skills_ExportString(kv, %1, %2, %3, %4)

#define EXPORT_INT(%1,%2) EXPORT_INT_DEFAULT(%1, %2, 0)
#define EXPORT_FLOAT(%1,%2) EXPORT_FLOAT_DEFAULT(%1, %2, 0.0)
#define EXPORT_VECTOR(%1,%2) EXPORT_VECTOR_DEFAULT(%1, %2, {0.0, 0.0, 0.0})
#define EXPORT_STRING(%1,%2,%3) EXPORT_STRING_DEFAULT(%1, %2, %3, "")

enum SkillType
{
	ST_INVALID = -1,
	ST_NONE,
	ST_ACTIVATION,
	ST_PASSIVE,
	ST_INPUT,
};

enum UpgradeImplementation
{
	UI_NULL,
	UI_DEFAULT,
	UI_CUSTOM
};

enum SkillState
{
	SS_NULL,
	SS_PURCHASED,
	SS_UPGRADED
};

typedef Skills_OnSkillStateReset = function Action( int id );
typedef Skills_OnUpgradeMenuRequest = function UpgradeImplementation( int client, int id, int &nextLevel, float &upgradeCost );
typedef Skills_OnCanClientUpgradeSkill = function bool( int client, int id );
typedef Skills_ItemMenuCallback = function void( int client, const char[] item );

// ====================================================================================================
// FORWARDS
// ====================================================================================================

/**
 * @brief Called when client opened main menu of skills
 *
 * @param menu			Handle of main menu 
 * @param client		Client index who opened menu
 *
 * @noreturn
 */
forward void Skills_OnClientSkillsMenuOpen( Menu menu, int client );

/**
 * @brief Called whenever some plugin registered skill
 *
 * @param name			Name of registered skill 
 * @param type			Type of registered skill (see SkillType)
 *
 * @noreturn
 */
forward void Skills_OnSkillRegistered( const char[] name, SkillType type );

/**
 * @brief Called when skill changes it's state  (Eg. upgraded or puchased)
 *
 * @param client		Client index who owns this skill 
 * @param id			Unique id of changed skill
 * @param state			New state of skill (see SkillState)
 *
 * @noreturn
 */
forward void Skills_OnSkillStateChanged( int client, int id, SkillState state );

/**
 * @brief Called when it's time to load skill settings
 * @remarks Use this with EXPORT_XXX helpers
 *
 * @param kv		KeyValues with skill settings 
 *
 * @noreturn
 */
forward void Skills_OnGetSkillSettings( KeyValues kv )

/**
 * @brief Called when l4d2_skills_core is started (OnPluginStart)
 *
 * @noreturn
 */
forward void Skills_OnSkillCoreStart();

/**
 * @brief Called when l4d2_skills_core is loaded (OnAllPluginsLoaded)
 *
 * @noreturn
 */
forward void Skills_OnSkillCoreLoaded();

/**
 * @brief Called when skills should reset their states
 *
 * @noreturn
 */
forward void Skills_OnSkillsStateReset();

// ====================================================================================================
// NATIVES
// ====================================================================================================

/**
 * @brief Returns number of purchased skills 
 *
 * @param client	Client index
 *
 * @return 			Number of purchased skills
 */
native int Skills_GetClientSkillsCount( int client );

/**
 * @brief Returns client money
 *
 * @param client	Client index
 *
 * @return 			Client money
 */
native float Skills_GetClientMoney( int client );

/**
 * @brief Sets client money
 *
 * @param client	Client index
 * @param money		Value to set
 *
 * @noreturn
 */
native void Skills_SetClientMoney( int client, float money );

/**
 * @brief Returns client money multiplier
 *
 * @param client	Client index
 *
 * @return 			Client money multiplier
 */
native float Skills_GetClientMoneyMultiplier( int client );

/**
 * @brief Sets client money multiplier
 *
 * @param client		Client index
 * @param multiplier	Value to set
 *
 * @noreturn
 */
native void Skills_SetClientMoneyMultiplier( int client, float multiplier );
	
/**
 * @brief Returns team money
 *
 * @return 			Client money
 */
native float Skills_GetTeamMoney();

/**
 * @brief Sets team money
 *
 * @param money		Value to set
 *
 * @noreturn
 */
native void Skills_SetTeamMoney( float money );

/**
 * @brief Returns team money multiplier
 *
 * @return 			Team money multiplier
 */
native float Skills_GetTeamMoneyMultiplier();

/**
 * @brief Sets team money multiplier
 *
 * @param multiplier	Value to set
 *
 * @noreturn
 */
native void Skills_SetTeamMoneyMultiplier( float multiplier );

/**
 * @brief Retrieves a skill name by ID
 *
 * @param id		Unique skill ID
 * @param name		Buffer to store name
 * @param length	Buffer length
 *
 * @return			true on success, false otherwise
 */
native bool Skills_GetName( int id, char[] name, int length = MAX_SKILL_NAME_LENGTH );

/**
 * @brief Retrieves a skill ID by name
 *
 * @param name		Skill name
 *
 * @return			ID on success, -1 on failure
 */
native int Skills_GetID( const char[] name );

/**
 * @brief Returns number of registered skills
 *
 * @noreturn
 */
native int Skills_GetCount();

/**
 * @brief Returns skill type by it's name
 *
 * @param name		Skill name
 *
 * @return			SkillType
 */
native SkillType Skills_GetType( const char[] name );

/**
 * @brief Returns plugin handle of the skill owner
 *
 * @param name		Skill name
 *
 * @return			Plugin handle
 */
native Handle Skills_GetOwner( const char[] name );

/**
 * @brief Checks if skills can be upgraded
 *
 * @param name		Skill name
 *
 * @return			true if can be upgraded, false otherwise
 */
native bool Skills_IsUpgradable( const char[] name );

/**
 * @brief Checks if client have skill by name
 *
 * @param client	Client index
 * @param name		Skill name
 *
 * @return			true if client has skill, false otherwise
 */
native bool Skills_ClientHaveByName( int client, const char[] name );

/**
 * @brief Checks if client have skill by ID
 *
 * @param client	Client index
 * @param id		Skill ID
 *
 * @return			true if client has skill, false otherwise
 */
native bool Skills_ClientHaveByID(  int client, int id );

/**
 * @brief Changes skill state
 * @remarks If client already has skill then skill will be upgraded if can be 
 * @remarks Pass false to disable skill  
 *
 * @param client	Client index
 * @param id		Skill ID
 * @param bool		State
 *
 * @noreturn
 */
native void Skills_ChangeState( int client, int id, bool state );

/**
 * @brief Returns default upgrade menu
 * @remarks Menu must be closed via delete
 *
 * @param client	Client index
 * @param id		Skill ID
 * @param nextLevel	Next level of skill
 * @param cost		Cost of upgrade
 *
 * @return			Menu handle
 */
native Menu Skills_RequestDefaultUpgradeMenu( int client, int id, int nextLevel, float cost );

/**
 * @brief Adds item to main menu
 *
 * @param item		Unique item name
 * @param id		Display string
 * @param callback	Callback for added item
 *
 * @noreturn
 */
native void Skills_AddMenuItem(const char[] item, const char[] display, Skills_ItemMenuCallback callback);

/**
 * @brief Registers new skill
 *
 * @param name			Unique skill name
 * @param SkillType		Type of skill (see SkilType)
 * @param upgradable	Pass true if skill can be upgraded, false otherwise 
 *
 * @return				Unique skill ID
 */
native int Skills_Register( const char[] name, SkillType type, bool upgradable = false );

/**
 * @brief Exports int value from config by name
 * @remarks Use escape '/' to travese multiple keys
 *
 * @param skill			Key to travse (Usually skill name)
 * @param key			Key to export
 * @param value			Variable to store exported value 
 * @param defaultValue 	Variable to store default value if key doesn't exist 
 * @param createKey 	Creates key if it doesn't exist (optional)
 *
 * @return				true if key exist and was successfully exported, false otherwise
 */
native bool Skills_ExportIntByName( const char[] skill, const char[] key, int &value, const int defaultValue = 0, bool createKey = false);

/**
 * @brief Exports float value from config by name
 * @remarks Use escape '/' to travese multiple keys
 *
 * @param skill			Key to travse (Usually skill name)
 * @param key			Key to export
 * @param value			Variable to store exported value 
 * @param defaultValue 	Variable to store default value if key doesn't exist 
 * @param createKey 	Creates key if it doesn't exist (optional)
 *
 * @return				true if key exist and was successfully exported, false otherwise
 */
native bool Skills_ExportFloatByName( const char[] skill, const char[] key, float &value, const float defaultValue = 0.0, bool createKey = false);

/**
 * @brief Exports string from config by name
 * @remarks Use escape '/' to travese multiple keys
 *
 * @param skill			Key to travse (Usually skill name)
 * @param key			Key to export
 * @param buffer		Buffer to store exported value
 * @param maxlength		Length of buffer
 * @param defaultValue 	Variable to store default value if key doesn't exist 
 * @param createKey 	Creates key if it doesn't exist (optional)
 *
 * @return				true if key exist and was successfully exported, false otherwise
 */
native bool Skills_ExportStringByName( const char[] skill, const char[] key, char[] buffer, int maxlength, const char[] defaultValue = "", bool createKey = false);

/**
 * @brief Exports vector from config by name
 * @remarks Use escape '/' to travese multiple keys
 *
 * @param skill			Key to travse (Usually skill name)
 * @param key			Key to export
 * @param value			Vector variable to store exported value
 * @param defaultValue 	Variable to store default value if key doesn't exist 
 * @param createKey 	Creates key if it doesn't exist (optional)
 *
 * @return				true if key exist and was successfully exported, false otherwise
 */
native bool Skills_ExportVectorByName( const char[] skill, const char[] key, float value[3], const float defaultValue[3] = {0.0, 0.0, 0.0}, bool createKey = false);

/**
 * @brief Used to request reload from config module
 * @remarks Will produce error if Skills_OnGetSkillSettings callback will not be found
 *
 * @param reopen	If true config will be reopened to take user changes 
 *
 * @noreturn
 */
native void Skills_RequestConfigReload( bool reopen = true );

// ====================================================================================================
// STOCKS/WRAPPERS
// ====================================================================================================

stock void Skills_AddClientMoney( int client, float add, bool noMultiplier = false, bool print = false )
{
	if ( !noMultiplier )
		add *= Skills_GetClientMoneyMultiplier(client);
		
	float money = Skills_GetClientMoney(client) + add;
	Skills_SetClientMoney(client, money);

	if (print)
		Skills_PrintToChat(client, "\x04+\x05%.0f", add);
}

stock void Skills_AddTeamMoney( float add, bool noMultiplier = false )
{
	if ( !noMultiplier )
		add *= Skills_GetTeamMoneyMultiplier();
		
	float money = Skills_GetTeamMoney() + add;
	Skills_SetTeamMoney(money);
}

stock bool Skills_ExportIntByID( int id, const char[] key, int &value, const int defaultValue = 0, bool createKey = false)
{
	char name[MAX_SKILL_NAME_LENGTH];
	
	if ( !Skills_GetName(id, name) )
		return false;	
	
	return Skills_ExportIntByName(name, key, value, defaultValue, createKey);
}

stock bool Skills_ExportFloatByID( int id, const char[] key, float &value, const float defaultValue = 0.0, bool createKey = false)
{
	char name[MAX_SKILL_NAME_LENGTH];
	
	if ( !Skills_GetName(id, name) )
		return false;	
	
	return Skills_ExportFloatByName(name, key, value, defaultValue, createKey);
}

stock bool Skills_ExportStringByID( int id, const char[] key, char[] value, int maxlength, const char[] defaultValue = "", bool createKey = false)
{
	char name[MAX_SKILL_NAME_LENGTH];
	
	if ( !Skills_GetName(id, name) )
		return false;	
	
	return Skills_ExportStringByName(name, key, value, maxlength, defaultValue, createKey);
}

stock bool Skills_ExportVectorByID( int id, const char[] key, float value[3], const float defaultValue[3] = {0.0, 0.0, 0.0}, bool createKey = false)
{
	char name[MAX_SKILL_NAME_LENGTH];
	
	if ( !Skills_GetName(id, name) )
		return false;	
	
	return Skills_ExportVectorByName(name, key, value, defaultValue, createKey);
}

stock bool Skills_ExportInt( KeyValues kv, const char[] key, int& value, const int defaultValue = 0 )
{
	int id;
	
	if ( !kv.GetSectionSymbol(id) )
		return false;

	if ( !kv.JumpToKey(key) )
	{
		value = defaultValue;
		kv.SetNum(key, defaultValue);
		kv.JumpToKeySymbol(id);
		return false;
	}
	
	value = kv.GetNum(NULL_STRING, defaultValue)
	kv.GoBack();
	return true;
}

stock bool Skills_ExportFloat( KeyValues kv, const char[] key, float& value, const float defaultValue = 0.0 )
{
	int id;
	
	if ( !kv.GetSectionSymbol(id) )
		return false;

	if ( !kv.JumpToKey(key) )
	{
		value = defaultValue;
		kv.SetFloat(key, defaultValue);
		kv.JumpToKeySymbol(id);
		return false;
	}

	value = kv.GetFloat(NULL_STRING, defaultValue);
	kv.GoBack();
	return true;
}

stock bool Skills_ExportString( KeyValues kv, const char[] key, char[] value, int maxlength, const char[] defaultValue = "" )
{
	int id;
	
	if ( !kv.GetSectionSymbol(id) )
		return false;

	if ( !kv.JumpToKey(key) )
	{
		strcopy(value, maxlength, defaultValue);
		kv.SetString(key, defaultValue);
		kv.GoBack();
		kv.JumpToKeySymbol(id);
		return false;
	}
	
	kv.GetString(NULL_STRING, value, maxlength, defaultValue);
	kv.GoBack();
	return true;
}

stock bool Skills_ExportVector( KeyValues kv, const char[] key, float value[3], const float defaultValue[3] = { 0.0, 0.0, 0.0 } )
{
	int id;
	
	if ( !kv.GetSectionSymbol(id) )
		return false;

	if ( !kv.JumpToKey(key) )
	{
		value = defaultValue;
		kv.SetVector(key, defaultValue);
		kv.JumpToKeySymbol(id);
		return false;
	}
	
	kv.GetVector(NULL_STRING, value, defaultValue);
	kv.GoBack();
	return true;
}

stock void KeyValueExportToFile( KeyValues kv )
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, SKILLS_CONFIG);
	
	kv.Rewind();
	kv.ExportToFile(szPath);
}

// ====================================================================================================
// STOCKS/HELPERS
// ====================================================================================================

stock void ExecuteCheatCommand(int client, const char[] command, const char[] arg)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommandEx(client, "%s %s", command, arg);
	SetCommandFlags(command, flags);
}

stock bool ClassMatchesComplex( int entity, const char[] match )
{
	static char name[36];
	
	if ( !GetEntityClassname(entity, name, sizeof name) )
		return false;
		
	return strcmp(name, match, false) == 0;
}

stock bool IsValidEntRef(int ref)
{
	int entity = EntRefToEntIndex(ref);
	return entity > 0 && IsValidEntity(entity);
}

stock void Skills_PrintToChat( int client, const char[] fmt, any ... )
{
	char buffer[254];
	VFormat(buffer, sizeof buffer, fmt, 3);
	PrintToChat(client, "%s %s", SKILLS_TAG, buffer);
}

stock void Skills_PrintToChatAll( const char[] fmt, any ... )
{
	char buffer[254];
	VFormat(buffer, sizeof buffer, fmt, 2);
	PrintToChatAll("%s %s", SKILLS_TAG, buffer);
}

stock void Skills_ReplyToCommand( int client, const char[] fmt, any ... )
{
	char buffer[254];
	VFormat(buffer, sizeof buffer, fmt, 3);
	ReplyToCommand(client, "%s %s", GetCmdReplySource() == SM_REPLY_TO_CONSOLE ? SKILLS_TAG_NO_COLOR : SKILLS_TAG, buffer);
}