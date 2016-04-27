//SB_Engine_InitNatives.sp


//=============================================================================
// SB_InitNatives
//=============================================================================
public bool SB_Engine_InitNatives()
{
	CreateNative("SB_GetCountDownTimer",Native_SB_GetCountDownTimer);

	CreateNative("SB_GetGamePlaying",Native_SB_GetGamePlaying);

	CreateNative("SB_SetPlayerProp",NSB_SetPlayerProp);
	CreateNative("SB_GetPlayerProp",NSB_GetPlayerProp);

	CreateNative("SB_SpawnPlayer",NSB_SpawnPlayer);

	SB_Engine_DamageSystem_SB_Engine_InitNatives();

	return true;
}


public Native_SB_GetGamePlaying(Handle:plugin,numParams)
{
	return playing;
}

public Native_SB_GetCountDownTimer(Handle:plugin,numParams)
{
	return CountDownTimer;
}

public NSB_GetPlayerProp(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		return p_properties[client][SBPlayerProp:GetNativeCell(2)];
	}
	else
		return 0;
}
public NSB_SetPlayerProp(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		p_properties[client][SBPlayerProp:GetNativeCell(2)]=GetNativeCell(3);
	}
}

public NSB_SpawnPlayer(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (SB_ValidPlayer(client))
	{
		SDKCall(hSpawnPlayer,client);

		SB_Engine_Internal_OnSB_SpawnPlayer();

		Call_StartForward(FHOnSB_SpawnPlayer);
		Call_PushCell(client);
		Call_Finish();
		return 1;
	}
	else
		return 0;
}
