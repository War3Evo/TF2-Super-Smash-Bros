#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sb_interface>
//#tryinclude <DiabloStocks>
#include <sdkhooks>

/*
#if !defined _diablostocks_included
#define STRING(%1) %1, sizeof(%1)

#define LoopIngamePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && !IsFakeClient(%1))

#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))

stock bool ValidPlayer(int client, bool check_alive=false, bool alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}

stock bool IsEntLimitReached()
{
	if (GetEntityCount() >= (GetMaxEntities()-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
		return true;
	}
	else
		return false;
}
#endif*/

new g_FilteredEntity = -1;
new Float:g_ClientPosition[MAXPLAYERS+1][3];

float PlayerMulti[MAXPLAYERS+1];
int reapplyspeed[MAXPLAYERSCUSTOM];
//float gspeedmulti[MAXPLAYERSCUSTOM];
float speedBefore[MAXPLAYERSCUSTOM];
float speedWeSet[MAXPLAYERSCUSTOM];

int m_OffsetSpeed=-1;

Handle g_hName;
Handle g_hPos;
Handle g_hTime;
Handle g_hEntity;

Handle PowerUPMessage;

Handle hItemTimer = null;

bool ItemsLoaded = false;

enum PowerUpType
{
	psmall,
	pmedium,
	pfull
}

PowerUpType pMenuType = pfull;

public Plugin:myinfo =
{
	name = "[TF2] Smash Bros Plugin",
	author = "El Diablo",
	description = "Smash Bros Plugin",
	version = "1.0",
	url = "https://www.war3evo.info"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	PowerUPMessage = CreateHudSynchronizer();

	m_OffsetSpeed=FindSendPropOffs("CTFPlayer","m_flMaxspeed");
	if(m_OffsetSpeed==-1)
	{
		PrintToServer("[Smash Bros] Error finding speed offset.");
	}

	RegAdminCmd("sm_clearitems", ClearItems, ADMFLAG_ROOT);
	RegAdminCmd("sm_loaditems", LoadItems, ADMFLAG_ROOT);
	RegAdminCmd("sm_saveitems", SaveItems, ADMFLAG_ROOT);

	RegAdminCmd("sm_items", Command_ItemMenu, ADMFLAG_ROOT);

	RegAdminCmd("sm_sbammo", SpawnAmmoCommand, ADMFLAG_ROOT);
	RegAdminCmd("sm_sbpower", SpawnHealthCommand, ADMFLAG_ROOT);

	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);

	//HookEntityOutput("item_healthkit_small", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
	//HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
	//HookEntityOutput("item_healthkit_full", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);

	g_hName = CreateArray(ByteCountToCells(64)); //string
	g_hPos = CreateArray(3); //array
	g_hTime = CreateArray(1);
	g_hEntity = CreateArray(1);

	HookEvent("teamplay_round_win", teamplay_round_win);

	CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);
}

public Action:teamplay_round_win(Handle:event,  const String:name[], bool:dontBroadcast) {
	if(hItemTimer == null)
	{
		ClearItems(0, 0);
		ItemsLoaded=false;
		hItemTimer = CreateTimer(1.0, LoadItemsTimer, _);
	}
	else
	{
		KillTimer(hItemTimer);
		ClearItems(0, 0);
		ItemsLoaded=false;
		hItemTimer = CreateTimer(1.0, LoadItemsTimer, _);
	}
}

public OnMapStart()
{
	PrecacheModel("models/props_halloween/halloween_medkit_large.mdl",true);
	PrecacheModel("models/props_halloween/halloween_medkit_medium.mdl",true);
	PrecacheModel("models/props_halloween/halloween_medkit_small.mdl",true);

	if(hItemTimer == null)
	{
		ClearItems(0, 0);
		ItemsLoaded=false;
		hItemTimer = CreateTimer(5.0, LoadItemsTimer, _);
	}
	else
	{
		KillTimer(hItemTimer);
		ClearItems(0, 0);
		ItemsLoaded=false;
		hItemTimer = CreateTimer(5.0, LoadItemsTimer, _);
	}
}

public OnMapEnd()
{
	PrintToServer("ITEMS CLEARED");
	PrintToServer("ITEMS CLEARED");
	PrintToServer("ITEMS CLEARED");
	ClearItems(0, 0);
	ItemsLoaded = false;
}

bool HumansExist()
{
	int countit = 0;
	LoopIngamePlayers(target)
	{
		if(IsPlayerAlive(target))
		{
			countit++;
		}
	}
	return (countit > 0)?true:false;
}

public Action:LoadItemsTimer(Handle:timer)
{
	if(!ItemsLoaded && !SB_GetGamePlaying())
	{
		if(!HumansExist())
		{
			PrintToServer("ITEMS WAITING FOR FIRST ROUND...");
			hItemTimer = CreateTimer(1.0, LoadItemsTimer, _);
			return Plugin_Stop;
		}
	}

	if(ItemsLoaded) return Plugin_Stop;

	ItemsLoaded = true;
	PrintToServer("Loading Items");
	LoadItems(0, 0);

	hItemTimer = null;
	return Plugin_Stop;
}

