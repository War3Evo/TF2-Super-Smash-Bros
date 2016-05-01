//SB_001_RegConsoleCmd.sp

public SB_001_RegConsoleCmd_OnPluginStart()
{
	RegConsoleCmd("allowengineering",SB_ENGINEERING,"allowengineering");

	RegConsoleCmd("sm_sbclass",Command_ChangeClass);
	RegConsoleCmd("sm_scout",Command_ChangeClassScout);
	RegConsoleCmd("sm_sniper",Command_ChangeClassSniper);
	RegConsoleCmd("sm_soldier",Command_ChangeClassSoldier);
	RegConsoleCmd("sm_demoman",Command_ChangeClassDemo);
	RegConsoleCmd("sm_demo",Command_ChangeClassDemo);
	RegConsoleCmd("sm_medic",Command_ChangeClassMedic);
	RegConsoleCmd("sm_heavy",Command_ChangeClassHeavy);
	RegConsoleCmd("sm_pyro",Command_ChangeClassPyro);
	RegConsoleCmd("sm_spy",Command_ChangeClassSpy);
	RegConsoleCmd("sm_engineer",Command_ChangeClassEngi);
	RegConsoleCmd("sm_engi",Command_ChangeClassEngi);

	RegConsoleCmd("jointeam", Command_jointeam);

	RegAdminCmd("sm_lives", Command_Lives, ADMFLAG_BAN, "sm_lives");

	SB_Engine_Weapon_Manager_SB_001_RegConsoleCmd();
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


public Action Command_ChangeClass(int client, int args)
{
	//PrintToChatAll("Command_ChangeClass");
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	ChangeClass_Menu(client);

	return Plugin_Handled;
}

public Action Command_ChangeClassScout(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 1;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSniper(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 2;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSoldier(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 3;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassDemo(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 4;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassMedic(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 5;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassHeavy(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 6;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassPyro(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 7;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassSpy(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 8;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}
public Action Command_ChangeClassEngi(int client, int args)
{
	if(!SB_ValidPlayer(client)) return Plugin_Continue;
	int itemnumber = 9;
	PlayerNextClass[client]=view_as<TFClassType>(itemnumber);
	SB_ChatMessage(client,"You will be %s next spawn.",ClassList[itemnumber-1]);
	return Plugin_Handled;
}

public Action:Command_jointeam(client, args) {
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena")) {
		g_spec[client] = true;
	} else {
		g_spec[client] = false;
		if(playing)
		{
			SB_ChatMessage(client,"{yellow}You can not join while the round is active!");
			ForcePlayerSuicide(client);
		}
	}
}

public Action:Command_Lives(client, args)
{
	for(int i=1;i<MaxClients;i++)
	{
		if(SB_ValidPlayer(i))
		{
			char sClientName[32];
			GetClientName(i,STRING(sClientName));
			PrintToConsole(client,"%s has %d lives.",sClientName,GetPlayerProp(i,iLives));
		}
	}

}
