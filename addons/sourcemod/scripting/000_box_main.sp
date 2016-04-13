// *************************************************************************
// 000_box_main.sp
//
// Made by  El Diablo <admin@war3evo.info>
//
//  War3Evo Community Forums: https://war3evo.info/forums/index.php

// https://forums.alliedmods.net/showthread.php?t=264551&page=3

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// DO NOT GO BELOW THIS LINE AND EDIT THE FILES UNLESS YOU KNOW WHAT YOUR DOING
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------



#pragma semicolon 1

#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <000_box_engine>
#include <tf2_stocks>

#if !defined _War3Source_included
/**
 * Prints Message to server and all chat
 * For debugging prints
 */
stock DP(const String:szMessage[], any:...)
{
	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
}
#endif

new String:g_sPushModel[64] = "models/props_2fort/frog.mdl";

new iMenuClient = 0;

new bool:ToggleBox=false;
new bool:SeeAllBoxes=false;
new bool:FollowMeBoxes=false;
new FollowMeClient=0;
new SeeAllBoxesClient=0;

new CurrentBoxID=-1;

new bool:SeeDetails=false;

new bool:changesettings=false;

new g_cornerSW=0;
new BehaviorBitFlags = 0;
new TargetBitFlags = 0;

new Handle:CurrentClientMenuHandle[MAXPLAYERS + 1];
new TriggerClientMenu[MAXPLAYERS + 1];


new CurrentClientInBox[MAXPLAYERS + 1];

new bool:CanDoNoDamage[MAXPLAYERS + 1];
new bool:NoShooting[MAXPLAYERS + 1];

new m_OffsetActiveWeapon;

new Handle:ClientNameInfoMessage;

new Handle:g_hCvarAllowed;

stock ClearVariables()
{
	changesettings=false;
	g_cornerSW=0;
	BehaviorBitFlags = 0;
	TargetBitFlags = 0;
	SeeDetails=false;
	FollowMeBoxes=false;
	SeeAllBoxes=false;
	ToggleBox=false;
	CurrentBoxID=-1;
	FollowMeClient=0;
	SeeAllBoxesClient=0;

	LoopMaxClients(client)
	{
		TriggerClientMenu[client]=-1;
		CanDoNoDamage[client]=false;
		NoShooting[client]=false;
	}
}

public Plugin:myinfo =
{
	name = "Box Main Plugin",
	author = "El Diablo",
	description = "Box Main",
	version = "1.0",
	url = "http://www.war3evo.info/"
};

public OnPluginStart()
{
	ClientNameInfoMessage = CreateHudSynchronizer();

	// need to create a flag string to check against and allow any number of those flags
	g_hCvarAllowed = CreateConVar("box_allowed_flags", "z", "Set up to 21 admin flag characters.");

	RegConsoleCmd("sm_box",	Command_BoxMenu);
	RegConsoleCmd("sm_boxloadfromfile",	Command_BoxesLoad);
	RegConsoleCmd("sm_boxsavetofile",		Command_BoxesSave);
}

stock bool:CheckFlags(client)
{
	new String:flagString[21];
	GetConVarString(g_hCvarAllowed, STRING(flagString));

	new AdminId:admin = GetUserAdmin(client);
	if(admin!=INVALID_ADMIN_ID)
	{
		new flags = ReadFlagString(flagString);
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				if(GetAdminFlag(admin, AdminFlag:i))
				{
					return true;
				}
			}
		}
	}
	return false;
}

public OnMapStart()
{
	ClearVariables();

	PrecacheModel(g_sPushModel);

	LoopIngameClients(client)
	{
		SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	}
	m_OffsetActiveWeapon=FindSendPropOffs("CBasePlayer","m_hActiveWeapon");

	Box_LoadFromFile();
}

public OnMapEnd()
{
	ClearVariables();
	Box_ClearBoxes();
}

public Action OnSB_EventSpawn (int client)
{
	TriggerClientMenu[client]=-1;
	CanDoNoDamage[client]=false;
	NoShooting[client]=false;
	return Plugin_Continue;
}

public Action:Command_BoxesSave(client, args)
{
	if(ValidPlayer(client))
	{
		if(CheckFlags(client))
		{
			Box_SaveToFile();
		}
	}
	return Plugin_Handled;
}