//bool ignoreNextEntity = false;
/*
public OnEntityCreated(entity, const String:classname[])
{
	if(ignoreNextEntity) {
			ignoreNextEntity = false;
			LogMessage("Ignored entity");
			return;
	}

	char model[128];

	if(StrEqual(classname, "item_healthkit_full")) {
			Format(model, sizeof(model), "models/props_halloween/halloween_medkit_large.mdl");
	} else if(StrEqual(classname, "item_healthkit_medium")) {
			Format(model, sizeof(model), "models/props_halloween/halloween_medkit_medium.mdl");
	} else if(StrEqual(classname, "item_healthkit_small")) {
			Format(model, sizeof(model), "models/props_halloween/halloween_medkit_small.mdl");
	} else {
			return; // not a healthpack
	}

	new Float:pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	AcceptEntityInput(entity, "kill");

	int ArrayPos = FindValueInArray(g_hEntity, entity);
	if(ArrayPos > -1)
	{
		// remove old g_hEntity
		SetArrayCell(g_hEntity, ArrayPos, 0);
	}

	ignoreNextEntity = true;
	entity = CreateEntityByName(classname);
	DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
	DispatchKeyValue(entity, "powerup_model", model);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", 0, 4);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

	if(ArrayPos > -1)
	{
		// set new g_hEntity
		SetArrayCell(g_hEntity, ArrayPos, entity);
	}

	if(StrEqual(classname, "item_healthkit_full"))
		SDKHook(entity, SDKHook_StartTouchPost, OnHealthTouched);
	else if(StrEqual(classname, "item_healthkit_medium"))
		SDKHook(entity, SDKHook_StartTouchPost, OnHealthTouched);
	else if(StrEqual(classname, "item_healthkit_small"))
		SDKHook(entity, SDKHook_StartTouchPost, OnHealthTouched);
}*/

public Action:ClearItems(client, args)
{
	// remove all items first
	int ent = -1;

	for(int ArrayPos=0; ArrayPos < GetArraySize(g_hEntity); ArrayPos++)
	{
		ent = GetArrayCell(g_hEntity, ArrayPos);
		if (ent > -1 && IsValidEdict(ent))
		{
			//RemoveEdict(ent); <-- isn't safe according to someone in sourcemod
			AcceptEntityInput(ent, "Kill");
		}
	}

	ClearArray(g_hName);
	ClearArray(g_hPos);
	ClearArray(g_hTime);
	ClearArray(g_hEntity);

	LoopAlivePlayers(target)
	{
		TF2_RegeneratePlayer(target);
	}

	return Plugin_Handled;
}

public Action:LoadItems(client, args)
{
	if(client)
	{
		PrintToChat(client,"LoadItems");
	}

	char path[1024];
	char mapname[1024];
	char mappath[1024];

	GetCurrentMap(STRING(mapname));

	Format(STRING(mappath), "configs/sb_items_%s.cfg", mapname);

	BuildPath(Path_SM,path,sizeof(path),mappath);

	if(!FileExists(path))
	{
		PrintToServer("Could Not Find items: %s",path);

		if(client)
		{
			PrintToChat(client,"smash bros item configuration file\n%s\nDoes not exist!",path);
		}
		return Plugin_Handled;
	}

	PrintToServer("ITEMS: %s",path);

	/* Return true if an update was available. */
	Handle kv = CreateKeyValues("TF2_SB_ITEMS");

	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		return Plugin_Handled;
	}

	if(client)
	{
		PrintToChat(client,"Loading from %s",path);
	}

	PrintToServer("LOADING MAP ITEMS...");

	//PrintToChatAll("TF2_SB_ITEMS %s",path);

	KvRewind(kv);

	ClearItems(0, 0);

	PrintToServer("INIT ITEMS DATA...");

	//PrintToChatAll("ClearArray");

	new String:name[64];
	new Float:ItemPos[3];

	int ArraySz = -1;

	decl String:sSectionBuffer[32];
	decl String:sSubKeyBuffer[32];

	PrintToServer("REGISTERING ITEMS DATA...");

	do
	{
		// You can read the section/key name by using KvGetSectionName here.
		//PrintToChatAll("do loop\n");

		if (KvGotoFirstSubKey(kv, false))
		{
			do
			{
				if(KvGetSectionName(kv, sSectionBuffer, sizeof(sSectionBuffer)))
				{
					//PrintToChatAll(sSectionBuffer);

					if (KvGotoFirstSubKey(kv, false))
					{
						// Current key is a section. Browse it recursively.
						do
						{
							if(KvGetSectionName(kv, sSubKeyBuffer, sizeof(sSubKeyBuffer)))
							{
								//PrintToChatAll("sSubSectionBuffer %s", sSubKeyBuffer);

								if(StrEqual(sSubKeyBuffer,"name"))
								{
									PrintToServer("REGISTERING: %s",name);
									KvGetString(kv, NULL_STRING, STRING(name));
									//PrintToChatAll("name: %s",name);
								}
								else if(StrEqual(sSubKeyBuffer,"pos0"))
								{
									ItemPos[0] = KvGetFloat(kv, NULL_STRING);
									//PrintToChatAll("pos0: %.2f",ItemPos[0]);
								}
								else if(StrEqual(sSubKeyBuffer,"pos1"))
								{
									ItemPos[1] = KvGetFloat(kv, NULL_STRING);
									//PrintToChatAll("pos1: %.2f",ItemPos[1]);
								}
								else if(StrEqual(sSubKeyBuffer,"pos2"))
								{
									ItemPos[2] = KvGetFloat(kv, NULL_STRING);
									//PrintToChatAll("pos2: %.2f",ItemPos[2]);
								}
							}
						} while (KvGotoNextKey(kv, false));
						KvGoBack(kv);

						// save to array
						//PrintToChatAll("%s %.2f %.2f %.2f %s loaded.",TmpStr,ItemPos[0],ItemPos[1],ItemPos[2],name);

						PushArrayString(g_hName, name);
						PushArrayArray(g_hPos, ItemPos);
						PushArrayCell(g_hTime, 0); // 0 = not picked up yet
						PushArrayCell(g_hEntity, 0);

						ArraySz = GetArraySize(g_hName) - 1;

						//PrintToChatAll("GetArraySize %d",ArraySz);

						TF_CreateItem(ArraySz);
					}
				}
				//if(found) found = false;
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}
		//if(found) found = false;
	} while (KvGotoNextKey(kv, false));

	CloseHandle(kv);

	PrintToServer("ITEM DATA FINISHED");

	//PrintToChatAll("CloseHandle");

	return Plugin_Handled;
}

