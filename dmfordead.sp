#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <smlib> 
#include <cstrike> 

#define PLUGIN_VERSION "1.6" 

#pragma tabsize 0

ConVar sv_footsteps;

public Plugin myinfo =  
{ 
    name = "DM Arena for dead people", 
    author = "DiogoOnAir", 
    description = "DM Arena for dead people", 
    version = PLUGIN_VERSION, 
    url = "www.steamcommunity.com/id/diogo218dv" 
} 

bool g_indm[MAXPLAYERS+1];

Handle menutodelete[MAXPLAYERS + 1] = INVALID_HANDLE;

public void OnPluginStart() 
{ 
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
    sv_footsteps = FindConVar("sv_footsteps");
	
 	AddNormalSoundHook(Event_FootSteps);
	AddNormalSoundHook(Event_WeaponPlayed);
 	AddTempEntHook("Shotgun Shot", WeaponSoundHook);
} 


/* Events */
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{ 
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			g_indm[i] = false;
			if(menutodelete[i] != INVALID_HANDLE)
			{
				delete menutodelete[i];
				menutodelete[i] = INVALID_HANDLE;
			}
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
		return;
		
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
    
    SendConVarValue(client, sv_footsteps, "0");
} 

public Action Hook_SetTransmit(int entity, int client) 
{ 
    if (client != entity && (0 < entity <= MaxClients) && g_indm[client] != g_indm[entity]) 
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

	menu.SetTitle("Do you want to go to the DM Arena?");
	menu.AddItem("ss", "Yes");
	menu.AddItem("nn", "No");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);  
	
	menutodelete[client] = menu;
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

	menu.SetTitle("Escolhe a arma?");
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

public Action Event_FootSteps(int clients[64],&numClients,char sample[PLATFORM_MAX_PATH],&entity,&channel,float &volume,&level,&pitch,&flags) 
{
	if (entity && IsValidClient(entity) && (StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1))
	{
			numClients = 0;
			if(!g_indm[entity])
			{
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(IsClientInGame(i) && !IsFakeClient(i) && !g_indm[i])
                    {
                        clients[numClients++] = i;
                    }
                }
                return Plugin_Changed;
			}
			else
			{
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(IsClientInGame(i) && !IsFakeClient(i) && g_indm[i])
                    {
                        clients[numClients++] = i;
                    }
                }
                return Plugin_Changed;
			}
	}

	return Plugin_Continue
}

public Action Event_WeaponPlayed(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!(strncmp(sample, "weapons", 7) == 0 || strncmp(sample[1], "weapons", 7) == 0))
		return Plugin_Continue;

	int i, j;

	for (i = 0; i < numClients; i++)
	{
		if (g_indm[entity] != g_indm[clients[i]])
		{
			for (j = i; j < numClients-1; j++)
			{
				clients[j] = clients[j+1];
			}

			numClients--;
			i--;
		}
	}

	return (numClients > 0) ? Plugin_Changed : Plugin_Handled;
}

public Action WeaponSoundHook(const char[] te_name, int[] Players, int numClients, float delay)
{
	int[] newClients = new int[MaxClients];
	int client;
	int newTotal = 0;
	int user = TE_ReadNum("m_iPlayer") + 1;

	for (int i = 0; i < numClients; i++)
	{
		client = Players[i];
		if(client == user)
			continue;

		if (!g_indm[client] && !g_indm[user])
		{
			newClients[newTotal++] = client;
		}
		else if(g_indm[client] &&  g_indm[user])
		{
			newClients[newTotal++] = client;
		}
	}


	if (newTotal == numClients)
		return Plugin_Continue;


	else if (newTotal == 0)
		return Plugin_Handled;

	float vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);

	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}