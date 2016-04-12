/*
 * =============================================================================
 * Smash Bros Interface Includes File
 * Includes, stocks, natives, and other resources required by Smash Bros Plugins
 *
 * (C)2014 El Diablo of www.war3evo.info                       All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License , version 3.0, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#pragma semicolon 1

#include <sourcemod>
#include <sb_interface>
#include <sdkhooks>

#define LoopIngameClients(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1))

#define STRING(%1) %1, sizeof(%1)

Handle sb_lives;

Handle CountDownTimerMessage;
Handle TargetDamageMessage;
Handle YourDamageMessage;
Handle YourLivesMessage;

bool g_spec[MAXPLAYERS+1] = {true, ...};

//new Float:respawn[MAXPLAYERS+1];
int LastPersonAttacked[MAXPLAYERSCUSTOM];

//new bool:started=false;
//new bool:playing=false;

public Plugin:myinfo = {
	name = "Smash Bros Display Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}

public OnPluginStart()
{
	CountDownTimerMessage = CreateHudSynchronizer();
	TargetDamageMessage = CreateHudSynchronizer();
	YourDamageMessage = CreateHudSynchronizer();
	YourLivesMessage = CreateHudSynchronizer();

	sb_lives = CreateConVar("sb_lives", "3", "Amount of lives a player starts with.", FCVAR_PLUGIN);

	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_waiting_begins", teamplay_round_start);

	RegAdminCmd("sm_lives", Command_Lives, ADMFLAG_BAN, "sm_lives");


	RegConsoleCmd("jointeam", Command_jointeam);
	HookEvent("player_team", Event_player_team);

	CreateTimer(0.1,DisplayInformation,_,TIMER_REPEAT);
}
public OnAllPluginsLoaded()
{
	for(int i=1;i<MaxClients;i++)
	{
		int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
		SB_SetPlayerProp(i,iLives,MaxLives);
	}
}

public OnClientConnected(client){
	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
}

public OnClientDisconnected(client){
	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
}

public OnClientPutInServer(client){
	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
}


public Action:Command_Lives(client, args)
{
	for(int i=1;i<MaxClients;i++)
	{
		if(SB_ValidPlayer(i))
		{
			char sClientName[32];
			GetClientName(i,STRING(sClientName));
			PrintToConsole(client,"%s has %d lives.",sClientName,SB_GetPlayerProp(i,iLives));
		}
	}

}

public OnClientDisconnect(client) {
	g_spec[client] = true;
}
public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetEventInt(event, "team")>1) {
		g_spec[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
	}
}

public Action:Command_jointeam(client, args) {
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena")) {
		g_spec[client] = true;
	} else {
		g_spec[client] = false;
	}
}

public Action teamplay_round_win(Handle event,  const char[] name, bool dontBroadcast) {
	for(int i=1;i<=MaxClients;++i){
		LastPersonAttacked[i]=-1;
	}
	/*
	int rand = GetRandomInt(2, 3);
	for(int i=1;i<=MaxClients;i++)
	{
		//if(!g_spec[i] && SB_ValidPlayer(i) && !IsFakeClient(i) && !(GetClientTeam(i)==1))
		if(SB_ValidPlayer(i))
		{
			int cred = GetTeamClientCount(2);
			int cblue = GetTeamClientCount(3);
			if(cred>cblue) {
				if(GetClientTeam(i)!=3)
				{
					ChangeClientTeam(i, 3);
				}
			} else if(cblue>cred) {
				if(GetClientTeam(i)!=2)
				{
					ChangeClientTeam(i, 2);
				}
			} else if(GetTeamClientCount(1)>0) {
				rand = GetRandomInt(2, 3);
				ChangeClientTeam(i, rand);
			}
			//else
			//{
				//rand = GetRandomInt(2, 3);
				//ChangeClientTeam(i, rand);
			//}
		}
		//TF2_RespawnPlayer(i);
	}*/
}
/*
remove_entity_all(String:classname[])
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		PrintToChatAll("classname(%s) %i", classname, ent);
		AcceptEntityInput(ent, "Kill");
	}
}*/

