//SB_001_OnClientConnected.sp

public OnClientConnected(client)
{
	ResetClientVars(client);
	SB_Engine_Display_OnClientConnected(client);
}
