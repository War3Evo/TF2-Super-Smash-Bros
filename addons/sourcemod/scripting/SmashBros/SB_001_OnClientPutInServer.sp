//SB_001_OnClientPutInServer.sp

public OnClientPutInServer(client)
{
	respawn[client]=1.0;
	ResetClientVars(client);
}