public Action teamplay_round_start(Handle event,  const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("TEAMPLAY_ROUND_START");
	//remove_entity_all("trigger_hurt");
	int MaxLives = GetConVarInt(sb_lives);
	//PrintToChatAll("Max lives = %d",MaxLives);
	for(int i=1;i<=MaxClients;++i){
		LastPersonAttacked[i]=-1;
		SB_SetPlayerProp(i,iLives,MaxLives);
	}
	int rand = GetRandomInt(2, 3);
	for(int i=1;i<=MaxClients;i++)
	{
		//if(!g_spec[i] && SB_ValidPlayer(i) && !IsFakeClient(i) && !(GetClientTeam(i)==1))
		if(SB_ValidPlayer(i))
		{
			int cred = GetTeamClientCount(2);
			int cblue = GetTeamClientCount(3);
			if(cred>cblue) {
				if(GetClientTeam(i)!=3)
				{
					ChangeClientTeam(i, 3);
				}
			} else if(cblue>cred) {
				if(GetClientTeam(i)!=2)
				{
					ChangeClientTeam(i, 2);
				}
			}
			/*
			else if(GetTeamClientCount(1)>0) {
				rand = GetRandomInt(2, 3);
				ChangeClientTeam(i, rand);
			}
			else
			{
				rand = GetRandomInt(2, 3);
				ChangeClientTeam(i, rand);
			}*/
		}
		//TF2_RespawnPlayer(i);
	}

	// Created timer so that it doesn't hold up round_start
	CreateTimer(1.0,TeamBalanceTimer, _);

	return Plugin_Continue;
}

public Action:TeamBalanceTimer(Handle:timer,any:userid)
{
	//PrintToChatAll("Debug: Start of Balancing");

	int redteamcount = GetTeamClientCount(2);
	int blueteamcount = GetTeamClientCount(3);

	int ConVarLives = GetConVarInt(sb_lives);
	if(ConVarLives <=0) ConVarLives =1;
	//PrintToChatAll("Debug: sb_lives = %d",ConVarLives);
	//PrintToChatAll("Debug: redteamcount = %d",redteamcount);
	//PrintToChatAll("Debug: blueteamcount = %d",blueteamcount);
	int teambalance = 0;
	int teamToBalance = 0;
	if(redteamcount>blueteamcount)
	{
		teambalance = redteamcount-blueteamcount;
		teambalance *= ConVarLives;
		teamToBalance = 3;
	}
	else
	{
		teambalance = blueteamcount-redteamcount;
		teambalance *= ConVarLives;
		teamToBalance = 2;
	}
	//PrintToChatAll("Debug: teamToBalance = %d",teamToBalance);
	if(teamToBalance == 0) return Plugin_Continue;

	// Randomly spread the love
	bool TargetGotExtraLiveAlready[MAXPLAYERSCUSTOM];

	int retry = teambalance;

	char sClientName[32];
	while(teambalance > 0)
	{
		LoopIngameClients(target)
		{
			// try not to use same person twice
			if(TargetGotExtraLiveAlready[target] && retry>0)
			{
				retry--;
				continue;
			}
			if(GetClientTeam(target)!=teamToBalance) continue;
			if(GetRandomFloat(0.0,1.0)>=0.50)
			{
				TargetGotExtraLiveAlready[target]=true;
				SB_SetPlayerProp(target,iLives,(SB_GetPlayerProp(target,iLives)+1));
				GetClientName(target,STRING(sClientName));
				if(teamToBalance==2)
				{
					SB_ChatMessage(0,"{yellow}To help balance the game, {red}%s on red team {yellow}now has {green}%d {yellow}lives!",sClientName,SB_GetPlayerProp(target,iLives));
				}
				else
				{
					SB_ChatMessage(0,"{yellow}To help balance the game, {blue}%s on blue team {yellow}now has {green}%d {yellow}lives!",sClientName,SB_GetPlayerProp(target,iLives));
				}
				teambalance--;
			}
		}
	}
	//PrintToChatAll("Debug: End of Balancing");

	return Plugin_Continue;
}


sb_seconds(time) {
	return time % 86400 % 3600 % 60;
}
sb_minutes(time) {
	return RoundToFloor((time % 86400 % 3600) / 60.0);
}
//sb_hours(time) {
	//return RoundToFloor((time % 86400 )/3600.0);
//}
//sb_days(time) {
	//return RoundToFloor(time/86400.0);
//}

public OnSB_TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(SB_ValidPlayer(attacker))
	{
		LastPersonAttacked[attacker]=victim;
	}
}


