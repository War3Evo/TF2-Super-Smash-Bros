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

	SB_Engine_Weapon_Manager_SB_Engine_InitNatives();

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

public any GetPlayerProp(int client, SBPlayerProp Property)
{
	if (client > 0 && client <= MaxClients)
	{
		return p_properties[client][Property];
	}
	else
		return 0;
}
public void SetPlayerProp(int client, SBPlayerProp Property, any value)
{
	if (client > 0 && client <= MaxClients)
	{
		p_properties[client][Property]=value;
	}
}

public NSB_GetPlayerProp(Handle:plugin,numParams)
{
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		//return p_properties[client][SBPlayerProp:GetNativeCell(2)];
		return GetPlayerProp(client,view_as<SBPlayerProp>(GetNativeCell(2)));
	}
	else
		return 0;
}
public NSB_SetPlayerProp(Handle:plugin,numParams)
{
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		//p_properties[client][SBPlayerProp:GetNativeCell(2)]=GetNativeCell(3);
		SetPlayerProp(client,GetNativeCell(2),GetNativeCell(3));
	}
}

public bool SpawnPlayer(int client)
{
	if (SB_ValidPlayer(client))
	{
		SDKCall(hSpawnPlayer,client);

		SB_Engine_Internal_OnSB_SpawnPlayer(client);

		Call_StartForward(FHOnSB_SpawnPlayer);
		Call_PushCell(client);
		Call_Finish();
		return true;
	}
	else
		return false;
}

public NSB_SpawnPlayer(Handle:plugin,numParams)
{
	int client=GetNativeCell(1);
	return SpawnPlayer(client);
}
