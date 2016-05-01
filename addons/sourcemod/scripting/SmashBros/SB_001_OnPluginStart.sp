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

	SB_001_HookEvent_OnPluginStart();

	SB_Engine_Updater_OnPluginStart();

	SB_Engine_DamageSystem_OnPluginStart();

	SB_Engine_Display_OnPluginStart();

	SB_Engine_Weapon_Manager_OnPluginStart();

	SB_001_RegConsoleCmd_OnPluginStart();
}