public Action:SaveItems(client, args)
{
	char path[1024];
	char mapname[1024];
	char mappath[1024];
	char TmpStr[64];

	GetCurrentMap(STRING(mapname));

	Format(STRING(mappath), "configs/sb_items_%s.cfg", mapname);

	BuildPath(Path_SM,path,sizeof(path),mappath);

	if(FileExists(path))
	{
		DeleteFile(path);
	}

	if(client)
	{
		PrintToChat(client,"Saving to %s",path);
	}

	/* Return true if an update was available. */
	Handle kv = CreateKeyValues("TF2_SB_ITEMS");

	new String:name[64];
	new Float:ItemPos[3];

	for(int ArrayPos=0; ArrayPos < GetArraySize(g_hName); ArrayPos++)
	{
		Format(STRING(TmpStr), "item%d", ArrayPos);
		KvJumpToKey(kv, TmpStr, true);

		GetArrayString(g_hName, ArrayPos, STRING(name));
		GetArrayArray(g_hPos, ArrayPos, ItemPos);

		KvSetString(kv, "name", name);
		KvSetFloat(kv, "pos0", ItemPos[0]);
		KvSetFloat(kv, "pos1", ItemPos[1]);
		KvSetFloat(kv, "pos2", ItemPos[2]);

		KvGoBack(kv);

		//DP("%s %s saved.",TmpStr,name);
	}

	KvRewind(kv);
	KeyValuesToFile(kv, path);
	CloseHandle(kv);

	return Plugin_Handled;
}

public Action:Timer_Caching(Handle:timer)
{
	int mintime = GetTime();
	for(int ArrayPos=0; ArrayPos < GetArraySize(g_hName); ArrayPos++)
	{
		int time = GetArrayCell(g_hTime, ArrayPos);
		if (time > 0 && time < mintime)
		{
			TF_CreateItem(ArrayPos);
		}
	}
}

