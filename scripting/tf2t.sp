#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define DEBUG
#define SCOUT_BOOST

// Colors
#define cDefault							0x01
#define cLightGreen 						0x03
#define cGreen								0x04
#define cDarkGreen  						0x05

#pragma semicolon 1

new Handle:g_cEnable;
new Handle:g_cSpeedoMeter;
new Handle:g_cHighJump;
#if defined SCOUT_BOOST 
new Handle:g_cScoutBoostAmount;
#endif

new g_iEnable;
new g_iSpeedoMeter;
new bool:g_bHighJump;
#if defined SCOUT_BOOST 
new Float:g_fScoutBoostAmount;
#endif
new CanDJump[MAXPLAYERS+1];
new InTrimp[MAXPLAYERS+1];
new WasInJumpLastTime[MAXPLAYERS+1];
new WasOnGroundLastTime[MAXPLAYERS+1];
new Float:VelLastTime[MAXPLAYERS+1][3];
// Menu
new Handle:g_hSpeedoMeter;
// Database
new Handle:SQLTF2turbo = INVALID_HANDLE;
// Speedometer
new g_ShowSpeedometer[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "TF2Turbo",
	author = "caesium & cowe and fixes by ChrisFPS",
	description = "TF2turbo",
	version = "1.2",
	url = "forums.alliedmodders.com"
}


public OnPluginStart()
{
	// settings
	g_cEnable 				= CreateConVar("tf2t_enable", "1", "Enable/Disable TF2T - 1 = Enable, 0 = Disable (Allow Speedometer)");
	g_cSpeedoMeter 			= CreateConVar("tf2t_speedometer", "1", "Default Speedometer Value");
	#if defined SCOUT_BOOST
	g_cScoutBoostAmount 	= CreateConVar("tf2t_scoutboostamount", "1.0", "Scout Boost Modifier");
	#endif
	g_cHighJump 			= CreateConVar("tf2t_highjump", "1", "Enable/Disable Highjump");
	
	// sellf-damage boost
	HookEvent("player_hurt", EventPlayerHurt);
	
	HookConVarChange(g_cEnable			, ConVarChanged_TF2Turbo);
	HookConVarChange(g_cSpeedoMeter		, ConVarChanged_TF2Turbo);
	#if defined SCOUT_BOOST
	HookConVarChange(g_cScoutBoostAmount, ConVarChanged_TF2Turbo);
	#endif
	HookConVarChange(g_cHighJump		, ConVarChanged_TF2Turbo);
	
	RegConsoleCmd("sm_speedometer", Command_Speedometer, "Client console command to enable/disable speedometer");
	RegConsoleCmd("sm_turbo", Command_Speedometer, "Client console command to enable/disable speedometer");
	
	InitSQL();
}

public InitSQL() {
	decl String:error[255];
	SQLTF2turbo = SQLite_UseDatabase("tf2turbo", error, sizeof(error));
	if(SQLTF2turbo == INVALID_HANDLE) {
		SetFailState(error);
		#if defined DEBUG
		LogToGame("%s", error);
		#endif
	}
	SQL_FastQuery(SQLTF2turbo, "CREATE TABLE IF NOT EXISTS `tf2turbo` (`steamid` VARCHAR(32), speedometer INTEGER, PRIMARY KEY (`steamid`));");
}

public Action:Command_Speedometer(client, args)
{
	if(IsClientInGame(client))
	{
		SpeedometerMenu(client, args);
	}
}

public MenuHandler(Handle:menu, MenuAction:action, client, item)
{
	if(menu == g_hSpeedoMeter)
	{
		if(action == MenuAction_Select)
		{
			if(item == 0)
			{
				SetInfo(client,"speedometer",1); // Enable
				g_ShowSpeedometer[client] = 1;
				PrintToChat(client,"%c[%cTF2T%c] Speedometer enabled!",cDefault,cGreen,cDefault);
			} else
			if(item == 1)
			{
				SetInfo(client,"speedometer",0); // Disable
				g_ShowSpeedometer[client] = 0;
				PrintToChat(client,"%c[%cTF2T%c] Speedometer disabled!",cDefault,cGreen,cDefault);
			}
		}
	}
}

public Action:SpeedometerMenu(client, args) 
{
	new Handle:menu = CreateMenu(MenuHandler, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "Enable/Disable Speedometer");
	AddMenuItem(menu,"Enable","Enable");
	AddMenuItem(menu,"Disable","Disable");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 50);
	g_hSpeedoMeter = menu;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

