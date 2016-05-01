//SB_Engine_Internal_OnSB_RoundEnd.sp

public SB_Engine_Internal_OnSB_RoundEnd()
{
	new iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");

	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
		{
			//ReplyToCommand(client, "Unable to find or create a game_round_win entity!");
			SB_DP("Unable to find or create a game_round_win entity!");
			return;
		}
	}

	int teamred, teamblue;
	CalculateTeamScores(teamred,teamblue);

	int iWinningTeam = 0;

	if(teamred>teamblue)
	{
		iWinningTeam=TEAM_RED;
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}RED TEAM WINS!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}
	else if(teamred<teamblue)
	{
		iWinningTeam=TEAM_BLUE;
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}BLUE TEAM WINS!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}
	else
	{
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}STALEMATE!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}

	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");

	SB_Engine_Sound_SB_Engine_Internal_OnSB_RoundEnd();
}