public Action:SpawnHealthCommand(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_sbpower <full / medium / small>");
		return Plugin_Handled;
	}
	if (client < 1)
	{
		ReplyToCommand(client, "This command must be used ingame");
		return Plugin_Handled;
	}


	decl String:buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));

	if (StrEqual(buffer, "full", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Full\x01 power pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Full power pack.", client);
		TF_SpawnItem(client, "item_healthkit_full", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "medium", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Medium\x01 power pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Medium power pack.", client);
		TF_SpawnItem(client, "item_healthkit_medium", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "small", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Small\x01 power pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Small power pack.", client);
		TF_SpawnItem(client, "item_healthkit_small", true);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Usage: sm_sbpower <full / medium / small>");
	return Plugin_Handled;
}

public Action:SpawnAmmoCommand(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_sbammo <full / medium / small>");
		return Plugin_Handled;
	}
	if (client < 1)
	{
		ReplyToCommand(client, "This command must be used ingame");
		return Plugin_Handled;
	}


	decl String:buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));

	if (StrEqual(buffer, "full", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Full\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Full ammo pack.", client);
		TF_SpawnItem(client, "item_ammopack_full", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "medium", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Medium\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Medium ammo pack.", client);
		TF_SpawnItem(client, "item_ammopack_medium", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "small", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Small\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Small ammo pack.", client);
		TF_SpawnItem(client, "item_ammopack_small", true);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Usage: sm_spawnammo <full / medium / small>");
	return Plugin_Handled;
}

stock TF_SpawnItem(client, String:name[], bool:cmd)
{
	new Float:PlayerPosition[3];
	if (cmd)
		GetClientAbsOrigin(client, PlayerPosition);
	else
		PlayerPosition = g_ClientPosition[client];

	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		if (cmd)
		{
			new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

			new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, ItempackTraceFilter);
			TR_GetEndPosition(PlayerPosition, TraceEx);
			CloseHandle(TraceEx);
		}

		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, ItempackTraceFilter);

		new Float:ItemPos[3];
		TR_GetEndPosition(ItemPos, Trace);
		CloseHandle(Trace);
		ItemPos[2] += 4;

		int Itempack;

		if(StrContains(name,"health") > -1)
		{
			Itempack = CreateEntityByName("prop_dynamic");

			if(StrEqual(name, "item_healthkit_full")) {
					SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_large.mdl");
			} else if(StrEqual(name, "item_healthkit_medium")) {
					SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_medium.mdl");
			} else if(StrEqual(name, "item_healthkit_small")) {
					SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_small.mdl");
			}
			if (DispatchSpawn(Itempack))
			{
				AcceptEntityInput( Itempack, "DisableCollision" );
				AcceptEntityInput( Itempack, "EnableCollision" );

				TeleportEntity(Itempack, ItemPos, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(Itempack, MOVETYPE_NONE);

				PushArrayString(g_hName, name);
				PushArrayArray(g_hPos, ItemPos);
				PushArrayCell(g_hTime, 0); // 0 = not picked up yet
				PushArrayCell(g_hEntity, Itempack);

				SDKHook(Itempack, SDKHook_Touch, OnHealthTouched);
			}
		}
		else
		{
			Itempack = CreateEntityByName(name);
			DispatchKeyValue(Itempack, "OnPlayerTouch", "!self,Kill,,0,-1");
			if (DispatchSpawn(Itempack))
			{
				new team = 0;
				SetEntProp(Itempack, Prop_Send, "m_iTeamNum", team, 4);
				TeleportEntity(Itempack, ItemPos, NULL_VECTOR, NULL_VECTOR);

				PushArrayString(g_hName, name);
				PushArrayArray(g_hPos, ItemPos);
				PushArrayCell(g_hTime, 0); // 0 = not picked up yet
				PushArrayCell(g_hEntity, Itempack);
			}

		}
	}
}

stock TF_CreateItem(ArrayPos)
{
	new String:name[64];
	GetArrayString(g_hName, ArrayPos, STRING(name));

	new Float:ItemPos[3];
	GetArrayArray(g_hPos, ArrayPos, ItemPos);


	int Itempack;

	if(StrContains(name,"health") > -1)
	{
		Itempack = CreateEntityByName("prop_dynamic");

		if(StrEqual(name, "item_healthkit_full")) {
				SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_large.mdl");
		} else if(StrEqual(name, "item_healthkit_medium")) {
				SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_medium.mdl");
		} else if(StrEqual(name, "item_healthkit_small")) {
				SetEntityModel(Itempack, "models/props_halloween/halloween_medkit_small.mdl");
		}
		if (DispatchSpawn(Itempack))
		{
			AcceptEntityInput( Itempack, "DisableCollision" );
			AcceptEntityInput( Itempack, "EnableCollision" );

			TeleportEntity(Itempack, ItemPos, NULL_VECTOR, NULL_VECTOR);
			SetEntityMoveType(Itempack, MOVETYPE_NONE);

			SetArrayCell(g_hTime, ArrayPos, 0); // 0 = not picked up yet
			SetArrayCell(g_hEntity, ArrayPos, Itempack);

			SDKHook(Itempack, SDKHook_Touch, OnHealthTouched);
		}
	}
	else
	{
		Itempack = CreateEntityByName(name);
		DispatchKeyValue(Itempack, "OnPlayerTouch", "!self,Kill,,0,-1");
		if (DispatchSpawn(Itempack))
		{
			new team = 0;
			SetEntProp(Itempack, Prop_Send, "m_iTeamNum", team, 4);
			TeleportEntity(Itempack, ItemPos, NULL_VECTOR, NULL_VECTOR);

			SetArrayCell(g_hTime, ArrayPos, 0); // 0 = not picked up yet
			SetArrayCell(g_hEntity, ArrayPos, Itempack);
		}

	}
/*
	int Itempack = CreateEntityByName(name);
	DispatchKeyValue(Itempack, "OnPlayerTouch", "!self,Kill,,0,-1");
	if (DispatchSpawn(Itempack))
	{
		int team = 0;
		SetEntProp(Itempack, Prop_Send, "m_iTeamNum", team, 4);
		TeleportEntity(Itempack, ItemPos, NULL_VECTOR, NULL_VECTOR);

		SetArrayCell(g_hTime, ArrayPos, 0); // 0 = not picked up yet
		SetArrayCell(g_hEntity, ArrayPos, Itempack);
	}*/
}

public bool:ItempackTraceFilter(ent, contentMask)
{
	return (ent != g_FilteredEntity);
}

//public OnHealthTouched(entity)
public void OnHealthTouched (int entity, int other)
{
	if(IsValidEdict(entity) && ValidPlayer(other,true))
	{
		new String:modelname[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);

		//PrintToChatAll("model name: %s",modelname);

		//new String:classname[64];
		//GetEdictClassname(entity, classname, 64);

		//if (!strncmp(classname, "item_healthkit", 14))
		//{
		if(StrContains(modelname,"small") > -1)
		{
			//if(SB_GetPlayerProp(other,iDamage)>0)
			//{
				//int CurrentDamage = SB_GetPlayerProp(other,iDamage);
				//int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.25));
				//CurrentDamage -= ReduceDamageBy;
				//if(CurrentDamage<0) CurrentDamage = 0;
				//SB_SetPlayerProp(other,iDamage,CurrentDamage);

			RandomPowerUp(other,psmall);

			MyOwnHandler(entity);
			AcceptEntityInput(entity, "Kill");
			//}
			//OnGiftBreak(NULL_STRING, entity, other, 0.0);
		}
		else if(StrContains(modelname,"medium") > -1) // if(StrEqual("item_healthkit_medium",classname))
		{
			//if(SB_GetPlayerProp(other,iDamage)>0)
			//{
				//int CurrentDamage = SB_GetPlayerProp(other,iDamage);
				//int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.50));
				//CurrentDamage -= ReduceDamageBy;
				//if(CurrentDamage<0) CurrentDamage = 0;
				//SB_SetPlayerProp(other,iDamage,CurrentDamage);

			RandomPowerUp(other,pmedium);

			MyOwnHandler(entity);
			AcceptEntityInput(entity, "Kill");
			//}
			//OnGiftBreak(NULL_STRING, entity, other, 0.0);
		}
		else if(StrContains(modelname,"large") > -1) // if(StrEqual("item_healthkit_full",classname))
		{
			//if(SB_GetPlayerProp(other,iDamage)>0)
			//{
				//int CurrentDamage = SB_GetPlayerProp(other,iDamage);
				//int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.75));
				//CurrentDamage -= ReduceDamageBy;
				//if(CurrentDamage<0) CurrentDamage = 0;
				//SB_SetPlayerProp(other,iDamage,CurrentDamage);

			RandomPowerUp(other,pfull);

			MyOwnHandler(entity);
			AcceptEntityInput(entity, "Kill");
			//}
			//OnGiftBreak(NULL_STRING, entity, other, 0.0);
		}
			//else if(StrEqual("halloween_medkit_small",classname))
			//{
			//}
			//else if(StrEqual("halloween_medkit_medium",classname))
			//{
			//}
			//else if(StrEqual("halloween_medkit_full",classname))
			//{
			//}
		//}
	}
}

public Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	//MyOwnHandler(caller, activator);
	MyOwnHandler(caller);
}

MyOwnHandler(caller)
{
	int ArrayPos = FindValueInArray(g_hEntity, caller);
	if(ArrayPos > -1)
	{
		// set time from pickup
		SetArrayCell(g_hTime, ArrayPos, (GetTime()+30));
	}
}

/*
MyOwnHandler(caller, activator)
{
	//DP("Output: [%s]",output);
	int time = GetArrayCell(g_hTime, caller);
	if (time > 0 && activator > 0)
	{

		if (IsValidEdict(caller) && ValidPlayer(activator) && !IsFakeClient(activator))
		{
			new W3DropItemProperties:DropItem = W3DropItemProperties:GetArrayCell(g_DropItemTime2, caller);
			new XP=0,GOLD=0,PLATINUM=0;
			new client=activator;
			new RaceID=War3_GetRace(client);
			new String:sClientName[128];
			GetClientName(client,sClientName,sizeof(sClientName));
			//if(DropItem==Gold_Green_Money)
				//DP("Gold_Green_Money");
			new String:classname[64];
			GetEdictClassname(caller, classname, 64);
			if (!strncmp(classname, "item_ammopack", 13))
			{
				//DP("item_ammopack");
			}
			if (!strncmp(classname, "item_healthkit", 14))
			{
				//DP("item_healthkit");
				if(StrEqual("item_healthkit_small",classname))
				{
					if(DropItem==Black_Cloak_Item)
					{
						Cloak(client);
						War3_ChatMessage(client,"%s found a bottle of {lightgreen}dark liquor!",sClientName);
						Log("%s found a bottle of dark liquor!",sClientName);
					}
					else if(DropItem==Blue_Armor_Item)
					{
						Armor(client);
						War3_ChatMessage(client,"%s found a bottle of {lightgreen}stone skin!",sClientName);
						Log("%s found a bottle of stone skin!",sClientName);
					}
					else if(DropItem==Purple_Gravity_Item)
					{
						Gravity(client);
						War3_ChatMessage(client,"%s found some {lightgreen}weight loss pills!",sClientName);
						Log("%s found some weight loss pills!",sClientName);
					}
				}
			}
			if (!strncmp(classname, "item_currencypack", 17))
			{
				//DP("item_currencypack");
				if(StrEqual("item_currencypack_small",classname))
				{
					if(DropItem==Gold_Money)
					{
						XP=0;
						GOLD=1;
						W3GiveXPGold(client,XPAwardByGeneric,XP,GOLD,"picking up small amount of gold");
						//War3_ChatMessage(client,"%s found some small {lightgreen}Gold Cash!",sClientName);
						Log("%s found some small Gold Cash!",sClientName);
					}
					else if(DropItem==Platinum_Money)
					{
						XP=0;
						GOLD=0;
						PLATINUM=GetRandomInt(1, 10);
						LoopTeamPlayers(client,target)
						{
							decl String:sMyBuffer[192];
							Format(STRING(sMyBuffer),"%s picking up small amount of platinum",XPAwardByGeneric,sClientName);
							W3GiveXP_Platinum(target,RaceID,PLATINUM,sMyBuffer);
						}
						War3_ChatMessage(0,"%s found some small {lightgreen}Platinum!",sClientName);
						Log("%s found some small Platinum!",sClientName);
					}
				}
				if(StrEqual("item_currencypack_medium",classname))
				{
					if(DropItem==Gold_Money)
					{
						XP=0;
						GOLD=2;
						W3GiveXPGold(client,XPAwardByGeneric,XP,GOLD,"picking up medium amount of gold");
						War3_ChatMessage(0,"%s found some medium {lightgreen}Gold!",sClientName);
						Log("%s found some medium Gold!",sClientName);
					}
					else if(DropItem==Platinum_Money)
					{
						XP=0;
						GOLD=0;
						PLATINUM=GetRandomInt(10, 25);
						LoopTeamPlayers(client,target)
						{
							decl String:sMyBuffer[192];
							Format(STRING(sMyBuffer),"%s picking up medium amount of platinum",XPAwardByGeneric,sClientName);
							W3GiveXP_Platinum(target,RaceID,PLATINUM,sMyBuffer);
						}
						War3_ChatMessage(0,"%s found some medium {lightgreen}Platinum!",sClientName);
						Log("%s found some medium Platinum!",sClientName);
					}
				}
				if(StrEqual("item_currencypack_large",classname))
				{
					if(DropItem==Gold_Money)
					{
						XP=0;
						GOLD=3;
						W3GiveXPGold(client,XPAwardByGeneric,XP,GOLD,"picking up large amount of gold");
						War3_ChatMessage(client,"%s found some large {lightgreen}Gold!",sClientName);
						Log("%s found some large Gold!",sClientName);
					}
					else if(DropItem==Platinum_Money)
					{
						XP=0;
						GOLD=0;
						PLATINUM=GetRandomInt(25, 50);
						LoopTeamPlayers(client,target)
						{
							decl String:sMyBuffer[192];
							Format(STRING(sMyBuffer),"%s picking up large amount of platinum",XPAwardByGeneric,sClientName);
							W3GiveXP_Platinum(target,RaceID,PLATINUM,sMyBuffer);
						}
						War3_ChatMessage(0,"%s found some large {lightgreen}Platinum!",sClientName);
						Log("%s found some large Platinum!",sClientName);
					}
				}
			}
		}

		SetArrayCell(g_DropItemTime, caller, 0);
		SetArrayCell(g_DropItemTime2, caller, 0);
		g_DropItemCount--;
	}
}
*/

stock PosMsg(client, char sMsg[256], float TimeAmount)
{
	SetHudTextParams(-1.0, 0.15, TimeAmount, 0, 255, 0, 200);
	ShowSyncHudText(client, PowerUPMessage, sMsg);
	PrintToChat(client,sMsg);
}

stock NegMsg(client, char sMsg[256], float TimeAmount)
{
	SetHudTextParams(-1.0, 0.20, TimeAmount, 255, 0, 0, 200);
	ShowSyncHudText(client, PowerUPMessage, sMsg);
	PrintToChat(client,sMsg);
}

public Action:StopSpeedTimer(Handle:timer,any:userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		PlayerMulti[client]=0.0;
		reapplyspeed[client]++;
	}
}