public Action:Command_BoxesLoad(client, args)
{
	if(ValidPlayer(client))
	{
		if(CheckFlags(client))
		{
			if(Box_LoadFromFile())
			{
				PrintToChat(client,"Boxes Loaded");
			}
			else
			{
				PrintToChat(client,"Unable to load boxes, check configs/boxes.cfg");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_BoxMenu(client, args)
{
	if(ValidPlayer(client))
	{
		if(CheckFlags(client))
		{
			BoxMenu(client);
		}
	}
	return Plugin_Handled;
}


////////////////////////////////////////////////////////////////////////////////////
// MENU SYSTEM
////////////////////////////////////////////////////////////////////////////////////

stock BoxMenu(client)
{
	iMenuClient = client;

	new Handle:hMenu = CreateMenu(MenuHandle_BOX_Menu);
	SetMenuExitBackButton(hMenu, false);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuTitle(hMenu,"BOX Main Menu:");

	new String:Buffer[64];

	AddMenuItem(hMenu,"1","Create Box",ITEMDRAW_DEFAULT);

	if(CurrentBoxID>-1)
	{
		Format(STRING(Buffer), "Delete Box (your standing in) from File?");
		AddMenuItem(hMenu,"2",Buffer,ITEMDRAW_DEFAULT);
	}
	else
	{
		Format(STRING(Buffer), "must be in box to delete");
		AddMenuItem(hMenu,"22",Buffer,ITEMDRAW_DEFAULT);
	}

	if(CurrentBoxID>-1)
	{
		Format(STRING(Buffer), "Change Settings");
		AddMenuItem(hMenu,"8",Buffer,ITEMDRAW_DEFAULT);
	}
	else
	{
		Format(STRING(Buffer), "must be in box to change settings");
		AddMenuItem(hMenu,"88",Buffer,ITEMDRAW_DEFAULT);
	}

	AddMenuItem(hMenu,"3","Reset & Reload All Boxes",ITEMDRAW_DEFAULT);

	Format(STRING(Buffer), "Toggle Box %s", ToggleBox?"ON":"OFF");
	AddMenuItem(hMenu,"4",Buffer,ITEMDRAW_DEFAULT);

	Format(STRING(Buffer), "See all %s", SeeAllBoxes?"ON":"OFF");
	AddMenuItem(hMenu,"5",Buffer,ITEMDRAW_DEFAULT);

	Format(STRING(Buffer), "Follow Me %s", FollowMeBoxes?"ON":"OFF");
	AddMenuItem(hMenu,"6",Buffer,ITEMDRAW_DEFAULT);

	Format(STRING(Buffer), "See Details %s", SeeDetails?"ON":"OFF");
	AddMenuItem(hMenu,"7",Buffer,ITEMDRAW_DEFAULT);

	if(ValidPlayer(client))
	{
		CurrentClientMenuHandle[client]= hMenu;
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_BOX_Menu(Handle:hMenu, MenuAction:action, param1, selection)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			//boxtoggle=false;
		}
		case MenuAction_Select:
		{
			new String:SelectionInfo[8];
			new String:SelectionDispText[2048];

			new SelectionStyle;
			GetMenuItem(hMenu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

			new itemnumber=StringToInt(SelectionInfo);

			new client=param1;

			if(ValidPlayer(client))
			{
				switch(itemnumber)
				{
					case 1:
					{
						changesettings=false;
						MarkCornerMenu(client);
						return;
					}
					case 2:
					{
						// delete
						if(CurrentBoxID>-1)
						{
							if(Box_Remove(CurrentBoxID))
							{
								CPrintToChat(client,"{red}Box Removed!");
								Box_SaveToFile();
							}
							else
							{
								CPrintToChat(client,"{red}Box not found!");
								CPrintToChat(client,"{red}Go inside a box to delete.");
							}
						}
						else
						{
							CPrintToChat(client,"{red}Go inside a box to delete.");
						}
					}
					case 3:
					{
						Box_Reset();
						if(Box_LoadFromFile())
						{
							PrintToChat(client,"Load from file successful!");
						}
					}
					case 4:
					{
						ToggleBox=ToggleBox?false:true;
						Box_Toggle(ToggleBox);
					}
					case 5:
					{
						if(SeeAllBoxes)
						{
							SeeAllBoxes=false;
							SeeAllBoxesClient=0;
						}
						else
						{
							SeeAllBoxes=true;
							SeeAllBoxesClient=client;
						}
					}
					case 6:
					{
						if(FollowMeBoxes)
						{
							FollowMeBoxes=false;
							FollowMeClient=0;
						}
						else
						{
							FollowMeBoxes=true;
							FollowMeClient=client;
						}
					}
					case 7:
					{
						SeeDetails = SeeDetails?false:true;
					}
					case 8:
					{
						//change settings
						if(CurrentBoxID>-1)
						{
							BehaviorBitFlags = Box_GetBehavior(CurrentBoxID);
							TargetBitFlags = Box_GetTarget(CurrentBoxID);
							changesettings=true;
							SetBehaviorMenu(client,0);
							return;
						}
					}
				}
				BoxMenu(client);
			}
		}
		case MenuAction_End:
		{
			new client=param1;
			if(ValidPlayer(client))
			{
				CurrentClientMenuHandle[client]= INVALID_HANDLE;
			}
			CloseHandle(hMenu);
		}
	}
}

stock MarkCornerMenu(client, cornerSw=0)
{
	new Handle:hMarkCornerMenu = CreateMenu(MenuHandle_MarkCorner_Menu);
	SetMenuTitle(hMarkCornerMenu,"BOX Corner Menu:");

	new String:Buffer[64];

	if(cornerSw==0 || cornerSw==1)
	{
		AddMenuItem(hMarkCornerMenu,"1","Mark Corner",ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "No Clip %s", Box_GetNoClip(client)?"ON":"OFF");
		AddMenuItem(hMarkCornerMenu,"5",Buffer,ITEMDRAW_DEFAULT);
	}
	else
	{
		AddMenuItem(hMarkCornerMenu,"2","Start Box Over",ITEMDRAW_DEFAULT);
		AddMenuItem(hMarkCornerMenu,"3","Set Behavior Menu",ITEMDRAW_DEFAULT);
		AddMenuItem(hMarkCornerMenu,"4","Save Box to File",ITEMDRAW_DEFAULT);
	}

	if(ValidPlayer(client))
	{
		CurrentClientMenuHandle[client]= hMarkCornerMenu;
	}
	DisplayMenu(hMarkCornerMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_MarkCorner_Menu(Handle:hMenu, MenuAction:action, param1, selection)
{
	switch (action)
	{
	case MenuAction_Cancel:
	{
		if(selection==MenuCancel_Exit||selection==MenuCancel_Timeout)
		{
			Box_Toggle(false);
		}
	}
	case MenuAction_Select:
		{
			new String:SelectionInfo[8];
			new String:SelectionDispText[2048];

			new SelectionStyle;
			GetMenuItem(hMenu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

			new itemnumber=StringToInt(SelectionInfo);

			new client=param1;

			if(ValidPlayer(client))
			{
				switch(itemnumber)
				{
					case 1:
					{
						Box_Toggle(true);
						g_cornerSW=Box_MarkCorner(client);
						MarkCornerMenu(client,g_cornerSW);
						return;
					}
					case 2:
					{
						g_cornerSW=Box_MarkCorner(client,true);
						MarkCornerMenu(client,g_cornerSW);
						return;
					}
					case 3:
					{
						BehaviorBitFlags=0;
						TargetBitFlags=0;
						SetBehaviorMenu(client);
						return;
					}
					case 4:
					{
						// Save Box
						Box_Toggle(false);
						Box_SaveCurrentBox(BehaviorBitFlags,TargetBitFlags);
						Box_SaveToFile();
						BoxMenu(client);
#if defined _War3Source_included
						War3_SetBuff(client,bNoClipMode,0,false);
						War3_SetBuff(client,bFlyMode,0,false);
#endif
						return;
					}
					case 5:
					{
#if defined _War3Source_included
						if(!W3GetBuff(client,bNoClipMode,0))
						{
							War3_SetBuff(client,bNoClipMode,0,true);
							War3_SetBuff(client,bFlyMode,0,true);
						}
						else
						{
							War3_SetBuff(client,bNoClipMode,0,false);
							War3_SetBuff(client,bFlyMode,0,false);
						}
#else
						Box_NoClip(client,!Box_GetNoClip(client));
#endif
						MarkCornerMenu(client,g_cornerSW);
						return;
					}
				}
			}
		}
	case MenuAction_End:
		{
			new client=param1;
			if(ValidPlayer(client))
			{
				CurrentClientMenuHandle[client]= INVALID_HANDLE;
			}
			CloseHandle(hMenu);
		}
	}
}

stock SetBehaviorMenu(client,pagenum=0)
{
	new Handle:hMenu = CreateMenu(MenuHandle_Behavior_Menu);
	SetMenuExitBackButton(hMenu, false);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, false);
	SetMenuTitle(hMenu,"Behavior(s) and Target(s)");

	new String:Buffer[32];

	if(pagenum==0)
	{
		Format(STRING(Buffer), "[%s] No Damage", HasBitflags(BehaviorBitFlags,BEHAVIOR_NO_DAMAGE)?"+":"-");
		AddMenuItem(hMenu,"1",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] No Shoot", HasBitflags(BehaviorBitFlags,BEHAVIOR_NO_SHOOTING)?"+":"-");
		AddMenuItem(hMenu,"15",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] No Buildings", HasBitflags(BehaviorBitFlags,BEHAVIOR_NO_BUILDINGS)?"+":"-");
		AddMenuItem(hMenu,"2",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Kill Zone", HasBitflags(BehaviorBitFlags,BEHAVIOR_KILL_ZONE)?"+":"-");
		AddMenuItem(hMenu,"16",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Red Team", HasBitflags(TargetBitFlags,BOX_TARGET_REDTEAM)?"+":"-");
		AddMenuItem(hMenu,"3",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Blue Team", HasBitflags(TargetBitFlags,BOX_TARGET_BLUETEAM)?"+":"-");
		AddMenuItem(hMenu,"4",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Scouts", HasBitflags(TargetBitFlags,BOX_TARGET_SCOUT)?"+":"-");
		AddMenuItem(hMenu,"5",Buffer,ITEMDRAW_DEFAULT);

		//AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"9","Next Page",ITEMDRAW_DEFAULT);
		AddMenuItem(hMenu,"999","Save Settings",ITEMDRAW_DEFAULT);
	}
	else if(pagenum==1)
	{
		Format(STRING(Buffer), "[%s] Target Soldiers", HasBitflags(TargetBitFlags,BOX_TARGET_SOLDIER)?"+":"-");
		AddMenuItem(hMenu,"6",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Demomen", HasBitflags(TargetBitFlags,BOX_TARGET_DEMOMAN)?"+":"-");
		AddMenuItem(hMenu,"7",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Medic", HasBitflags(TargetBitFlags,BOX_TARGET_MEDIC)?"+":"-");
		AddMenuItem(hMenu,"10",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Heavy", HasBitflags(TargetBitFlags,BOX_TARGET_HEAVY)?"+":"-");
		AddMenuItem(hMenu,"11",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Pyro", HasBitflags(TargetBitFlags,BOX_TARGET_PYRO)?"+":"-");
		AddMenuItem(hMenu,"12",Buffer,ITEMDRAW_DEFAULT);

		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"8","Previous Page",ITEMDRAW_DEFAULT);
		AddMenuItem(hMenu,"20","Next Page",ITEMDRAW_DEFAULT);
		AddMenuItem(hMenu,"999","Save Settings",ITEMDRAW_DEFAULT);
	}
	else if(pagenum==2)
	{
		Format(STRING(Buffer), "[%s] Target Spy", HasBitflags(TargetBitFlags,BOX_TARGET_SPY)?"+":"-");
		AddMenuItem(hMenu,"13",Buffer,ITEMDRAW_DEFAULT);

		Format(STRING(Buffer), "[%s] Target Engineer", HasBitflags(TargetBitFlags,BOX_TARGET_ENGINEER)?"+":"-");
		AddMenuItem(hMenu,"14",Buffer,ITEMDRAW_DEFAULT);

		if(CurrentBoxID>-1)
		{
			Format(STRING(Buffer), "(toggle) Box %s", Box_isEnable(CurrentBoxID)?"Enabled":"Disabled");
			AddMenuItem(hMenu,"50",Buffer,ITEMDRAW_DEFAULT);
		}

		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"9","Previous Page",ITEMDRAW_DEFAULT);
		AddMenuItem(hMenu,"777","",ITEMDRAW_SPACER);
		AddMenuItem(hMenu,"999","Save Settings",ITEMDRAW_DEFAULT);
	}

	if(ValidPlayer(client))
	{
		CurrentClientMenuHandle[client]= hMenu;
	}
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_Behavior_Menu(Handle:hMenu, MenuAction:action, param1, selection)
{
	if(action==MenuAction_Cancel)
	{
		if(selection==MenuCancel_Exit||selection==MenuCancel_Timeout)
		{
			new client=param1;
			MarkCornerMenu(client, 2);
		}
	}
	else if(action==MenuAction_Select)
	{
		new String:SelectionInfo[8];
		new String:SelectionDispText[2048];

		new SelectionStyle;
		GetMenuItem(hMenu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

		new itemnumber=StringToInt(SelectionInfo);

		new client=param1;

		if(ValidPlayer(client))
		{
			switch(itemnumber)
			{
				case 1:
				{
					BehaviorBitFlags = ToggleBitflag(BehaviorBitFlags,BEHAVIOR_NO_DAMAGE);
					SetBehaviorMenu(client,0);
				}
				case 15:
				{
					BehaviorBitFlags = ToggleBitflag(BehaviorBitFlags,BEHAVIOR_NO_SHOOTING);
					SetBehaviorMenu(client,0);
				}
				case 2:
				{
					BehaviorBitFlags = ToggleBitflag(BehaviorBitFlags,BEHAVIOR_NO_BUILDINGS);
					SetBehaviorMenu(client,0);
				}
				case 3:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_REDTEAM);
					SetBehaviorMenu(client,0);
				}
				case 4:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_BLUETEAM);
					SetBehaviorMenu(client,0);
				}
				case 5:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_SCOUT);
					SetBehaviorMenu(client,0);
				}
				case 8:
				{
					SetBehaviorMenu(client,0);
				}
				case 9:
				{
					SetBehaviorMenu(client,1);
				}
				case 6:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_SOLDIER);
					SetBehaviorMenu(client,1);
				}
				case 7:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_DEMOMAN);
					SetBehaviorMenu(client,1);
				}
				case 10:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_MEDIC);
					SetBehaviorMenu(client,1);
				}
				case 11:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_HEAVY);
					SetBehaviorMenu(client,1);
				}
				case 12:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_PYRO);
					SetBehaviorMenu(client,1);
				}
				case 20:
				{
					SetBehaviorMenu(client,2);
				}
				case 13:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_SPY);
					SetBehaviorMenu(client,2);
				}
				case 14:
				{
					TargetBitFlags = ToggleBitflag(TargetBitFlags,BOX_TARGET_ENGINEER);
					SetBehaviorMenu(client,2);
				}
				case 16:
				{
					BehaviorBitFlags = ToggleBitflag(BehaviorBitFlags,BEHAVIOR_KILL_ZONE);
					SetBehaviorMenu(client,0);
				}
				case 50:
				{
					if(CurrentBoxID>-1)
					{
						Box_Enable(CurrentBoxID,!Box_isEnable(CurrentBoxID));
					}
					SetBehaviorMenu(client,2);
				}
				case 999:
				{
					if(!changesettings)
					{
						MarkCornerMenu(client, 2);
					}
					else
					{
						if(CurrentBoxID>-1)
						{
							Box_SetBehavior(CurrentBoxID,BehaviorBitFlags);
							Box_SetTarget(CurrentBoxID,TargetBitFlags);
							Box_SaveToFile();
							BoxMenu(client);
							return;
						}
					}
					//if(hMenu!=INVALID_HANDLE) CloseHandle(hMenu);
				}
			}
		}
	}
	else if(action==MenuAction_End)
	{
		new client=param1;
		if(ValidPlayer(client))
		{
			CurrentClientMenuHandle[client]= INVALID_HANDLE;
		}
		CloseHandle(hMenu);
	}
}

