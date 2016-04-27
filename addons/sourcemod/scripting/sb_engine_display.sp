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

#define STRING(%1) %1, sizeof(%1)

/*
enum TFClassType
{
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
};*/

char ClassList[][] =
{
	"Scout", //1
	"Sniper", //2
	"Soldier", //3
	"Demoman", //4
	"Medic", //5
	"Heavy", //6
	"Pyro", //7
	"Spy", //8
	"Engineer" //9
};

TFClassType PlayerNextClass[MAXPLAYERSCUSTOM];

Handle sb_lives;
Handle sb_chatmsg;
Handle sb_chatmsg_balance;

Handle CountDownTimerMessage;
Handle TargetDamageMessage;
Handle YourDamageMessage;
Handle YourLivesMessage;

bool g_spec[MAXPLAYERS+1] = {true, ...};

bool displayedHelp[MAXPLAYERSCUSTOM];

bool NewMap = true;

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
	sb_chatmsg = CreateConVar("sb_chatmsg", "0", "Enable chat messages of team scores in chat.", FCVAR_PLUGIN);
	sb_chatmsg_balance = CreateConVar("sb_chatmsg_balance", "1", "Enable showing player balance information of lives during beginning of round.", FCVAR_PLUGIN);

	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_win", teamplay_round_win);
	//HookEvent("teamplay_waiting_begins", teamplay_round_start);

	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("arena_round_start", teamplay_round_active);

	RegAdminCmd("sm_lives", Command_Lives, ADMFLAG_BAN, "sm_lives");

	AddCommandListener(Command_InterceptSpectate, "spectate");
	//AddCommandListener(Command_InterceptJoinTeam, "jointeam");

	RegConsoleCmd("sm_sbclass",Command_ChangeClass);
	RegConsoleCmd("sm_scout",Command_ChangeClassScout);
	RegConsoleCmd("sm_sniper",Command_ChangeClassSniper);
	RegConsoleCmd("sm_soldier",Command_ChangeClassSoldier);
	RegConsoleCmd("sm_demoman",Command_ChangeClassDemo);
	RegConsoleCmd("sm_demo",Command_ChangeClassDemo);
	RegConsoleCmd("sm_medic",Command_ChangeClassMedic);
	RegConsoleCmd("sm_heavy",Command_ChangeClassHeavy);
	RegConsoleCmd("sm_pyro",Command_ChangeClassPyro);
	RegConsoleCmd("sm_spy",Command_ChangeClassSpy);
	RegConsoleCmd("sm_engineer",Command_ChangeClassEngi);
	RegConsoleCmd("sm_engi",Command_ChangeClassEngi);


	RegConsoleCmd("jointeam", Command_jointeam);
	HookEvent("player_team", Event_player_team);

	CreateTimer(0.1,DisplayInformation,_,TIMER_REPEAT);
	//CreateTimer(1.0,DisplayInformation2,_,TIMER_REPEAT);
}

public OnMapStart()
{
	NewMap=true;
}

