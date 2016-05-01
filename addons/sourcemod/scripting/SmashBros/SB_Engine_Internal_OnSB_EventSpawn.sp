//SB_Engine_Internal_OnSB_EventSpawn.sp

public Action SB_Engine_Internal_OnSB_EventSpawn(int client)
{
	Action returnVal = Plugin_Continue;
	if(SB_ValidPlayer(client))
	{
		//iTotalScore[client]=GetPlayerProp(client,iLives);

		//if(TF2_GetPlayerClass(client)==TFClass_DemoMan)
		//{
			//SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		//}
		SetPlayerProp(client,iDamage,0);
		//SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
		SpawnProtect(client);

		if(bHopEnabled)
		{
			//FC_SetBhop2(client, false);
			//FC_SetBhop2(client, false, false);
			bStopMovement[client] = true;

			//PrintToChatAll("bStopMovement SB_Engine_Internal_OnSB_EventSpawn");
			CreateTimer(GetConVarFloat(sb_fc_bhop), AllowMovementAgain, client);
		}
	}
	return returnVal;
}
