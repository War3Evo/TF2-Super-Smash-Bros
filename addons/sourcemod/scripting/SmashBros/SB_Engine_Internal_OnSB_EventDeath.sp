// SB_Engine_Internal_OnSB_EventDeath.sp

public SB_Engine_Internal_OnSB_EventDeath(int victim,int killer,int assister,int distance,int attacker_hpleft,Handle event)
{
	if(GetEventBool(event, "sourcemod"))
		return;

	if(SB_ValidPlayer(victim))
	{
		//if(TF2_GetPlayerClass(victim)==TFClass_DemoMan)
		//{
			//SDKUnhook(victim,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		//}
		if(bHopEnabled)
		{
			//FC_SetBhop2(victim, false);
			FC_SetBhop2(victim, false, false);
			PrintToChatAll("FC_SetBhop2 SB_Engine_Internal_OnSB_EventDeath");
		}
	}

	// orignally from sb_engine_display
	if(victim)
	{
		//SB_SetPlayerProp(victim,iLives,0);
		int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
		SB_SetPlayerProp(victim,iLives,MaxLives);
		SB_SetPlayerProp(victim,iStartingTeam,0);
	}

	if(!SB_GetGamePlaying())
		return;

	if(!GetConVarBool(sb_chatmsg))
		return;

	int teamred, teamblue;
	CalculateTeamScores(teamred,teamblue);

	SB_ChatMessage(0,"{default}[{yellow}Total Lives{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
/*
	new iWinningTeam = 0;

	if(teamred>teamblue)
	{
		iWinningTeam=TEAM_RED;
	}
	else if(teamred<teamblue)
	{
		iWinningTeam=TEAM_BLUE;
	}*/
}