stock bool SpreadLives(int teamToGetLives, int GiveLives, int iClient=0)
{
	//PrintToChatAllPrintToChatAll("SpreadLives");
	if(teamToGetLives <=0 || teamToGetLives > 3)
	{
		//PrintToChatAll("invalid teamToGetLives");
		return false;
	}
	if(iClient>0 && !SB_ValidPlayer(iClient,true))
	{
		//PrintToChatAll("iClient is not valid, returning false");
		return false;
	}

	if(GiveLives <= 0)
	{
		//PrintToChatAll("GiveLives <= 0");
		return false;
	}
	if(SB_CountTeams(teamToGetLives)<1) return false;
	//PrintToChatAll("SB_CountTeams(teamToGetLives)>=1");

	// Randomly spread the love
	bool TargetGotExtraLiveAlready[MAXPLAYERSCUSTOM];

	int SpreadSuccess = 0;

	bool B_sb_chatmsg_balance = GetConVarBool(sb_chatmsg_balance);

	int retry = 2;

	float ChanceFloat = 0.60;

	int LivePlayerCount = 0;
	int LivePlayers[MAXPLAYERSCUSTOM];
	int LivePlayersTeam[MAXPLAYERSCUSTOM];
	//PrintToChatAll("LoopAlivePlayers before");
	LoopAlivePlayers(target)
	{
		if(SB_GetPlayerProp(target,iStartingTeam)<=1)
		{
			//PrintToChatAll("SB_GetPlayerProp(target,iStartingTeam) %d",SB_GetPlayerProp(target,iStartingTeam));
			continue;
		}
		LivePlayers[LivePlayerCount]=target;
		LivePlayersTeam[LivePlayerCount]=SB_GetPlayerProp(target,iStartingTeam);
		LivePlayerCount++;
		//PrintToChatAll("LivePlayerCount %d",LivePlayerCount);
	}
	//PrintToChatAll("LoopAlivePlayers after");

	if(LivePlayerCount<=1)
	{
		//PrintToChatAll("LivePlayerCount<=1");
		return false;
	}
	else
	{
		//PrintToChatAll("LivePlayerCount>1");
	}


	char sClientName[32];
	//PrintToChatAll("char sClientName[32];");
	int target = 0;
	//PrintToChatAll("target = 0");
	int OldGiveLives = GiveLives;
	//PrintToChatAll("OldGiveLives = GiveLives which is %d", OldGiveLives);
	//for(int igive=1;igive<=GiveLives;++igive)
	while(GiveLives > 0)
	{
		//PrintToChatAll("GiveLives:%d",GiveLives);
		ChanceFloat = 0.60;
		for(new i=0;i<=LivePlayerCount;++i)
		{
			//PrintToChatAll("i %d",i);
			target=LivePlayers[i];
			if(!SB_ValidPlayer(target,true))
			{
				//PrintToChatAll("i %d not valid player",i);
				continue;
			}
			//PrintToChatAll("target %d",target);

			if(target==iClient) continue;
			// try not to use same person twice
			if(TargetGotExtraLiveAlready[target] && retry>0)
			{
				//PrintToChatAll("retry %d",retry);
				retry--;
				continue;
			}
			if(LivePlayersTeam[i]!=teamToGetLives) continue;
			if(GetRandomFloat(0.0,1.0)<=ChanceFloat)
			{
				//PrintToChatAll("GetRandomFloat success");
				TargetGotExtraLiveAlready[target]=true;
				if(teamToGetLives==2)
				{
					//PrintToChatAll("teamToGetLives==2");
					SB_SetPlayerProp(target,iLives,(SB_GetPlayerProp(target,iLives)+1));
					if(B_sb_chatmsg_balance)
					{
						GetClientName(target,STRING(sClientName));
						SB_ChatMessage(0,"{yellow}To help balance the game, {red}%s on red team {yellow}now has {green}%d {yellow}lives!",sClientName,SB_GetPlayerProp(target,iLives));
					}
					SpreadSuccess++;
					GiveLives--;
					break;
				}
				else if(teamToGetLives==3)
				{
					//PrintToChatAll("teamToGetLives==3");
					SB_SetPlayerProp(target,iLives,(SB_GetPlayerProp(target,iLives)+1));
					if(B_sb_chatmsg_balance)
					{
						GetClientName(target,STRING(sClientName));
						SB_ChatMessage(0,"{yellow}To help balance the game, {blue}%s on blue team {yellow}now has {green}%d {yellow}lives!",sClientName,SB_GetPlayerProp(target,iLives));
					}
					SpreadSuccess++;
					GiveLives--;
					break;
				}
			}
			else
			{
				//PrintToChatAll("GetRandomFloat fail");
				ChanceFloat += 0.05;
				if(ChanceFloat>1.0) ChanceFloat = 1.0;
			}
		}
	}

	//PrintToChatAll("after while");

	if(OldGiveLives - SpreadSuccess == 0)
	{
		return true;
	}
	else
	{
		//PrintToChatAll("SpreadLives failed!");
		return false;
	}
}
/*
public Action Command_InterceptJoinTeam(int client, char[] command, int args)
{
	if(!SB_ValidPlayer(client,true) || !SB_GetGamePlaying())
	{
		return Plugin_Continue;
	}

	if(SB_GetGamePlaying())
	{
		int CurrentLives = SB_GetPlayerProp(client,iLives);
		char sClientName[32];
		GetClientName(client,STRING(sClientName));
		SB_ChatMessage(0,"{yellow}%s is switching teams!",sClientName);
		if(SpreadLives(GetClientTeam(client), CurrentLives, client))
		{
			SB_ChatMessage(client,"{yellow}Gived away your lives, please wait while we give you the team menu!");
		}
		CreateTimer(1.5, Force_Jointeam, client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

#define PANEL_TEAM "team"
public Action:Force_Jointeam(Handle:timer, any:client)
{
	// Make sure client is still in game and didn't rage quit
	if(IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, 1);
		ShowVGUIPanel(client, PANEL_TEAM);
	}
}*/

