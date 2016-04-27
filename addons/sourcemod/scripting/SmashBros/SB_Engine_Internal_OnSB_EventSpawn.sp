//SB_Engine_Internal_OnSB_EventSpawn.sp

public Action SB_Engine_Internal_OnSB_EventSpawn()
{
	Action returnVal = Plugin_Continue;
	if(SB_ValidPlayer(client))
	{
		iTotalScore[client]=SB_GetPlayerProp(client,iLives);

		//if(TF2_GetPlayerClass(client)==TFClass_DemoMan)
		//{
			//SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		//}
		SB_SetPlayerProp(client,iDamage,0);
		//SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
		SpawnProtect(client);

		if(bHopEnabled)
		{
			FC_SetBhop(client, false);
			CreateTimer(GetConVarFloat(sb_fc_bhop), AllowBhopAgain, client);
		}
	}
	return returnVal;
}
