//SB_001_OnClientPutInServer.sp

public OnClientPutInServer(client)
{
	respawn[client]=1.0;
	ResetClientVars(client);
	SB_Engine_DamageSystem_OnClientPutInServer(client);
	SB_Engine_Display_OnClientPutInServer(client);
}