public Action Command_InterceptSpectate(int client, char[] command, int args)
{
	if(!SB_ValidPlayer(client,true) || !SB_GetGamePlaying())
	{
		return Plugin_Continue;
	}

	if(!SB_GetPlayerProp(client,SpawnedOnce))
	{
		return Plugin_Continue;
	}

	if(SB_GetGamePlaying())
	{
		int CurrentLives = SB_GetPlayerProp(client,iLives);
		char sClientName[32];
		GetClientName(client,STRING(sClientName));
		SB_ChatMessage(0,"{yellow}%s is going spectate!",sClientName);
		if(SpreadLives(GetClientTeam(client), CurrentLives, client))
		{
			SB_ChatMessage(client,"{yellow}Gave away your lives, please wait while prepare you for spectate!");
		}
		CreateTimer(1.5,SendToSpectate,client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action SendToSpectate(Handle timer, any client)
{
	if(SB_ValidPlayer(client) && GetClientTeam(client)>1)
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, 1);
		//int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
		//SB_SetPlayerProp(client,iLives,MaxLives);
	}
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
	PlayerNextClass[client]=TFClass_Unknown;
}

bool ClientDisconnectDisconnected[MAXPLAYERSCUSTOM];
int ClientDisconnectLives[MAXPLAYERSCUSTOM];
int ClientDisconnectTeam[MAXPLAYERSCUSTOM];

public void OnClientDisconnect(int client)
{
	//PrintToChatAll("OnClientDisconnect");
	g_spec[client] = true;

	ClientDisconnectDisconnected[client]=true;
	ClientDisconnectLives[client] = SB_GetPlayerProp(client,iLives);
	ClientDisconnectTeam[client] = SB_GetPlayerProp(client,iStartingTeam);

	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
}
public void OnClientDisconnect_Post(int client)
{
	//PrintToChatAll("OnClientDisconnect_Post");
	if(SB_GetGamePlaying())
	{
		if(ClientDisconnectDisconnected[client])
		{
			ClientDisconnectDisconnected[client]=false;
			SpreadLives(ClientDisconnectTeam[client], ClientDisconnectLives[client]);
		}
	}
	ClientDisconnectDisconnected[client] = false;
	ClientDisconnectTeam[client] = 0;
	ClientDisconnectLives[client] = 0;

	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
}

public OnClientPutInServer(client){
	int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
	SB_SetPlayerProp(client,iLives,MaxLives);
	PlayerNextClass[client]=TFClass_Unknown;
	SB_SetPlayerProp(client,iStartingTeam,0);
	displayedHelp[client]=false;
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
		SB_SetPlayerProp(i,iStartingTeam,0);
	}
	/*
	int rand = GetRandomInt(2, 3);
	for(int i=1;i<=MaxClients;i++)
	{
		//if(!g_spec[i] && SB_ValidPlayer(i) && !IsFakeClient(i) && !(GetClientTeam(i)==1))
		if(SB_ValidPlayer(i))
		{
			int cred = SB_CountTeams(2);
			int cblue = SB_CountTeams(3);
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
			} else if(SB_CountTeams(1)>0) {
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
	//int rand = GetRandomInt(2, 3);
	for(int i=1;i<=MaxClients;i++)
	{
		//if(!g_spec[i] && SB_ValidPlayer(i) && !IsFakeClient(i) && !(GetClientTeam(i)==1))
		if(SB_ValidPlayer(i))
		{
			// dont change GetTeamClientCount() to new method as it is required to balance everyone!
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
			else if(SB_CountTeams(1)>0) {
				rand = GetRandomInt(2, 3);
				ChangeClientTeam(i, rand);
			}
			else
			{
				rand = GetRandomInt(2, 3);
				ChangeClientTeam(i, rand);
			}*/

			SB_SetPlayerProp(i,iStartingTeam,GetClientTeam(i));
		}
		//TF2_RespawnPlayer(i);
	}

	return Plugin_Continue;
}