// BOX BEHAVIORS

public OnBoxPulse(boxindex, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled)
{
	if(SeeAllBoxes)
	{
		// for production version uncomment below and remove the other
		Box_DrawBoxID(boxindex,SeeAllBoxesClient);
		//Box_DrawBoxID(boxindex,0);
	}
}

public OnBoxTrigger(boxindex, client, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled)
{
	if(SeeAllBoxes && SeeAllBoxesClient==client && CurrentBoxID!=boxindex)
	{
		CurrentBoxID=boxindex;
	}
	else if(FollowMeBoxes && FollowMeClient==client && CurrentBoxID!=boxindex)
	{
		CurrentBoxID=boxindex;
	}

	if(SeeAllBoxes && SeeAllBoxesClient==client && CurrentBoxID==boxindex)
	{
		if(SeeDetails)
		{
			SeeDetailsDisplay(boxindex, behaviorBitFlags, targetBitFlags,SeeAllBoxesClient, isBoxEnabled);
		}
	}
	else if(FollowMeBoxes && FollowMeClient==client && CurrentBoxID==boxindex)
	{
		// for production version uncomment below and remove the other
		Box_DrawBoxID(boxindex,client);
		//Box_DrawBoxID(boxindex,0);
		if(SeeDetails)
		{
			SeeDetailsDisplay(boxindex, behaviorBitFlags, targetBitFlags,FollowMeClient, isBoxEnabled);
		}
	}

	// Menu Refresh
	if(client == iMenuClient
	&& TriggerClientMenu[client]!=CurrentBoxID
	&& (GetClientMenu(client)==MenuSource_External
	||GetClientMenu(client)==MenuSource_Normal
	||GetClientMenu(client)==MenuSource_RawPanel))
	{
		if(CurrentClientMenuHandle[client]!=INVALID_HANDLE)
		{
			new String:Buffer[64];
			if(GetMenuTitle(CurrentClientMenuHandle[client], STRING(Buffer)))
			{
				if(StrEqual("BOX Main Menu:",Buffer))
				{
					//PrintToChatAll("OnBoxTrigger refresh box%d",boxindex);
					CancelMenu(CurrentClientMenuHandle[client]);
					CurrentClientMenuHandle[client]=INVALID_HANDLE;
					BoxMenu(client);
					TriggerClientMenu[client]=CurrentBoxID;
				}
			}
		}
	}

	if(!isBoxEnabled) return;


	new team = GetClientTeam(client);

	if(!((targetBitFlags & BOX_TARGET_REDTEAM) && (targetBitFlags & BOX_TARGET_BLUETEAM)))
	{
		if ((targetBitFlags & BOX_TARGET_REDTEAM) && (team != 2))
		{
			return;
		}
		if ((targetBitFlags & BOX_TARGET_BLUETEAM) && (team != 3))
		{
			return;
		}
	}

	new TFClassType:class = TF2_GetPlayerClass(client);

	if ((targetBitFlags & BOX_TARGET_SCOUT) && class!=TFClass_Scout)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_SNIPER) && class!=TFClass_Sniper)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_SOLDIER) && class!=TFClass_Soldier)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_DEMOMAN) && class!=TFClass_DemoMan)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_MEDIC) && class!=TFClass_Medic)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_HEAVY) && class!=TFClass_Heavy)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_PYRO) && class!=TFClass_Pyro)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_SPY) && class!=TFClass_Spy)
	{
		return;
	}
	if ((targetBitFlags & BOX_TARGET_ENGINEER) && class!=TFClass_Engineer)
	{
		return;
	}

	CurrentClientInBox[client]=boxindex;

	if(HasBitflags(behaviorBitFlags,BEHAVIOR_KILL_ZONE))
	{
		// Damage instead of kill to help keep lives.
		//SDKHooks_TakeDamage(client, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
		//ForcePlayerSuicide(client);


		// fixed kill zones to work properly:

		int pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(client,"targetname","sb_hurtme"); //set victim as the target for damage
			DispatchKeyValue(pointHurt,"Damagetarget","sb_hurtme");
			DispatchKeyValue(pointHurt,"Damage","99999");
			DispatchKeyValue(pointHurt,"DamageType","32");
			DispatchKeyValue(pointHurt,"classname","sb_point_hurt");
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",-1);
			DispatchKeyValue(client,"targetname","sb_donthurtme"); //unset the victim as target for damage
			RemoveEdict(pointHurt);
		}

		return;
	}
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_DAMAGE))
	{
		CanDoNoDamage[client]=true;
	}
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_SHOOTING))
	{
		NoShooting[client]=true;
	}
}
public OnBoxNotTrigger(boxindex, client, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled)
{
	if(SeeAllBoxes && SeeAllBoxesClient==client && CurrentBoxID==boxindex)
	{
		CurrentBoxID=-1;
	}
	else if(FollowMeBoxes && FollowMeClient==client && CurrentBoxID==boxindex)
	{
		CurrentBoxID=-1;
	}

	// Menu Refresh
	if(client == iMenuClient
	&& TriggerClientMenu[client]==boxindex
	&& (GetClientMenu(client)==MenuSource_External
	||GetClientMenu(client)==MenuSource_Normal
	||GetClientMenu(client)==MenuSource_RawPanel))
	{
		if(CurrentClientMenuHandle[client]!=INVALID_HANDLE)
		{
			new String:Buffer[64];
			if(GetMenuTitle(CurrentClientMenuHandle[client], STRING(Buffer)))
			{
				if(StrEqual("BOX Main Menu:",Buffer))
				{
					//PrintToChatAll("OnBoxNotTrigger refresh box%d",boxindex);
					CancelMenu(CurrentClientMenuHandle[client]);
					CurrentClientMenuHandle[client]=INVALID_HANDLE;
					BoxMenu(client);
					TriggerClientMenu[client]=-1;
				}
			}
		}
	}

	if(!isBoxEnabled) return;

	if(CurrentClientInBox[client]==boxindex)
	{
		CurrentClientInBox[client]=-1;
		if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_DAMAGE))
		{
			CanDoNoDamage[client]=false;
		}
		if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_SHOOTING))
		{
			NoShooting[client]=false;
		}
	}
}