public RandomPowerUp(client, PowerUpType:pUP)
{
	//
	//PowerUPMessage
	//SetHudTextParams(-1.0, -1.0, 3.0, 0, 255, 0, 200); //green
	//ShowSyncHudText(client, CountDownTimerMessage, "Time %d:%d",Minutes,Seconds);

	int RandNumber = GetRandomInt(1, 120);
	//int RandNumber = 110;

	// TFCond_CritCola - mini crits
	if(RandNumber >= 1 && RandNumber < 20)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_CritCola, 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_CritCola, 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_CritCola, 8.0);
			}
		}
	}
	// TFCond_Ubercharged
	else if(RandNumber >= 20 && RandNumber < 40)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_Ubercharged, 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_Ubercharged, 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_Ubercharged, 8.0);
			}
		}
	}
	// TFCond_MarkedForDeath
	else if(RandNumber >= 40 && RandNumber < 45)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_MarkedForDeath, 4.0);
				NegMsg(client, "[Marked for Death] 4 seconds", 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_MarkedForDeath, 6.0);
				NegMsg(client, "[Marked for Death] 6 seconds", 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_MarkedForDeath, 8.0);
				NegMsg(client, "[Marked for Death] 8 seconds", 8.0);
			}
		}
	}
	// TFCond_Cloaked
	else if(RandNumber >= 45 && RandNumber < 55)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_Stealthed, 4.0);
				PosMsg(client, "[Stealth] 4 seconds", 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_Stealthed, 6.0);
				PosMsg(client, "[Stealth] 6 seconds", 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_Stealthed, 8.0);
				PosMsg(client, "[Stealth] 8 seconds", 8.0);
			}
		}
	}
	// Slowed
	else if(RandNumber >= 55 && RandNumber < 60)
	{
		switch (pUP)
		{
			case psmall:
			{
				PlayerMulti[client]=0.6;
				reapplyspeed[client]++;
				PosMsg(client, "[Slowed] 4 seconds", 4.0);
				CreateTimer(4.0, StopSpeedTimer, GetClientUserId(client));
			}
			case pmedium:
			{
				PlayerMulti[client]=0.6;
				reapplyspeed[client]++;
				PosMsg(client, "[Slowed] 6 seconds", 6.0);
				CreateTimer(6.0, StopSpeedTimer, GetClientUserId(client));
			}
			case pfull:
			{
				PlayerMulti[client]=0.6;
				reapplyspeed[client]++;
				PosMsg(client, "[Slowed] 8 seconds", 8.0);
				CreateTimer(8.0, StopSpeedTimer, GetClientUserId(client));
			}
		}
	}
	// TFCond_Kritzkrieged - full crits
	else if(RandNumber >= 60 && RandNumber < 80)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_Kritzkrieged, 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_Kritzkrieged, 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_Kritzkrieged, 8.0);
			}
		}
	}
	// TFCond_Milked
	else if(RandNumber >= 80 && RandNumber < 85)
	{
		switch (pUP)
		{
			case psmall:
			{
				TF2_AddCondition(client, TFCond_Milked, 4.0);
				NegMsg(client, "[Milked] 4 seconds", 4.0);
			}
			case pmedium:
			{
				TF2_AddCondition(client, TFCond_Milked, 6.0);
				NegMsg(client, "[Milked] 6 seconds", 6.0);
			}
			case pfull:
			{
				TF2_AddCondition(client, TFCond_Milked, 8.0);
				NegMsg(client, "[Milked] 8 seconds", 8.0);
			}
		}
	}
	// Heals Percentage
	else if(RandNumber >= 85 && RandNumber < 100)
	{
		switch (pUP)
		{
			case psmall:
			{
				if(SB_GetPlayerProp(client,iDamage)>0)
				{
					int CurrentDamage = SB_GetPlayerProp(client,iDamage);
					int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.25));
					CurrentDamage -= ReduceDamageBy;
					if(CurrentDamage<0) CurrentDamage = 0;
					SB_SetPlayerProp(client,iDamage,CurrentDamage);
				}

				PosMsg(client, "Reduced Percentage by 25%", 5.0);
			}
			case pmedium:
			{
				if(SB_GetPlayerProp(client,iDamage)>0)
				{
					int CurrentDamage = SB_GetPlayerProp(client,iDamage);
					int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.50));
					CurrentDamage -= ReduceDamageBy;
					if(CurrentDamage<0) CurrentDamage = 0;
					SB_SetPlayerProp(client,iDamage,CurrentDamage);
				}

				PosMsg(client, "Reduced Percentage by 50%", 5.0);
			}
			case pfull:
			{
				if(SB_GetPlayerProp(client,iDamage)>0)
				{
					int CurrentDamage = SB_GetPlayerProp(client,iDamage);
					int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.75));
					CurrentDamage -= ReduceDamageBy;
					if(CurrentDamage<0) CurrentDamage = 0;
					SB_SetPlayerProp(client,iDamage,CurrentDamage);
				}

				PosMsg(client, "Reduced Percentage by 75%", 5.0);
			}
		}
	}
	// Speedy
	else if(RandNumber >= 100 && RandNumber < 121)
	{
		switch (pUP)
		{
			case psmall:
			{
				PlayerMulti[client]=1.4;
				reapplyspeed[client]++;
				NegMsg(client, "[Speedy] 4 seconds", 4.0);
				CreateTimer(4.0, StopSpeedTimer, GetClientUserId(client));
			}
			case pmedium:
			{
				PlayerMulti[client]=1.4;
				reapplyspeed[client]++;
				NegMsg(client, "[Speedy] 6 seconds", 6.0);
				CreateTimer(6.0, StopSpeedTimer, GetClientUserId(client));
			}
			case pfull:
			{
				PlayerMulti[client]=1.4;
				reapplyspeed[client]++;
				NegMsg(client, "[Speedy] 8 seconds", 8.0);
				CreateTimer(8.0, StopSpeedTimer, GetClientUserId(client));
			}
		}
	}
}


