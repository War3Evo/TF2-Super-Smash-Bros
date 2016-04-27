//SB_001_OnPluginStart.sp

public OnPluginStart()
{
	OnPluginStart_SB_001_CreateConVar();
	OnPluginStart_SB_001_CreateTimer();

	Handle hGameConf=INVALID_HANDLE;
	hGameConf=LoadGameConfigFile("sm-tf2.games");
	if(hGameConf)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"ForceRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else
	{
		PrintToServer("[SmashBros] Error, could not find configuration file for game.");
	}

	int playerresource = -1;
	iTotalScoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");
	if (iTotalScoreOffset != -1)
	{
		playerresource = FindEntityByClassname(playerresource, "tf_player_manager");
		if (playerresource != INVALID_ENT_REFERENCE)
		{
			SB_001_SDKHook_OnPluginStart(playerresource);
		}
	}


	SB_001_HookEvent_OnPluginStart();

	SB_Engine_Updater_OnPluginStart();
}