public OnClientPostAdminCheck(client)
{
	if(!(SQLTF2turbo == INVALID_HANDLE))
	{
		if (ReadInfo(client,"speedometer") == 1)
		{
			g_ShowSpeedometer[client] = 1;
			return;
		} else
		if (ReadInfo(client,"speedometer") == 0)
		{
			g_ShowSpeedometer[client] = 0;
			return;
		} else
		{
			g_ShowSpeedometer[client] = g_iSpeedoMeter;
		}
	}
}

public OnConfigsExecuted()
{
	g_iEnable			= GetConVarBool(g_cEnable);
	g_iSpeedoMeter 		= GetConVarInt(g_cSpeedoMeter);
	#if defined SCOUT_BOOST
	g_fScoutBoostAmount = GetConVarFloat(g_cScoutBoostAmount);
	#endif
	g_bHighJump 		= GetConVarBool(g_cHighJump);
}

public ConVarChanged_TF2Turbo(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_cEnable) 			g_iEnable 			= GetConVarInt(g_cEnable);
	if(convar == g_cSpeedoMeter) 		g_iSpeedoMeter 		= GetConVarInt(g_cSpeedoMeter);
	#if defined SCOUT_BOOST
	if(convar == g_cScoutBoostAmount) 	g_fScoutBoostAmount = GetConVarFloat(g_cScoutBoostAmount);
	#endif
	if(convar == g_cHighJump) 			g_bHighJump 		= GetConVarBool(g_cHighJump);
}

public OnPostThink(i)
{
	new Float:PlayerVel[3];
	new Float:TrimpVel[3];
	new Float:PlayerSpeed[1];
	new Float:PlayerSpeedLastTime[1];
	new String:TempString[32];
	new GroundEntity;
			
	if( IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) )
	{
		GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel);
		PlayerSpeed[0] = SquareRoot(  FloatAdd(FloatMul(PlayerVel[0],PlayerVel[0]), FloatMul(PlayerVel[1],PlayerVel[1])) );
		
		// speedometer
		if( g_ShowSpeedometer[i] )
		{
			if (FloatCompare(PlayerSpeed[0], (400.0*1.6/1.2)) > 0)
			{
				FloatToString((FloatDiv(PlayerSpeed[0],(4.0*1.6))),TempString,32);
				PrintCenterText(i,"%i%", StringToInt(TempString));
			}
			else
			{
				PrintCenterText(i,"");
			}
		}
		
		if(!g_iEnable) return;
		
		GroundEntity = GetEntDataEnt2(i, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")); // 0 = World (aka on ground) | -1 = In air | Any other positive value = CBaseEntity entity-index below player.

		// bhop, trimp, normal jump
		if( (GetClientButtons(i) & IN_JUMP) && ( (GroundEntity != -1) || WasOnGroundLastTime[i] ) )
		{
			PlayerSpeedLastTime[0] = SquareRoot(  FloatAdd(FloatMul(VelLastTime[i][0],VelLastTime[i][0]), FloatMul(VelLastTime[i][1],VelLastTime[i][1]))  );
			
			// check we haven't been slowed down since last time
			if(FloatCompare(PlayerSpeedLastTime[0], PlayerSpeed[0]) > 0)
			{
				if(FloatCompare(PlayerSpeed[0], 0.0) == 1)
				{
					PlayerVel[0] = FloatDiv(FloatMul(PlayerVel[0], PlayerSpeedLastTime[0]), PlayerSpeed[0]);
					PlayerVel[1] = FloatDiv(FloatMul(PlayerVel[1], PlayerSpeedLastTime[0]), PlayerSpeed[0]);
				}
				PlayerSpeed[0] = PlayerSpeedLastTime[0];
			}
			
			// trimp
			if( ( (GetClientButtons(i) & IN_FORWARD) || (GetClientButtons(i) & IN_BACK) ) && (FloatCompare(PlayerSpeed[0], (400.0 * 1.6)) >= 0) && g_bHighJump)
			{
				TrimpVel[0] = FloatMul(PlayerVel[0], Cosine(70.0*3.14159265/180.0));
				TrimpVel[1] = FloatMul(PlayerVel[1], Cosine(70.0*3.14159265/180.0));
				TrimpVel[2] = FloatMul(PlayerSpeed[0], Sine(70.0*3.14159265/180.0));
				
				InTrimp[i] = true;
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, TrimpVel);
			}
			
			// bhop (and normal jump)
			else
			{
				PlayerVel[2] = 800.0/3.0;
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
			}
		}
		#if defined SCOUT_BOOST			
		// doublejump
		else if( (InTrimp[i] || (CanDJump[i] && (TF2_GetPlayerClass(i) == TFClass_Scout))) && (WasInJumpLastTime[i] == 0) && (GetClientButtons(i) & IN_JUMP))
		{
			PlayerSpeedLastTime[0] = FloatMul(g_fScoutBoostAmount, SquareRoot(  FloatAdd(FloatMul(VelLastTime[i][0],VelLastTime[i][0]), FloatMul(VelLastTime[i][1],VelLastTime[i][1]))  ));
			
			if (FloatCompare(PlayerSpeedLastTime[0], 400.0) < 0)
			{
				PlayerSpeedLastTime[0] = 400.0;
			}
			
			if(FloatCompare(PlayerSpeed[0], 0.0) == 0)
			{
				PlayerSpeedLastTime[0] = 0.0;
			} else
			{
				PlayerVel[0] = FloatDiv(FloatMul(PlayerVel[0], PlayerSpeedLastTime[0]), PlayerSpeed[0]);
				PlayerVel[1] = FloatDiv(FloatMul(PlayerVel[1], PlayerSpeedLastTime[0]), PlayerSpeed[0]);
			}
			
			PlayerVel[2] = 800.0/3.0;
			
			CanDJump[i] = false;
			InTrimp[i] = false;
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
		}
		#endif			
		
		// enable doublejump
		if( ( (InTrimp[i] == 1) || (CanDJump[i] == 0) )	&& (GroundEntity != -1) )
		{
			CanDJump[i] = true;
			InTrimp[i] = false;
		}
		
		
		// always save this stuff for next time
		WasInJumpLastTime[i] = (GetClientButtons(i) & IN_JUMP);
		WasOnGroundLastTime[i] = GroundEntity != -1 ? 1 : 0;
		VelLastTime[i][0] = PlayerVel[0];
		VelLastTime[i][1] = PlayerVel[1];
		VelLastTime[i][2] = PlayerVel[2];	
	}	
}


