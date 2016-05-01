//SB_001_SDKHook.sp

public SB_001_SDKHook_OnPluginStart(int playerresource)
{
	SDKHook(playerresource, SDKHook_ThinkPost, Hook_OnThinkPost);
}

public Hook_OnThinkPost(iEnt)
{
/*
	static teamScoreOffset = -1;
	if (teamScoreOffset == -1)
	{
		teamScoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTeam");
    }
	static classOffset = -1;
	if (classOffset == -1)
	{
		classOffset = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClass");
    }
	static aliveOffset = -1;
	if (aliveOffset == -1)
	{
		aliveOffset = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
    }*/
	//int teamScore[MAXPLAYERS+1];
	//int class[MAXPLAYERS+1];
	//int alive[MAXPLAYERS+1];
	//GetEntDataArray(iEnt, teamScoreOffset, teamScore, MaxClients+1);
	//GetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
	//GetEntDataArray(iEnt, classOffset, class, MaxClients+1);
	//GetEntDataArray(iEnt, aliveOffset, alive, MaxClients+1);
	//teamScore[spawnRocketIndex]=spawnRocketTeam;
	//iTotalScore[spawnRocketIndex]=spawnRocketScore;
	//class[spawnRocketIndex]=3;
	//alive[spawnRocketIndex]=1;
	if (iTotalScoreOffset != -1)
	{
		SetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
	}
	//SetEntDataArray(iEnt, teamScoreOffset, teamScore, MaxClients+1);
	//SetEntDataArray(iEnt, classOffset, class, MaxClients+1);
	//SetEntDataArray(iEnt, aliveOffset, alive, MaxClients+1);

	if(SB_ValidPlayer(iEnt,true))
	{
		if(bStopMovement[iEnt])
		{
			StopMovement(iEnt);
		}
	}
}

public void StopMovement(int client)
{
	// Stop Velocity!
	float fNewVel[3];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fNewVel);
}
