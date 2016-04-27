//SB_001_AddCommandListener.sp

public OnPluginStart_SB_001_AddCommandListener()
{
	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");
}

public Action Command_InterceptSuicide(int client, char[] command, int args)
{
	if(!SB_ValidPlayer(client,true) || !SB_GetGamePlaying())
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
