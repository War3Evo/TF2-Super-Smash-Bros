//SB_001_OnMapStart.sp

public OnMapStart()
{
	playing=false;
	NewMap=true;

	SB_Engine_Sound_SB_001_OnMapStart();
	SB_001_PrecacheModel_OnMapStart();

	int playerresource = -1;
	iTotalScoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");
	if (iTotalScoreOffset != -1)
	{
		playerresource = FindEntityByClassname(playerresource, "tf_player_manager");
		if (playerresource != INVALID_ENT_REFERENCE)
		{
			SB_001_SDKHook_OnPluginStart(playerresource);
		}
	}
}