stock SeeDetailsDisplay(boxindex, behaviorBitFlags, targetBitFlags, xFollowMeClient, bool:isBoxEnabled)
{
	if(ValidPlayer(xFollowMeClient))
	{
		new String:Buffer[192];
		Format(STRING(Buffer), "%sbox%d", Buffer, boxindex);

		Format(STRING(Buffer), "%s%s", Buffer, isBoxEnabled?" ON":" OFF");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(behaviorBitFlags,BEHAVIOR_NO_DAMAGE)?" -DMG":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(behaviorBitFlags,BEHAVIOR_NO_SHOOTING)?" -SHOOT":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(behaviorBitFlags,BEHAVIOR_NO_BUILDINGS)?" -BUILD":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_REDTEAM)?" RED":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_BLUETEAM)?" BLUE":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_SCOUT)?" SCO":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_SNIPER)?" SNI":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_SOLDIER)?" SOL":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_DEMOMAN)?" DEM":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_MEDIC)?" MED":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_HEAVY)?" HEA":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_PYRO)?" PYR":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_SPY)?" SPY":"");

		Format(STRING(Buffer), "%s%s", Buffer, HasBitflags(targetBitFlags,BOX_TARGET_ENGINEER)?" ENG":"");

		SetHudTextParams(-1.0, -1.0, 0.25, 255, 255, 0, 255);
		ShowSyncHudText(xFollowMeClient, ClientNameInfoMessage, Buffer);
	}
}

