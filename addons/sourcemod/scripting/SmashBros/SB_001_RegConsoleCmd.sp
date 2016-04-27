//SB_001_RegConsoleCmd.sp

public SB_001_RegConsoleCmd_OnPluginStart()
{
	RegConsoleCmd("allowengineering",SB_ENGINEERING,"allowengineering");
}

public Action:SB_ENGINEERING(client,args)
{
	CreateTimer(0.1,RemoveStuff,0);
}

public Action:RemoveStuff(Handle:t,any:data)
{
	int i = -1;
	while((i = FindEntityByClassname(i,"func_nobuild")) != -1)
	{
		if(IsValidEntity(i))
		{
			AcceptEntityInput( i,"Kill");
		}
	}
	i = -1;
	while((i = FindEntityByClassname(i,"func_respawnroom")) != -1)
	{
		if(IsValidEntity(i))
		{
			AcceptEntityInput( i,"Kill");
		}
	}
}