//public OnGiftBreak(const String:output[], caller, activator, Float:delay)
//{
	//UnhookSingleEntityOutput(caller, "OnBreak", OnGiftBreak);
	//AcceptEntityInput(caller,"kill");
//}
public Action:Command_ItemMenu(client, args)
{
	ItemMenu(client);
	return Plugin_Handled;
}

stock ItemMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandle_ItemMenu);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitBackButton(hMenu, false);
	SetMenuExitButton(hMenu, true);
	SetMenuTitle(hMenu,"SPAWN ITEMS Main Menu:");

	if(pMenuType == pfull)
	{
		AddMenuItem(hMenu,"1","Spawn Type (toggle): Full",ITEMDRAW_DEFAULT);
	}
	else if(pMenuType == pmedium)
	{
		AddMenuItem(hMenu,"1","Spawn Type (toggle): Medium",ITEMDRAW_DEFAULT);
	}
	else if(pMenuType == psmall)
	{
		AddMenuItem(hMenu,"1","Spawn Type (toggle): Small",ITEMDRAW_DEFAULT);
	}
	AddMenuItem(hMenu,"2","Spawn Ammo",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"3","Spawn Powerup",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"4","",ITEMDRAW_SPACER);
	AddMenuItem(hMenu,"5","Save To Disk",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"6","",ITEMDRAW_SPACER);
	AddMenuItem(hMenu,"7","Load from Disk",ITEMDRAW_DEFAULT);
	AddMenuItem(hMenu,"8","",ITEMDRAW_SPACER);
	AddMenuItem(hMenu,"9","Reset All",ITEMDRAW_DEFAULT);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandle_ItemMenu(Handle:hMenu, MenuAction:action, param1, selection)
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
						if(pMenuType == psmall)
						{
							pMenuType = pmedium;
						}
						else if(pMenuType == pmedium)
						{
							pMenuType = pfull;
						}
						else if(pMenuType == pfull)
						{
							pMenuType = psmall;
						}
					}
					case 2:
					{
						if (pMenuType == pfull)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Full\x01 ammo pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Full ammo pack.", client);
							TF_SpawnItem(client, "item_ammopack_full", true);
						}
						else if (pMenuType == pmedium)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Medium\x01 ammo pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Medium ammo pack.", client);
							TF_SpawnItem(client, "item_ammopack_medium", true);
						}
						else if (pMenuType == psmall)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Small\x01 ammo pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Small ammo pack.", client);
							TF_SpawnItem(client, "item_ammopack_small", true);
						}
					}
					case 3:
					{
						if (pMenuType == pfull)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Full\x01 power pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Full power pack.", client);
							TF_SpawnItem(client, "item_healthkit_full", true);
						}
						else if (pMenuType == pmedium)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Medium\x01 power pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Medium power pack.", client);
							TF_SpawnItem(client, "item_healthkit_medium", true);
						}
						else if (pMenuType == psmall)
						{
							ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Small\x01 power pack!", client);
							LogAction(client, -1, "[Ammo] %L spawned a Small power pack.", client);
							TF_SpawnItem(client, "item_healthkit_small", true);
						}
					}
					case 5:
					{
						// save to disk
						SaveItems(client,0);
					}
					case 7:
					{
						// load from disk
						LoadItems(client,0);
					}
					case 9:
					{
						// reset all
						ClearItems(client,0);
					}
				}
				ItemMenu(client);
			}
		}
	case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}

public OnGameFrame()
{
	if(m_OffsetSpeed==-1) return;
	LoopAlivePlayers(client)
	{
		// Player Run Speed Settings
		float currentmaxspeed=GetEntDataFloat(client,m_OffsetSpeed);
		if(currentmaxspeed!=speedWeSet[client]) //SO DID engine set a new speed? copy that!!
		{
			speedBefore[client]=currentmaxspeed;
			reapplyspeed[client]++;
		}
		if(reapplyspeed[client]>0)
		{
			reapplyspeed[client]=0;
			float speedmulti=1.0;
			//gspeedmulti[client]=speedmulti; // used for display only / future use
			if(PlayerMulti[client]>0.0)
			{
				speedmulti=PlayerMulti[client];
			}
			float newmaxspeed=FloatMul(speedBefore[client],speedmulti);
			if(newmaxspeed<0.1){
				newmaxspeed=0.1;
			}
			speedWeSet[client]=newmaxspeed;
			SetEntDataFloat(client,m_OffsetSpeed,newmaxspeed,true);
		}
	}
}
