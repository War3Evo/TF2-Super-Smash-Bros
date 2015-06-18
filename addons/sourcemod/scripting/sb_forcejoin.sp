
//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

// Not compatible with CSS ATM
// Make sure the Game is set right in switchgamemode.inc in ../includes/switchgamemode.inc

#tryinclude <DiabloStocks>

#if !defined _diablostocks_included
stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}
#endif

#define PLUGIN_VERSION "1.00"

#define TEAM_BLUE 3
#define TEAM_RED 2

public Plugin:myinfo = {
	name = "Force Join",
	author = "El Diablo",
	description = "Forces clients to join a specific team",
	version = PLUGIN_VERSION,
};

//new ChooseTeam[MAXPLAYERSCUSTOM];

//public OnPluginStart() {
	// Hook jointeam command
	//RegConsoleCmd("jointeam", OnJoinTeam);
//}

//public Action:OnJoinTeam(client, args)
//{
	//if(ValidPlayer(client) && ChooseTeam[client]>0)
	//{
		//ChangeClientTeam(client, ChooseTeam[client]);
		//ChooseTeam[client]=0;
	//}
	//return Plugin_Handled;
//}

public OnClientPutInServer(client)
{
	//if (IsMvM(true))
	//{
		//ClientCommand(client,"sm_mvmred");
	//} else {
	new blueteam=0;
	new redteam=0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && !IsFakeClient(i))
		{
			if(GetClientTeam(i)==TEAM_BLUE)
			{
				blueteam++;
			}
			else if(GetClientTeam(i)==TEAM_RED)
			{
				redteam++;
			}
		}
	}

	if(redteam>blueteam)
	{
		ChangeClientTeam(client, TEAM_BLUE);
	}
	else if(redteam<blueteam)
	{
		ChangeClientTeam(client, TEAM_RED);
	}
	else
	{
		new iTeam=GetRandomInt(2, 3);
		if(iTeam==2)
		{
			ChangeClientTeam(client, TEAM_RED);
		}
		else
		{
			ChangeClientTeam(client, TEAM_BLUE);
		}
	}
		//CreateTimer(1.0,Timer_UpdateInfo,GetClientUserId(client));

		//Open class selection
	CreateTimer(1.0, ClassSelection, client, TIMER_FLAG_NO_MAPCHANGE);
	//}
}

public Action:ClassSelection(Handle:timer, any:client) {
	if(IsClientInGame(client)) {
			ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
		} else {
			PrintToChat(client, "Please open the class selection screen and select the class you wish to play!");
		}
}

//public Action:Timer_UpdateInfo(Handle:timer,any:userid)
//{
	//new client=GetClientOfUserId(userid);
	//if(ValidPlayer(client))
	//{
		//ChangeClientTeam(client, ChooseTeam[client]);
	//}
//}
