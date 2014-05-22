#include <sourcemod>
#include <sdktools_functions>
#include <sdkhooks>

#define SENTRY 2

new Handle:g_cKnockback;
new Handle:g_cDamage;
new Float:g_fKnockback;
new g_iDamage;

public Plugin:myinfo = 
{
	name = "Sentry Tools",
	author = "Panzer",
	description = "Modify the knockback and damage from sentry bullets",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	g_cKnockback = CreateConVar("sm_sentry_knockback", "1.0", "Amount of knockback from sentry bullets");
	g_cDamage = CreateConVar("sm_sentry_damage", "16", "Amount of damage from sentry bullets");
	
	HookConVarChange(g_cKnockback, ConVarChanged_SentryTools);
	HookConVarChange(g_cDamage, ConVarChanged_SentryTools);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnConfigsExecuted()
{
	g_fKnockback	 = GetConVarFloat(g_cKnockback);
	g_iDamage = GetConVarInt(g_cDamage);
}

public ConVarChanged_SentryTools(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_cKnockback) 
		g_fKnockback = GetConVarFloat(g_cKnockback);
	if (convar == g_cDamage) 
		g_iDamage = GetConVarInt(g_cDamage);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:classname[32];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	if (StrEqual(classname, "obj_sentrygun"))
	{
		damage = g_fKnockback * g_iDamage;
		new damageExtra = RoundToNearest(GetEntProp(victim, Prop_Send, "m_iHealth") - (1.0 - g_fKnockback) * (g_iDamage));
		if (damageExtra >= 0)
			SetEntProp(victim, Prop_Send, "m_iHealth", damageExtra);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}