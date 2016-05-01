//SB_001_OnClientDisconnected.sp

public OnClientDisconnected(client)
{
	ResetClientVars(client);
	SB_Engine_DamageSystem_OnClientDisconnect(client);
}
