// SB_Engine_InitForwards.sp


//=============================================================================
// War3Source_InitForwards
//=============================================================================
public bool SB_Engine_InitForwards()
{
	//bool Return_InitForwards=false;
	FHOnSB_RoundEnd=CreateGlobalForward("OnSB_RoundEnd",ET_Ignore);

	// only triggered when native SB_SpawnPlayer is triggered
	FHOnSB_SpawnPlayer=CreateGlobalForward("OnSB_SpawnPlayer",ET_Ignore, Param_Cell);

	g_OnSB_EventSpawnFH=CreateGlobalForward("OnSB_EventSpawn",ET_Hook,Param_Cell);
	g_OnSB_EventSpawnFH_Post=CreateGlobalForward("OnSB_EventSpawn_Post",ET_Ignore,Param_Cell);
	g_OnSB_EventDeathFH=CreateGlobalForward("OnSB_EventDeath",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);

	SB_Engine_DamageSystem_SB_Engine_InitForwards();

	return true;
}


public void DoForward_OnSB_EventSpawn(int client)
{
		if(!g_sb_enabled) return;

		Action returnVal = SB_Engine_Internal_OnSB_EventSpawn(client);

		if(returnVal != Plugin_Continue)
		{
			return;
		}

		Call_StartForward(g_OnSB_EventSpawnFH);
		Call_PushCell(client);
		Call_Finish(returnVal);

		if(returnVal != Plugin_Continue)
		{
			return;
		}

		SB_Engine_Display_OnSB_EventSpawn_Post(client);

		Call_StartForward(g_OnSB_EventSpawnFH_Post);
		Call_PushCell(client);
		Call_Finish(dummyreturn);
}

public void DoForward_OnSB_EventDeath(int victim,int killer,int assister,int distance,int attacker_hpleft,Handle event)
{
		if(!g_sb_enabled) return;

		SB_Engine_Internal_OnSB_EventDeath(victim,killer,assister,distance,attacker_hpleft,event);

		Call_StartForward(g_OnSB_EventDeathFH);
		Call_PushCell(victim);
		Call_PushCell(killer);
		Call_PushCell(assister);
		Call_PushCell(distance);
		Call_PushCell(attacker_hpleft);
		Call_PushCell(event);
		Call_Finish(dummyreturn);
}
