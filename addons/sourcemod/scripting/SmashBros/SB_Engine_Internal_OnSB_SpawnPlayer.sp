//SB_Engine_Internal_OnSB_SpawnPlayer.sp

public SB_Engine_Internal_OnSB_SpawnPlayer()
{
	if(SB_ValidPlayer(client))
	{
		iTotalScore[client]=SB_GetPlayerProp(client,iLives);

		if(bHopEnabled)
		{
			//ServerCommand("sm_bhop_enabled %d 0",GetClientUserId(client));
			FC_SetBhop(client, false);
			CreateTimer(GetConVarFloat(sb_fc_bhop), AllowBhopAgain, client);
		}
	}
}
public Action:AllowBhopAgain(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client,true))
	{
		//ServerCommand("sm_bhop_enabled %d 1",GetClientUserId(client));
		FC_SetBhop(client, true, true);
	}
}