// self-damage boost
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_iEnable) return Plugin_Continue;
	
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");
	
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	
	if(attacker == victim)
	{
		new Float:DamageVel[3];
		new Float:DamageSpeed[1];
		new Float:DamageOldSpeed[1];
		
		GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", DamageVel);
		
		DamageSpeed[0] = SquareRoot(  FloatAdd(FloatAdd(FloatMul(DamageVel[0],DamageVel[0]),FloatMul(DamageVel[1],DamageVel[1])), FloatMul(DamageVel[2],DamageVel[2]))  );
		
		DamageOldSpeed[0] = SquareRoot(  FloatAdd(FloatAdd(FloatMul(VelLastTime[attacker][0],VelLastTime[attacker][0]), FloatMul(VelLastTime[attacker][1],VelLastTime[attacker][1])), FloatMul(VelLastTime[attacker][2],VelLastTime[attacker][2]))  );
		
		if(FloatCompare(DamageSpeed[0], DamageOldSpeed[0]) > 0)
		{
			DamageVel[0] = FloatMul(1.2, DamageVel[0]);
			DamageVel[1] = FloatMul(1.2 ,DamageVel[1]);
			
			TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, DamageVel);
		}	
	}
	return Plugin_Continue;
}

stock SetInfo(client, String:type[], value) {
	new String:completebuffer[255];
	new String:steamid[64];
	GetClientAuthString(client, steamid, 64);
	Format(completebuffer,sizeof(completebuffer),"REPLACE into tf2turbo (steamid, %s) values ('%s', %d);", type, steamid, value);
	SQL_Query(SQLTF2turbo, completebuffer);
}

stock ReadInfo(client, String:type[]) {
	new String:scorebuffer[255];
	new String:steamid[64];
	new value;
	new DBResult:result;
	GetClientAuthString(client, steamid, 64);
	Format(scorebuffer,sizeof(scorebuffer),"SELECT `%s` FROM `tf2turbo` WHERE `steamid` = '%s'", type, steamid);
	new Handle:qry = SQL_Query(SQLTF2turbo, scorebuffer);
	while (SQL_FetchRow(qry)) {
		value = SQL_FetchInt(qry, 0, result);
	}
	CloseHandle(qry);
	if(result != DBVal_Data) return -1;
	return value;
}