public Action teamplay_round_active(Handle event,  char[] name, bool dontBroadcast)
{
	//PrintToChatAll("%s",name);
	if(NewMap)
	{
		for(int i=1;i<=MaxClients;++i){
			LastPersonAttacked[i]=-1;
			SB_SetPlayerProp(i,iLives,1);
		}

		NewMap = false;
		SB_ChatMessage(0,"First Round of the Map {yellow}[{red}SUDDEN DEATH{yellow}]");
		return Plugin_Continue;
	}
	TeamBalanceTimer();
	return Plugin_Continue;
}


public void TeamBalanceTimer()
{
	//PrintToChatAll("Debug: Start of Balancing");

	int redteamcount = SB_CountTeams(2);
	int blueteamcount = SB_CountTeams(3);

	SB_ChatMessage(0,"Red Team Count %d / Blue Team Count %d",redteamcount,blueteamcount);

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
	if(GetConVarBool(sb_chatmsg) && teamToBalance == 0)
	{
		int RedTeam, BlueTeam;
		CalculateTeamScores(RedTeam,BlueTeam);

		SB_ChatMessage(0,"{default}[{yellow}[ROUND START]{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",RedTeam,BlueTeam);
		return;
	}

	// Randomly spread the love
	if(teambalance != 0)
	{
		SpreadLives(teamToBalance, teambalance);
	}

	if(GetConVarBool(sb_chatmsg))
	{
		int RedTeam, BlueTeam;
		CalculateTeamScores(RedTeam,BlueTeam);

		SB_ChatMessage(0,"{default}[{yellow}[ROUND START]{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",RedTeam,BlueTeam);
	}

	// Keep here just incase SpreadLives doesn't work right:
	/*

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
	//PrintToChatAll("Debug: End of Balancing");*/

	return;
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


stock void SendDialogToOne(client, String:text[], any:...)
{
	char message[100];
	VFormat(message, sizeof(message), text, 3);

	Handle kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", 255, 255, 255, 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 1000);

	CreateDialog(client, kv, DialogType_Msg);

	CloseHandle(kv);
}
/*
public Action:DisplayInformation2(Handle:timer,any:userid)
{
	int RedTeam, BlueTeam;
	CalculateTeamScores(RedTeam,BlueTeam);

	for(new client=1;client<=MaxClients;client++)
	{
		if(SB_ValidPlayer(client))
		{
			SendDialogToOne(client, "Red Team %d Blue Team %d", teamred, teamblue);
		}
	}
}*/

public Action:DisplayInformation(Handle:timer,any:userid)
{
	int RedTeam, BlueTeam;
	CalculateTeamScores(RedTeam,BlueTeam);

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
				ShowSyncHudText(client, YourLivesMessage, "Lives %d\nRed %d - Blue %d",SB_GetPlayerProp(client,iLives),RedTeam,BlueTeam);

				//new target=SB_GetTargetInViewCone(client,10000.0,true, 13.0);
				if(TF2_GetPlayerClass(client) != TFClass_Medic)
				{
					int target = LastPersonAttacked[client];
					if(SB_ValidPlayer(target))
					{
						SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "Enemy: %d%%\nLives: %d",SB_GetPlayerProp(target,iDamage),SB_GetPlayerProp(target,iLives));
					}
				}
				else
				{
					int target = TF2_GetHealingTarget(client);
					if(SB_ValidPlayer(target))
					{
						SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "Healing: %d%%\nLives: %d",SB_GetPlayerProp(target,iDamage),SB_GetPlayerProp(target,iLives));
					}
					else
					{
						target = LastPersonAttacked[client];
						if(SB_ValidPlayer(target))
						{
							SetHudTextParams(0.67, 0.60, 0.11, 255, 255, 255, 255);
							ShowSyncHudText(client, TargetDamageMessage, "Enemy: %d%%\nLives: %d",SB_GetPlayerProp(target,iDamage),SB_GetPlayerProp(target,iLives));
						}
					}

				}
			}
			else
			{
				SetHudTextParams(-1.0, 0.88, 0.11, 255, 255, 255, 255);
				ShowSyncHudText(client, YourLivesMessage, "Red %d - Blue %d",RedTeam,BlueTeam);

				int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(!SB_ValidPlayer(target))
				{
					target=SB_GetTargetInViewCone(client,10000.0,true, 13.0);
				}
				if(SB_ValidPlayer(target))
				{
					char PlayerName[256];
					GetClientName(target,PlayerName,sizeof(PlayerName));

					int TargetOfTarget = SB_GetTargetInViewCone(target,10000.0,true, 13.0);
					if(SB_ValidPlayer(TargetOfTarget,true))
					{
						char TargetOfTargetName[256];
						GetClientName(TargetOfTarget,TargetOfTargetName,sizeof(TargetOfTargetName));

						SetHudTextParams(0.67, 0.80, 0.11, 255, 255, 255, 255);
						ShowSyncHudText(client, TargetDamageMessage, "%s: %d%%\nLives: %d",TargetOfTargetName,SB_GetPlayerProp(TargetOfTarget,iDamage),SB_GetPlayerProp(TargetOfTarget,iLives));
					}
					SetHudTextParams(0.27, 0.80, 0.11, 255, 255, 255, 255);
					ShowSyncHudText(client, YourDamageMessage, "%s: %d%%\nLives: %d",PlayerName,SB_GetPlayerProp(target,iDamage),SB_GetPlayerProp(target,iLives));
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
		SB_SetPlayerProp(victim,iStartingTeam,0);
	}

	if(!SB_GetGamePlaying())
		return;

	if(!GetConVarBool(sb_chatmsg))
		return;

	int teamred, teamblue;
	CalculateTeamScores(teamred,teamblue);

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


public Action Command_ChangeClass(int client, int args)
{
	//PrintToChatAll("Command_ChangeClass");
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	ChangeClass(client);

	return Plugin_Handled;
}

/*
char ClassList[][] =
{
	"Scout", //1
	"Sniper", //2
	"Soldier", //3
	"Demoman", //4
	"Medic", //5
	"Heavy", //6
	"Pyro", //7
	"Spy", //8
	"Engineer" //9
};*/

public Action Command_ChangeClassScout(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 1;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSniper(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 2;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSoldier(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 3;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassDemo(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 4;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassMedic(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 5;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassHeavy(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 6;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassPyro(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 7;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSpy(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 8;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassEngi(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 9;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}

stock ChangeClass(int client)
{
//	PrintToChatAll("ChangeClass");

	Handle hMenu = CreateMenu(MenuHandle_PickClass_Menu);
	SetMenuExitBackButton(hMenu, false);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuTitle(hMenu,"Pick New Class:");

	char Buffer[64];

	char IntToStr[8];
	for(int i=1; i<=9; i++)
	{
		//int myint = view_as<int>(TF2_GetPlayerClass(client));
		//if(myint==i) continue;

		IntToString(i, STRING(IntToStr));
		Format(STRING(Buffer), "%s", ClassList[i-1]);
		AddMenuItem(hMenu,IntToStr,Buffer,ITEMDRAW_DEFAULT);

		//PrintToChatAll("i %d, IntToStr %s, ClassList %s",i,IntToStr,ClassList[i-1]);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	//PrintToChatAll("DisplayMenu");
}
public MenuHandle_PickClass_Menu(Handle:hMenu, MenuAction:action, param1, selection)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			//MenuAction_Cancel
			//PrintToChatAll("MenuAction_Cancel");
		}
		case MenuAction_Select:
		{
			//PrintToChatAll("MenuAction_Select");
			char SelectionInfo[8];
			char SelectionDispText[2048];

			int SelectionStyle;
			GetMenuItem(hMenu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

			int itemnumber=StringToInt(SelectionInfo);

			int client=param1;

			if(SB_ValidPlayer(client))
			{
				PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
				SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
			}
		}
		case MenuAction_End:
		{
			//PrintToChatAll("MenuAction_End");
			CloseHandle(hMenu);
		}
	}
}

public void OnSB_EventSpawn_Post(client)
{
	if(!displayedHelp[client])
	{
		displayedHelp[client]=true;
		StartingHelpMenu(client);
	}
}

public OnSB_SpawnPlayer(int client)
{
	if(SB_ValidPlayer(client) && PlayerNextClass[client]!=TFClass_Unknown)
	{
		TF2_RemoveCondition(client, TFCond:44);

		//int oldAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
		//int oldAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);

		int oldFlags = GetEntityFlags(client);
		SetEntityFlags(client, oldFlags & ~FL_NOTARGET);	// Remove notarget if it was there
															// for whatever reason, weapons won't be
															// regenerated if FL_NOTARGET is set.

		//int oldHealth = GetClientHealth(client);
		TF2_RegeneratePlayer(client);

		// now get the maxs, since the current ammo = max
		//int oldMaxAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
		//int oldMaxAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);


		TF2_SetPlayerClass(client, PlayerNextClass[client], false, true);

		SetEntityHealth(client, 1);
		TF2_RegeneratePlayer(client);

		//int newMaxAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
		//int newMaxAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);

		//int scaled1 = RoundFloat(oldMaxAmmo1 == oldAmmo1 ? float(newMaxAmmo1) :
			//float(oldAmmo1) * (float(newMaxAmmo1) / float(oldMaxAmmo1)));

		//int scaled2 = RoundFloat(oldMaxAmmo2 == oldAmmo2 ? float(newMaxAmmo2) :
			//float(oldAmmo2) * (float(newMaxAmmo2) / float(oldMaxAmmo2)));

		//int ws1 = GetPlayerWeaponSlot(client, 0);
		//int ws2 = GetPlayerWeaponSlot(client, 1);
		//int clipMain = -1, clip2nd = -1;
		//if (ws1 > 0)
			//clipMain = GetEntData(ws1, FindSendPropInfo("CTFWeaponBase", "m_iClip1"));
		//if (ws2 > 0)
			//clip2nd = GetEntData(ws2, FindSendPropInfo("CTFWeaponBase", "m_iClip1"));

		// Do not Permit new clip (you get ammo from nothing)
		// Setting to 0 bugs certain weapons
		//if (clipMain > -1)
			//SetEntData(ws1, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 1);
		//if (clip2nd > -1)
			//SetEntData(ws2, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 1);

		//SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4,
			//scaled1);
		//SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8,
			//scaled2);

		// Engies shouldn't get ammo
		//if (PlayerNextClass[client] == TFClass_Engineer)
			//SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 12, 0, 4);

		//SetEntityHealth(client,oldHealth);

		//int slot;
		//if ((slot = GetPlayerWeaponSlot(client, 0)) > -1)
			//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", slot);


		CreateTimer(1.0, Remove_Cond_44, GetClientUserId(client));
		PlayerNextClass[client]=TFClass_Unknown;

		SB_ApplyWeapons(client);
	}
}


// force removal of heavy crits
public Action:Remove_Cond_44(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(SB_ValidPlayer(client) && TF2_IsPlayerInCondition(client, TFCond:44))
	{
		TF2_RemoveCondition(client, TFCond:44);
	}
}

stock StartingHelpMenu(int client)
{
	Handle hMenu = CreateMenu(MenuHandle_Help_Menu);
	SetMenuExitBackButton(hMenu, false);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuTitle(hMenu,"Super Smash Bros!");

	AddMenuItem(hMenu,"1","Type !sbclass in chat to pick your next class on spawn.",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"2","Also try !scout, !sniper, !soldier, !demo, !medic, !heavy, !pyro, !spy, !engi",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"3","Your Loadout is changed for the balance of this MOD!",ITEMDRAW_DEFAULT);

	DisplayMenu(hMenu, client, 30);
}
public MenuHandle_Help_Menu(Handle:hMenu, MenuAction:action, param1, selection)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			//MenuAction_Cancel
			//PrintToChatAll("MenuAction_Cancel");
		}
		case MenuAction_Select:
		{
			//PrintToChatAll("MenuAction_Select");
			char SelectionInfo[8];
			char SelectionDispText[2048];

			int SelectionStyle;
			GetMenuItem(hMenu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

			//int itemnumber=StringToInt(SelectionInfo);
			//int client=param1;
		}
		case MenuAction_End:
		{
			//PrintToChatAll("MenuAction_End");
			CloseHandle(hMenu);
		}
	}
}
