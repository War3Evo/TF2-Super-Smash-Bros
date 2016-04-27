// SB_Engine_Internal_OnSB_EventDeath.sp

public SB_Engine_Internal_OnSB_EventDeath(int victim,int killer,int assister,int distance,int attacker_hpleft,Handle event)
{
	if(SB_ValidPlayer(victim))
	{
		//if(TF2_GetPlayerClass(victim)==TFClass_DemoMan)
		//{
			//SDKUnhook(victim,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		//}
		if(bHopEnabled)
		{
			FC_SetBhop(victim, false);
		}
	}
}
