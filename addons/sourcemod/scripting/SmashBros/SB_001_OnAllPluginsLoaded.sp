//SB_001_OnAllPluginsLoaded.sp

public OnAllPluginsLoaded()
{
	SB_Engine_Libraries_OnAllPluginsLoaded();
	//SB_Engine_Display_OnAllPluginsLoaded();

	if(bLateLoad)
	{
		//PrintToChatAll("AskPluginLoad2()==late");
		DamageSystemLateLoad();

		int RS = GameRules_GetProp("m_iRoundState");
		//PrintToChatAll("round state %d",RS);

		//if(GameRules_GetRoundState()==RoundState_RoundRunning)
		//{
			//playing = true;

			//PrintToChatAll("GameRules_GetRoundState()==RoundState_RoundRunning");

		/*
		new iEnt = -1;
		iEnt = FindEntityByClassname(iEnt, "game_round_win");

		if (iEnt < 1)
		{
			iEnt = CreateEntityByName("game_round_win");
			if (IsValidEntity(iEnt))
			{
				DispatchSpawn(iEnt);

				SetVariantInt(0);
				AcceptEntityInput(iEnt, "SetTeam");
				AcceptEntityInput(iEnt, "RoundWin");
			}
		}
		else
		{
			if (IsValidEntity(iEnt))
			{
				SetVariantInt(0);
				AcceptEntityInput(iEnt, "SetTeam");
				AcceptEntityInput(iEnt, "RoundWin");
			}
		}*/

		//PrintToChatAll("Reloading Plugin... A new round must be started!");
		LoopAlivePlayers(client)
		{
			//ForcePlayerSuicide(client);
			int MaxLives = GetConVarInt(sb_lives)>0?GetConVarInt(sb_lives):1;
			SetPlayerProp(client,iLives,MaxLives);
		}
		//}

		if(RS==7)
		{
			//PrintToChatAll("Round Reset");
			StartTheRound();
		}

	}
}