////////////////////////////////////////////////////////////////////////////////////
// DAMAGE SYSTEM
////////////////////////////////////////////////////////////////////////////////////
public OnEntityCreated(entity, const String:classname[])
{
	if(entity>0 && IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
	}
}
public OnClientPutInServer(client){
	TriggerClientMenu[client]=-1;
	CanDoNoDamage[client]=false;
	NoShooting[client]=false;

	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
}

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype,&weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(ValidPlayer(attacker) && CanDoNoDamage[attacker])
	{
		damage=0.0;
	}
	return Plugin_Changed;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(NoShooting[client])
	{
		static bool:wasdisarmed[MAXPLAYERS + 1];
		if(!wasdisarmed[client]){
			wasdisarmed[client]=true;
			new ent = GetEntDataEnt2(client,m_OffsetActiveWeapon);
			if(ent != -1)
			{
				 SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+0.2);
			}
		}
		else if(wasdisarmed[client]){
			wasdisarmed[client]=false;

			new ent = GetEntDataEnt2(client,m_OffsetActiveWeapon);
			if(ent != -1)
			{
				 SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
			}
		}
	}

	if(NoShooting[client]){ //block attack
		if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
		{
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
		}
	}

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////
// NO BUILD SYSTEM
////////////////////////////////////////////////////////////////////////////////////
public OnBoxCreated(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3])
{
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_BUILDINGS))
	{
		if(HasBitflags(targetBitFlags,BOX_TARGET_REDTEAM))
		{
			SpawnFuncNoBuild(boxindex, 2, BoxMin, BoxMax);
		}
		else if(HasBitflags(targetBitFlags,BOX_TARGET_BLUETEAM))
		{
			SpawnFuncNoBuild(boxindex, 3, BoxMin, BoxMax);
		}
		else
		{
			SpawnFuncNoBuild(boxindex, 0, BoxMin, BoxMax);
		}
	}
}