public Action:DisplayInformation(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(SB_ValidPlayer(client))
		{
			// COUNT DOWN TIMER
			SetHudTextParams(-1.0, 0.85, 0.11, 255, 255, 255, 255);
			if(SB_GetGamePlaying())
			{
				new iTimer = SB_GetCountDownTimer() - GetTime();
				new Minutes = sb_minutes(iTimer);
				if(Minutes<0) Minutes = 0;
				new Seconds = sb_seconds(iTimer);
				if(Seconds<0) Seconds = 0;
				if(Seconds>9)
				{
					ShowSyncHudText(client, CountDownTimerMessage, "Time %d:%d",Minutes,Seconds);
				}
				else
				{
					ShowSyncHudText(client, CountDownTimerMessage, "Time %d:0%d",Minutes,Seconds);
				}
			}
			else
			{
				ShowSyncHudText(client, CountDownTimerMessage, "Time 0:0");
			}

			if(IsPlayerAlive(client))
			{
				SetHudTextParams(0.27, 0.60, 0.11, 255, 255, 255, 255);
				ShowSyncHudText(client, YourDamageMessage, "You: %d%%",SB_GetPlayerProp(client,iDamage));

				SetHudTextParams(-1.0, 0.88, 0.11, 255, 255, 255, 255);
				ShowSyncHudText(client, YourLivesMessage, "Lives %d",SB_GetPlayerProp(client,iLives));

				//new target=SB_GetTargetInViewCone(client,10000.0,true, 13.0);
				if(TF2_GetPlayerClass(client) != TFClass_Medic)
				{
					int target = LastPersonAttacked[client];
					if(SB_ValidPlayer(target))
					{
						SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "Enemy: %d%%",SB_GetPlayerProp(target,iDamage));
					}
				}
				else
				{
					int target = TF2_GetHealingTarget(client);
					if(SB_ValidPlayer(target))
					{
						SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "Healing: %d%%",SB_GetPlayerProp(target,iDamage));
					}
					else
					{
						target = LastPersonAttacked[client];
						if(SB_ValidPlayer(target))
						{
							SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
							ShowSyncHudText(client, TargetDamageMessage, "Enemy: %d%%",SB_GetPlayerProp(target,iDamage));
						}
					}

				}
			}
			else
			{
				new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(!SB_ValidPlayer(target))
				{
					target=SB_GetTargetInViewCone(client,10000.0,true, 13.0);
				}
				if(SB_ValidPlayer(target))
				{
					new String:PlayerName[256];
					GetClientName(target,PlayerName,sizeof(PlayerName));

					new TargetOfTarget = SB_GetTargetInViewCone(target,10000.0,true, 13.0);
					if(SB_ValidPlayer(TargetOfTarget))
					{
						SetHudTextParams(0.67, 0.80, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "Enemy: %d%%",PlayerName,SB_GetPlayerProp(TargetOfTarget,iDamage));
					}
					SetHudTextParams(0.27, 0.80, 0.11, 255, 255, 255, 255);
					ShowSyncHudText(client, YourDamageMessage, "%s: %d%%",PlayerName,SB_GetPlayerProp(target,iDamage));
				}
			}

			//new target=GetClientAimTarget(client,true)
			//new target=SB_GetTargetInViewCone(client,10000.0,true, 13.0);
			//GetClientTeam(client)!=GetClientTeam(target) ???
			//if(SB_ValidPlayer(target))
			//{
				//SetHudTextParams(0.20, 0.80, 0.11, 255, 255, 255, 255);

				//ShowSyncHudText(client, TargetDamageMessage, "Target: %d%%",SB_GetPlayerProp(target,iDamage));
			//}

/*
			if(WatchPlayer[client]>0 && WatchPlayerTicks[client]>=10 && SB_ValidPlayer(WatchPlayer[client],true))
			{
				WatchPlayerTicks[client]=0;
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", WatchPlayer[client]);
				SetEntProp(client, Prop_Send, "m_iFOV", 0);
			}
			WatchPlayerTicks[client]++;
			if(WatchPlayerTicks[client]>10)
			{
				WatchPlayerTicks[client]=10;
			}
*/
		}
	}
}

public void OnSB_EventDeath(int victim, int attacker, int assister, int distance, int attacker_hpleft, Handle event)
{
	/*
	if(SB_ValidPlayer(victim))
	{
		if(SB_GetPlayerProp(victim,iLives)>0)
		{
			SB_SetPlayerProp(victim,iLives,SB_GetPlayerProp(victim,iLives)-1);
			SDKCall(hSpawnPlayer,victim);
		}
	}
	*/
	if(GetEventBool(event, "sourcemod"))
		return;

	if(victim)
	{
		//SB_SetPlayerProp(victim,iLives,0);
		int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
		SB_SetPlayerProp(victim,iLives,MaxLives);
	}

	if(!SB_GetGamePlaying())
		return;

	int teamred=0;
	int teamblue=0;

	int TheLives = 0;

	for(int i=1;i<MaxClients;i++)
	{
		if(SB_ValidPlayer(i,true))
		{
			TheLives = SB_GetPlayerProp(i,iLives);
			if(TheLives>0)
			{
				if(GetClientTeam(i)==TEAM_RED)
				{
					teamred+=TheLives;
				}
				else if(GetClientTeam(i)==TEAM_BLUE)
				{
					teamblue+=TheLives;
				}
			}
		}
	}

	SB_ChatMessage(0,"{default}[{yellow}Total Lives{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
/*
	new iWinningTeam = 0;

	if(teamred>teamblue)
	{
		iWinningTeam=TEAM_RED;
	}
	else if(teamred<teamblue)
	{
		iWinningTeam=TEAM_BLUE;
	}*/
}
