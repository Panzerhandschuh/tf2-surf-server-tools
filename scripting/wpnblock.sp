#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3"
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hWpnTime = INVALID_HANDLE;
new Handle:g_hText = INVALID_HANDLE;
// new Handle:g_hSpawn = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new g_bEnabled = 1;
new bool:g_bText = true;
// new bool:g_bSpawn = true;
new Float:g_fWpnTime = 5.0;
new g_remCount;
new String:g_remArray[300][100];
public Plugin:myinfo = 
{
	name = "WpnBlock",
	author = "MikeJS",
	description = "Block usage of certain weapons.",
	version = PLUGIN_VERSION,
	url = "http://mikejs.byethost18.com/"
}
public OnPluginStart() {
	CreateConVar("sm_wpnblock_version", PLUGIN_VERSION, "WpnBlock version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_wpnblock", "1", "Wpnblock type: 0 = disable, 1 = remove on spawn (only), 2 = repeatable removal of weapons, see sm_wpntime.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hWpnTime = CreateConVar("sm_wpntime", "5.0", "Time to remove weapons again if sm_wpnblock = 2.");
	g_hText	   = CreateConVar("sm_wpntext", "1", "Enable printing of which weapons which has been disabled.");
	RegAdminCmd("sm_wpnblock_add", Command_add, ADMFLAG_KICK, "Add a blocked weapon.");
	RegAdminCmd("sm_wpnblock_clear", Command_clear, ADMFLAG_KICK, "Clear list of blocked weapons.");
	RegAdminCmd("sm_wpnblock_list", Command_list, ADMFLAG_KICK, "Show blocked weapons.");
	HookConVarChange(g_hEnabled,ConVarChange_WpnBlock);
	HookConVarChange(g_hWpnTime,ConVarChange_WpnBlock);
	HookConVarChange(g_hText, 	ConVarChange_WpnBlock);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarInt(g_hEnabled);
	g_fWpnTime = GetConVarFloat(g_hWpnTime);
	g_bText = GetConVarBool(g_hText);
	if(g_bEnabled == 1) {
		HookEvent("player_spawn",Event_Spawn);
	} else
	if(g_bEnabled == 2) {
		WpnCheck(INVALID_HANDLE);
	}
}
public ConVarChange_WpnBlock(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (convar == g_hEnabled)
	{
		g_bEnabled = GetConVarInt(g_hEnabled);
		if(g_bEnabled == 1) {
			HookEvent("player_spawn",Event_Spawn);
		} else
		if(g_bEnabled == 2) {
			WpnCheck(INVALID_HANDLE);
		}
	}
	if (convar == g_hWpnTime)
	{
		g_fWpnTime = GetConVarFloat(g_hWpnTime);
		CloseHandle(g_hTimer);
		if(g_bEnabled == 1) {
			CreateTimer(g_fWpnTime, WpnCheck);
		}
	}
	if (convar == g_hText)
	{
		g_bText = GetConVarBool(g_hText);
	}
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bEnabled == 1) Removeweapons(client);
}

public Action:WpnCheck(Handle:timer) {
	for(new x=1;x<=MaxClients;x++) {
		Removeweapons(x);
	}
	if(g_bEnabled == 2) {
		g_hTimer = CreateTimer(g_fWpnTime, WpnCheck);
	}
}

stock Removeweapons(x) {
	new ent;
	decl String:wpn[64];
	if(IsClientConnected(x) && IsClientInGame(x) && IsPlayerAlive(x)) {
		for(new y=0;y<6;y++) {
			if((ent = GetPlayerWeaponSlot(x, y))!=-1) {
				GetEdictClassname(ent, wpn, sizeof(wpn));
				for(new z=0;z<g_remCount;z++) {
					if(StrEqual(wpn, g_remArray[z])) {
						new weaponIndex;
						while((weaponIndex = GetPlayerWeaponSlot(x, y))!=-1) {
							RemovePlayerItem(x, weaponIndex);
							RemoveEdict(weaponIndex);
						}
						if (g_bText) {
						PrintToChat(x, "\x01[SM] Weapon \"\x04%s\x01\" has been disabled.", wpn);
						}
					}
				}
			}
		}
	}
}

public Action:Command_add(client, args) {
	decl String:argstr[64];
	GetCmdArgString(argstr, sizeof(argstr));
	StripQuotes(argstr);
	TrimString(argstr);
	g_remArray[g_remCount++] = argstr;
	return Plugin_Handled;
}
public Action:Command_clear(client, args) {
	g_remCount = 0;
	return Plugin_Handled;
}
public Action:Command_list(client, args) {
	ReplyToCommand(client, "Blocked weapons:");
	for(new i=0;i<g_remCount;i++) {
		ReplyToCommand(client, "%s", g_remArray[i]);
	}
	ReplyToCommand(client, "Total blocked: %i", g_remCount);
	return Plugin_Handled;
}