public OnBoxRemoved(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3])
{
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_BUILDINGS))
	{
		KillNoBuildEntity(boxindex);
	}
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_DAMAGE))
	{
		LoopMaxClients(client)
		{
			CanDoNoDamage[client]=false;
		}
	}
	if(HasBitflags(behaviorBitFlags,BEHAVIOR_NO_SHOOTING))
	{
		LoopMaxClients(client)
		{
			NoShooting[client]=false;
		}
	}
}

stock GetMiddleOfABox(const Float:vec1[3], const Float:vec2[3], Float:buffer[3])
{
	new Float:mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

stock SpawnFuncNoBuild(iZoneIndex, iTeam, Float:fMins[3], Float:fMaxs[3])
{
	new Float:fMiddle[3];

	new iEnt = CreateEntityByName("func_nobuild");

	decl String:sZoneName[32];
	DispatchKeyValue(iEnt, "spawnflags", "64");
	Format(sZoneName, sizeof(sZoneName), "sm_nobuild_%d", iZoneIndex);
	DispatchKeyValue(iEnt, "targetname", sZoneName);

	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	SetEntProp(iEnt, Prop_Data, "m_spawnflags", 64 );

	if(iTeam==2 || iTeam==3)
	{
		SetVariantInt(iTeam);
		AcceptEntityInput(iEnt, "TeamNum", -1, -1, 0);

		SetVariantInt(iTeam);
		AcceptEntityInput(iEnt, "SetTeam", -1, -1, 0);
	}

	GetMiddleOfABox(fMins, fMaxs, fMiddle);

	TeleportEntity(iEnt, fMiddle, NULL_VECTOR, NULL_VECTOR);
	//SetEntityModel(iEnt, "models/items/car_battery01.mdl");
	SetEntityModel(iEnt, g_sPushModel);

	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if(fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if(fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if(fMins[2] > 0.0)
		fMins[2] *= -1.0;

	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if(fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if(fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if(fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;

	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", fMaxs);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);

	new iEffects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
	iEffects |= 32;
	SetEntProp(iEnt, Prop_Send, "m_fEffects", iEffects);

	AcceptEntityInput(iEnt, "SetActive");
}

stock KillNoBuildEntity(iZoneIndex)
{
	decl String:sZoneName[128];
	Format(sZoneName, sizeof(sZoneName), "sm_nobuild_%d", iZoneIndex);

	new iEnts = GetMaxEntities();
	decl String:sClassName[256];
	for(new i=MaxClients+1;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "func_nobuild") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, sZoneName, false))
		{
			AcceptEntityInput(i, "Kill");
			break;
		}
	}
}

public OnBoxChanged(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3], bool:isBoxEnabled)
{
	if(!isBoxEnabled)
	{
		KillNoBuildEntity(boxindex);
		LoopMaxClients(client)
		{
			if(Box_IsPlayerInBox(client,boxindex))
			{
				CanDoNoDamage[client]=false;
				NoShooting[client]=false;
			}
		}
		return;
	}
	if(!HasBitflags(behaviorBitFlags,BEHAVIOR_NO_BUILDINGS))
	{
		KillNoBuildEntity(boxindex);
	}
	else
	{
		if(HasBitflags(targetBitFlags,BOX_TARGET_REDTEAM))
		{
			SpawnFuncNoBuild(boxindex, 2, BoxMin, BoxMax);
		}
		else if(HasBitflags(targetBitFlags,BOX_TARGET_BLUETEAM))
		{
			SpawnFuncNoBuild(boxindex, 3, BoxMin, BoxMax);
		}
		else
		{
			SpawnFuncNoBuild(boxindex, 0, BoxMin, BoxMax);
		}
	}
	if(!HasBitflags(behaviorBitFlags,BEHAVIOR_NO_DAMAGE))
	{
		LoopMaxClients(client)
		{
			if(Box_IsPlayerInBox(client,boxindex))
			{
				CanDoNoDamage[client]=false;
			}
		}
	}
	else
	{
		LoopMaxClients(client)
		{
			if(Box_IsPlayerInBox(client,boxindex))
			{
				CanDoNoDamage[client]=true;
			}
		}
	}
	if(!HasBitflags(behaviorBitFlags,BEHAVIOR_NO_SHOOTING))
	{
		LoopMaxClients(client)
		{
			if(Box_IsPlayerInBox(client,boxindex))
			{
				NoShooting[client]=false;
			}
		}
	}
	else
	{
		LoopMaxClients(client)
		{
			if(Box_IsPlayerInBox(client,boxindex))
			{
				NoShooting[client]=true;
			}
		}
	}
}
