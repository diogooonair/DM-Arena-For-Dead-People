#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <smlib> 
#include <cstrike> 

#define PLUGIN_VERSION "1.1" 

#pragma tabsize 0

public Plugin myinfo =  
{ 
    name = "DM Arena for dead people", 
    author = "DiogoOnAir", 
    description = "DM Arena for dead people", 
    version = PLUGIN_VERSION, 
    url = "www.steamcommunity.com/id/diogo218dv" 
} 

bool g_indm[MAXPLAYERS+1];

public void OnPluginStart() 
{ 
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	AddNormalSoundHook(Event_SoundPlayed);
} 

/* Events */
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{ 
	for (int i = 1; i < MaxClients; i++)
	{
		g_indm[i] = false;
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_indm[client])
	{
		Client_RemoveAllWeapons(client);
		ShowWeaponMenu(client);
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_indm[victim])
	{
		CreateTimer(1.5, GODMTIMER, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else
	{
		Askifhewantstogodm(victim);
    }
	
	GetRoundEnd();
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) 
{ 
    g_indm[client] = false; 
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit); 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
} 

public Action Hook_SetTransmit(int entity, int client) 
{ 
    if (client != entity && (0 < entity <= MaxClients) && g_indm[client] && !g_indm[entity]) 
    	return Plugin_Handled; 
     
    return Plugin_Continue; 
}  

public Action OnTakeDamage(int victim,int &attacker,int &inflictor,float &damage,int &damagetype)
{
	if(g_indm[victim] && !g_indm[attacker])
	{
		return Plugin_Handled;
	}
	else if(g_indm[attacker] && !g_indm[victim])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}	

/* Menus */

public void Askifhewantstogodm(int client) 
{ 
    Menu menu = new Menu(WantDM);

	menu.SetTitle("Do you want to go to the DM arena?");
	menu.AddItem("ss", "Yes");
	menu.AddItem("nn", "No");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);  
} 

public int WantDM(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "ss"))
			{
				g_indm[client] = true; 
				CreateTimer(1.0, GODMTIMER, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				return;
		    }
		}
	}			
}

public void ShowWeaponMenu(int client) 
{ 
    Menu menu = new Menu(Weaponmenu);

	menu.SetTitle("Choose your weapon?");
	menu.AddItem("ak47", "AK47 + Deagle");
	menu.AddItem("m4a1", "M4A1-S + Deagle");
	menu.AddItem("m4a4", "M4A4 + Deagle");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);  
} 

public int Weaponmenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "ak47"))
			{
			  if(g_indm[client])
			  {
			  	Client_RemoveAllWeapons(client);
				GivePlayerItem(client, "weapon_ak47");
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_knife");
			  }
			}
			else if (StrEqual(info, "m4a1"))
			{
			  if(g_indm[client])
			  {
			  	Client_RemoveAllWeapons(client);
				GivePlayerItem(client, "weapon_m4a1_silencer");
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_knife");
			  }
			}
			else if (StrEqual(info, "m4a4"))
			{
			  if(g_indm[client])
			  {
			  	Client_RemoveAllWeapons(client);
				GivePlayerItem(client, "weapon_m4a4");
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_knife");
			  }
			}
		}
	}			
}

/* Functions */

public Action GODMTIMER(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	CS_RespawnPlayer(client);
}

void GetRoundEnd()
{
	int Cts = 0;
	int Terrorist = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{

			if(GetClientTeam(i) == 2 && !g_indm[i])
				Terrorist++;
			else if(GetClientTeam(i) == 3 && !g_indm[i])
				Cts++;
		}
	}

	if(Terrorist == 0)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && g_indm[i])
			{
				CS_TerminateRound(7.0, CSRoundEnd_CTWin, true);
				g_indm[i] = false;
			}
		}
	}
	else if(Cts == 0)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && g_indm[i])
			{
				CS_TerminateRound(7.0, CSRoundEnd_TerroristWin, true);
				g_indm[i] = false;
			}
		}
	}
} 

public Action Event_SoundPlayed(clients[64],&numClients,char sample[PLATFORM_MAX_PATH],&entity,&channel,float &volume,&level,&pitch,&flags) 
{
	if (entity 
		&& entity <= MaxClients 
		&& (StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1))
	{
		if (g_indm[entity])
		{
			return Plugin_Handled
		}
	}

	return Plugin_Continue
}
