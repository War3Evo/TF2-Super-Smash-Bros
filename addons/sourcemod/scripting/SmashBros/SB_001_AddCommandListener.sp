//SB_001_AddCommandListener.sp

public OnPluginStart_SB_001_AddCommandListener()
{
	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");
	AddCommandListener(Command_InterceptSpectate, "spectate");
}

public Action Command_InterceptSuicide(int client, char[] command, int args)
{
	if(!g_sb_enabled || !SB_ValidPlayer(client,true) || !playing)
	{
		return Plugin_Continue;
	}

	// Player used "kill" or "explode"

	// Suicide attempt was intercepted
	if(FakeDeath(client,client))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


public Action Command_InterceptSpectate(int client, char[] command, int args)
{
	if(!g_sb_enabled || !SB_ValidPlayer(client,true) || !playing)
	{
		return Plugin_Continue;
	}

	if(!GetPlayerProp(client,SpawnedOnce))
	{
		return Plugin_Continue;
	}

	if(playing)
	{
		int CurrentLives = GetPlayerProp(client,iLives);
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
		//SetPlayerProp(client,iLives,MaxLives);
	}
}
