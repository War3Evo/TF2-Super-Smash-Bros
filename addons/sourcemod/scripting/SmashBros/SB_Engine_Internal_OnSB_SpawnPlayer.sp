//SB_Engine_Internal_OnSB_SpawnPlayer.sp

public void SB_Engine_Internal_OnSB_SpawnPlayer(int client)
{
	if(SB_ValidPlayer(client))
	{
		//iTotalScore[client]=GetPlayerProp(client,iLives);

		if(bHopEnabled)
		{
			//ServerCommand("sm_bhop_enabled %d 0",GetClientUserId(client));
			//FC_SetBhop2(client, false);
			FC_SetBhop2(client, false, false);
			bStopMovement[client] = true;
			//PrintToChatAll("bStopMovement SB_Engine_Internal_OnSB_SpawnPlayer");
			CreateTimer(GetConVarFloat(sb_fc_bhop), AllowMovementAgain, client);
		}
		SB_Engine_Display_SB_Engine_Internal_OnSB_SpawnPlayer(client);
	}
}
public Action:AllowMovementAgain(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client,true))
	{
		if(bHopEnabled)
		{
			//ServerCommand("sm_bhop_enabled %d 1",GetClientUserId(client));
			//PrintToChatAll("AllowMovementAgain");
			FC_SetBhop2(client, true, true);
		}
		bStopMovement[client] = false;
	}
}

