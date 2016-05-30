//SB_Engine_Weapon_Manager.sp

#include <tf2attributes>
#include <tf2items>

#define LoopMaxWeapons(%1) for(new %1=0;%1<=7;++%1)

//#define LoopMaxClients(%1) for(new %1=1;%1<=MaxClients;++%1)


// TF2 Weapon Loadout Slots
/* tf2_stocks
enum
{
	TFWeaponSlot_Primary,
	TFWeaponSlot_Secondary,
	TFWeaponSlot_Melee,
	TFWeaponSlot_Grenade,
	TFWeaponSlot_Building,
	TFWeaponSlot_PDA,
	TFWeaponSlot_Item1,
	TFWeaponSlot_Item2
};
*
*
			if(GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") != (42 || 159 || 311 || 433 || 863 || 1002) )
			//Can you eat it? If not get rid of it//
			{
			    TF2_RemoveWeaponSlot(client, 1);
			}

*/

Handle sb_weapon_enabled;

public void SB_Engine_Weapon_Manager_SB_Engine_InitNatives()
{
	CreateNative("SB_ApplyWeapons",Native_SB_ApplyWeapons);
}

Handle h_index = null;
Handle h_Old_Weapon_String = null;
Handle h_New_Weapon_String = null;
Handle h_ForceWeaponActive = null;
Handle h_WeaponIndex = null;
Handle h_WeaponLevel = null;
Handle h_WeaponQuality = null;
Handle h_WeaponAttribute = null;
Handle h_WeaponAmmo1 = null;
Handle h_WeaponAmmo2 = null;
Handle h_WeaponAmmo3 = null;
Handle h_WeaponClip1 = null;
Handle h_WeaponClip2 = null;
Handle h_WeaponClip3 = null;


Handle h_Block_list = null;

public void SB_Engine_Weapon_Manager_SB_001_CreateConVar()
{
	sb_weapon_enabled = CreateConVar("sb_weapon_enabled", "1", "0 - disable, 1 - enable", FCVAR_PLUGIN);
}

public void SB_Engine_Weapon_Manager_SB_001_RegConsoleCmd()
{
	RegAdminCmd("reloadcfg", SB_TESTING_CONFIG, ADMFLAG_ROOT);
	RegAdminCmd("reloadswitcher", SB_WEAPON_SWITCHER_CONFIG, ADMFLAG_ROOT);
}

public SB_Engine_Weapon_Manager_OnPluginStart()
{
	h_index = CreateArray(1);
	h_Old_Weapon_String = CreateArray(ByteCountToCells(64));
	h_New_Weapon_String = CreateArray(ByteCountToCells(64));
	h_ForceWeaponActive = CreateArray(1);
	h_WeaponIndex = CreateArray(1);
	h_WeaponLevel = CreateArray(1);
	h_WeaponQuality = CreateArray(1);
	h_WeaponAttribute = CreateArray(ByteCountToCells(64));

	h_WeaponAmmo1 = CreateArray(1);
	h_WeaponClip1 = CreateArray(1);

	h_WeaponAmmo2 = CreateArray(1);
	h_WeaponClip2 = CreateArray(1);

	h_WeaponAmmo3 = CreateArray(1);
	h_WeaponClip3 = CreateArray(1);

	h_Block_list = CreateArray(ByteCountToCells(64));


	Handle kv = PrePareTheFile();
	if(kv != null)
	{
		ClearArray(h_index);
		ClearArray(h_Old_Weapon_String);
		ClearArray(h_New_Weapon_String);
		ClearArray(h_ForceWeaponActive);
		ClearArray(h_WeaponIndex);
		ClearArray(h_WeaponLevel);
		ClearArray(h_WeaponQuality);
		ClearArray(h_WeaponAttribute);
		ClearArray(h_WeaponAmmo1);
		ClearArray(h_WeaponAmmo2);
		ClearArray(h_WeaponAmmo3);
		ClearArray(h_WeaponClip1);
		ClearArray(h_WeaponClip2);
		ClearArray(h_WeaponClip3);
		ClearArray(h_index);
		LoadWeaponSwitchingValues(kv);
		CloseTheFile(kv);
	}
}

//StringToInt

//h_Old_Weapon_String
public int Switcher_GetWeapon(Handle hString, char [] WeaponString, int iItemDefinitionIndex)
{
	int MainIndex = FindStringInArray(hString, WeaponString);
	if(MainIndex == -1)
	{
		char tmpWeaponString[64];
		IntToString(iItemDefinitionIndex, STRING(tmpWeaponString));
		MainIndex = FindStringInArray(hString, tmpWeaponString);
	}
	return MainIndex;
}

public void Switcher_AddWeapon(	char OldWeapon[64],
								char NewWeapon[64],
								int ForceWeaponActive,
								int WeaponIndex,
								int WeaponLevel,
								int WeaponQuality,
								char WeaponAttribute[64],
								int Ammo1,
								int Ammo2,
								int Ammo3,
								int Clip1,
								int Clip2,
								int Clip3)
{
	PushArrayCell(h_index, 0);
	PushArrayString(h_Old_Weapon_String, OldWeapon);
	PushArrayString(h_New_Weapon_String, NewWeapon);
	PushArrayCell(h_ForceWeaponActive, ForceWeaponActive);
	PushArrayCell(h_WeaponIndex, WeaponIndex);
	PushArrayCell(h_WeaponLevel, WeaponLevel);
	PushArrayCell(h_WeaponQuality, WeaponQuality);
	PushArrayString(h_WeaponAttribute, WeaponAttribute);
	PushArrayCell(h_WeaponAmmo1, Ammo1);
	PushArrayCell(h_WeaponAmmo2, Ammo2);
	PushArrayCell(h_WeaponAmmo3, Ammo3);
	PushArrayCell(h_WeaponClip1, Clip1);
	PushArrayCell(h_WeaponClip2, Clip2);
	PushArrayCell(h_WeaponClip3, Clip3);
}

public Action:SB_WEAPON_SWITCHER_CONFIG(client,args)
{
	PrintToChatAll("reloading weapon switcher configuration");
	//PrintToChatAll("Player must rejoin in order to activate it!");

	Handle kv = PrePareTheFile();

	if(kv != null)
	{
		ClearArray(h_index);
		ClearArray(h_Old_Weapon_String);
		ClearArray(h_New_Weapon_String);
		ClearArray(h_ForceWeaponActive);
		ClearArray(h_WeaponIndex);
		ClearArray(h_WeaponLevel);
		ClearArray(h_WeaponQuality);
		ClearArray(h_WeaponAttribute);
		ClearArray(h_WeaponAmmo1);
		ClearArray(h_WeaponAmmo2);
		ClearArray(h_WeaponAmmo3);
		ClearArray(h_WeaponClip1);
		ClearArray(h_WeaponClip2);
		ClearArray(h_WeaponClip3);
		ClearArray(h_index);
		LoadWeaponSwitchingValues(kv);
		CloseTheFile(kv);

		LoopMaxClients(target)
		{
			if(SB_ValidPlayer(target,true))
			{
				int weapon_index = 0;
				int weapon_entity = 0;
				LoopMaxWeapons(weapon_slot)
				{
					weapon_entity=GetPlayerWeaponSlot(target, weapon_slot);
					if(weapon_entity > MaxClients)
					{
						weapon_index = GetEntProp(weapon_entity, Prop_Send, "m_iItemDefinitionIndex");

						if(weapon_index > -1)
						{
							//PrintToChatAll("lookin up weapon %d", weapon_index);
							// run check against configuration file
							//ApplyWeaponValues(kv, target, weapon_index, weapon_entity, true);
							//ApplySwitcherWeapons();
							char weapon_name[64];
							GetEntityClassname(weapon_entity,weapon_name,sizeof(weapon_name));
							//PrintToChatAll("GetEntityClassname %s",weapon_name);

							int MainIndex = Switcher_GetWeapon(h_Old_Weapon_String, weapon_name, weapon_index);

							if(MainIndex>-1)
							{
								//PrintToChatAll("Switcher_GetWeapon MainIndex %d",MainIndex);

								Handle pack;
								if(CreateDataTimer(0.1,Timer_ReplaceWeapon,pack) != null)
								{
									WritePackCell(pack, client);
									WritePackCell(pack, MainIndex);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:SB_TESTING_CONFIG(client,args)
{
	PrintToChatAll("reloading configuration");

	Handle kv = PrePareTheFile();

	if(kv != null)
	{
		LoopMaxClients(target)
		{
			if(SB_ValidPlayer(target,true))
			{
				int weapon_index = 0;
				int weapon_entity = 0;
				LoopMaxWeapons(weapon_slot)
				{
					weapon_entity=GetPlayerWeaponSlot(target, weapon_slot);
					if(weapon_entity > MaxClients)
					{
						weapon_index = GetEntProp(weapon_entity, Prop_Send, "m_iItemDefinitionIndex");

						if(weapon_index > -1)
						{
							//PrintToChatAll("lookin up weapon %d", weapon_index);
							// run check against configuration file
							ApplyWeaponValues(kv, target, weapon_index, weapon_entity, true);
						}
					}
				}
			}
		}
		CloseTheFile(kv);
	}
}

stock void ApplyWeaponsOnClient(int client)
{
	if(!GetConVarBool(sb_weapon_enabled)) return;

	//PrintToChatAll("weapon spawn");
	if(SB_ValidPlayer(client))
	{
		//PrintToChatAll("SB_ValidPlayer spawn");
		Handle kv = PrePareTheFile();

		if(kv != null)
		{
			int weapon_index = 0;
			int weapon_entity = 0;
			LoopMaxWeapons(weapon_slot)
			{
				weapon_entity=GetPlayerWeaponSlot(client, weapon_slot);
				if(weapon_entity > MaxClients)
				{
					weapon_index = GetEntProp(GetPlayerWeaponSlot(client, weapon_slot), Prop_Send, "m_iItemDefinitionIndex");

					if(weapon_index > -1)
					{
						//PrintToChatAll("lookin up weapon %d", weapon_index);
						// run check against configuration file

						// WEAPON MODIFIER CFG:
						ApplyWeaponValues(kv, client, weapon_index, weapon_entity, false);

						// WEAPON SWITCHER CFG:
						char weapon_name[64];
						GetEntityClassname(weapon_entity,weapon_name,sizeof(weapon_name));

						int MainIndex = Switcher_GetWeapon(h_Old_Weapon_String, weapon_name, weapon_index);

						if(MainIndex>-1)
						{
							//PrintToChatAll("Switcher_GetWeapon MainIndex %d",MainIndex);

							Handle pack;
							if(CreateDataTimer(1.0,Timer_ReplaceWeapon,pack) != null)
							{
								WritePackCell(pack, client);
								WritePackCell(pack, MainIndex);
							}
						}

					}
				}
			}
			CloseTheFile(kv);
		}
	}
}

public void OnSB_EventSpawn_Post(client)
{
	ApplyWeaponsOnClient(client);
}

public Handle PrePareTheFile()
{
	char path[1024];

	BuildPath(Path_SM,path,sizeof(path),"configs/sb_weapons.cfg");

	/* Return true if an update was available. */
	Handle kv = CreateKeyValues("TF2_SB_WEAPONS");

	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		return null;
	}
	return kv;
}

public CloseTheFile(Handle kv)
{
	CloseHandle(kv);
}

public LoadWeaponSwitchingValues(Handle kv)
{
	KvRewind(kv);

	char sSectionBuffer[32];
	char sSubKeyBuffer[32];

	//char sTempBuffer[64];

	bool found=false;

	//float newkeyvalue = 1.0;

	char old_weapon[64];
	char new_weapon[64];
	int ForceActiveWeapon = 0;
	int WeaponIndex = 0;
	int WeaponLevel = 0;
	int WeaponQuality = 0;
	char WeaponAttribute[64];
	int Ammo1 = -1;
	int Ammo2 = -1;
	int Ammo3 = -1;
	int Clip1 = -1;
	int Clip2 = -1;
	int Clip3 = -1;

	//GetEntityClassname(weapon_entity,weapon_name,sizeof(weapon_name));
	//PrintToChatAll("weapon name: %s", weapon_name);

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
					PrintToChatAll(sSectionBuffer);
					//PushArrayCell(g_hItemNumber, GetArraySize(g_hItemNumber)+1);

					if (KvGotoFirstSubKey(kv, false))
					{
						// Current key is a section. Browse it recursively.
						do
						{
							if(KvGetSectionName(kv, sSubKeyBuffer, sizeof(sSubKeyBuffer)))
							{
								if(!found && StrContains(sSubKeyBuffer,"switch") == 0)
								{
									if(KvGetNum(kv, NULL_STRING) == 1)
									{
										found = true;
									}
								}
								else if(found && StrContains(sSubKeyBuffer,"old weapon") == 0)
								{
									KvGetString(kv, NULL_STRING, STRING(old_weapon), "");
									//PrintToChatAll("found old weapon: %s",old_weapon);
								}
								else if(found && StrContains(sSubKeyBuffer,"new weapon") == 0)
								{
									KvGetString(kv, NULL_STRING, STRING(new_weapon), "");
									//PrintToChatAll("found new weapon: %s",new_weapon);
								}
								else if(found && StrContains(sSubKeyBuffer,"force active weapon") == 0)
								{
									ForceActiveWeapon = KvGetNum(kv, NULL_STRING, 0);
									//PrintToChatAll("found force active weapon: %d",ForceActiveWeapon);
								}
								else if(found && StrContains(sSubKeyBuffer,"index") == 0)
								{
									WeaponIndex = KvGetNum(kv, NULL_STRING, 0);
									//PrintToChatAll("found new index: %d",WeaponIndex);
								}
								else if(found && StrContains(sSubKeyBuffer,"level") == 0)
								{
									WeaponLevel = KvGetNum(kv, NULL_STRING, 1);
									//PrintToChatAll("found new level: %d",WeaponLevel);
								}
								else if(found && StrContains(sSubKeyBuffer,"quality") == 0)
								{
									WeaponQuality = KvGetNum(kv, NULL_STRING, 0);
									//PrintToChatAll("found new level: %d",WeaponQuality);
								}
								else if(found && StrContains(sSubKeyBuffer,"attribute") == 0)
								{
									KvGetString(kv, NULL_STRING, STRING(WeaponAttribute), "");
									//PrintToChatAll("found attribute: %s",WeaponAttribute);
								}
								else if(found && StrContains(sSubKeyBuffer,"ammo1") == 0)
								{
									Ammo1 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found ammo1: %d",Ammo1);
								}
								else if(found && StrContains(sSubKeyBuffer,"ammo2") == 0)
								{
									Ammo2 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found ammo2: %d",Ammo2);
								}
								else if(found && StrContains(sSubKeyBuffer,"ammo3") == 0)
								{
									Ammo3 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found ammo3: %d",Ammo3);
								}
								else if(found && StrContains(sSubKeyBuffer,"clip1") == 0)
								{
									Clip1 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found clip1: %d",Clip1);
								}
								else if(found && StrContains(sSubKeyBuffer,"clip2") == 0)
								{
									Clip2 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found clip1: %d",Clip2);
								}
								else if(found && StrContains(sSubKeyBuffer,"clip3") == 0)
								{
									Clip3 = KvGetNum(kv, NULL_STRING, -1);
									//PrintToChatAll("found clip1: %d",Clip3);
								}

							}
						} while (KvGotoNextKey(kv, false));
						KvGoBack(kv);
					}
				}
				if(found)
				{
					//PrintToChatAll("if(found) found = false");
					found = false;

					Switcher_AddWeapon(	old_weapon,
										new_weapon,
										ForceActiveWeapon,
										WeaponIndex,
										WeaponLevel,
										WeaponQuality,
										WeaponAttribute,
										Ammo1,
										Ammo2,
										Ammo3,
										Clip1,
										Clip2,
										Clip3);

					strcopy(old_weapon, sizeof(old_weapon), "");
					strcopy(new_weapon, sizeof(new_weapon), "");
					strcopy(WeaponAttribute, sizeof(WeaponAttribute), "");
					ForceActiveWeapon = 0;
					WeaponIndex = 0;
					WeaponLevel = 0;
					WeaponQuality = 0;
					Ammo1 = -1;
					Ammo2 = -1;
					Ammo3 = -1;
					Clip1 = -1;
					Clip2 = -1;
					Clip3 = -1;
				}
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}
		if(found) found = false;
	} while (KvGotoNextKey(kv, false));

	//PrintToChatAll("Finished");
}

public ApplyWeaponValues(Handle kv, client, weapon_index, weapon_entity, bool removefirst)
{
	KvRewind(kv);

	char sSectionBuffer[32];
	char sSubKeyBuffer[32];

	char sTempBuffer[64];

	bool found=false;

	float newkeyvalue = 1.0;

	char weapon_name[64];

	GetEntityClassname(weapon_entity,weapon_name,sizeof(weapon_name));
	//PrintToChatAll("weapon name: %s", weapon_name);

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
					//PushArrayCell(g_hItemNumber, GetArraySize(g_hItemNumber)+1);

					if (KvGotoFirstSubKey(kv, false))
					{
						// Current key is a section. Browse it recursively.
						do
						{
							if(KvGetSectionName(kv, sSubKeyBuffer, sizeof(sSubKeyBuffer)))
							{
								if(!found && StrContains(sSubKeyBuffer,"block") == 0)
								{
									KvGetString(kv, NULL_STRING, sTempBuffer, sizeof(sTempBuffer));
									PushArrayString(h_Block_list, sTempBuffer);
								}
								else if(!found && StrContains(sSubKeyBuffer,"all") == 0)
								{
									if(KvGetNum(kv, NULL_STRING) == 1)
									{
										found = true;
									}
								}
								else if(!found && StrContains(sSubKeyBuffer,"index") == 0)
								{
									if(weapon_index == KvGetNum(kv, NULL_STRING))
									{
										found = true;
									}
								}
								else if(!found && StrContains(sSubKeyBuffer,"class") == 0)
								{
									KvGetString(kv, NULL_STRING, sTempBuffer, sizeof(sTempBuffer));
									if(StrEqual(sTempBuffer,weapon_name))
									{
										found = true;
									}
								}
								else if(found)
								{
									if(!(StrContains(sSubKeyBuffer,"index") == 0 || StrContains(sSubKeyBuffer,"class") == 0))
									{
										// apply to weapon:
										newkeyvalue = KvGetFloat(kv, NULL_STRING);
										//
										//TF2Attrib_SetByName(client, sSubKeyBuffer, newkeyvalue);
										if(removefirst)
										{
											TF2Attrib_RemoveByName(weapon_entity, sSubKeyBuffer);
										}
										TF2Attrib_SetByName(weapon_entity, sSubKeyBuffer, newkeyvalue);
										//PrintToChatAll(sSectionBuffer);
										//PrintToChatAll("%s %.2f",sSubKeyBuffer,newkeyvalue);

										TF2_RegeneratePlayer(client);
									}
								}
							}
						} while (KvGotoNextKey(kv, false));
						KvGoBack(kv);
					}
				}
				if(found) found = false;
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}
		if(found) found = false;
	} while (KvGotoNextKey(kv, false));

	//PrintToChatAll("Finished");
}

public ApplyWeapons(int client)
{
	if(SB_ValidPlayer(client,true))
	{
		ApplyWeaponsOnClient(client);
	}
}
public Native_SB_ApplyWeapons(Handle:plugin,numParams)
{
	if(!g_sb_enabled) return;

	int client=GetNativeCell(1);
	ApplyWeapons(client);
}
/*
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		return;
	}

	if(SB_ValidPlayer(client,true))
	{
		TF2_RegeneratePlayer(client);
	}
}*/


public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!g_sb_enabled) return Plugin_Stop;

	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	//PrintToChatAll("classname %s iItemDefinitionIndex %d",classname,iItemDefinitionIndex);

	int MainIndex = Switcher_GetWeapon(h_Block_list, classname, iItemDefinitionIndex);
	if(MainIndex>-1)
	{
		return Plugin_Stop;
	}

	MainIndex = -1;

	MainIndex = Switcher_GetWeapon(h_Old_Weapon_String, classname, iItemDefinitionIndex);
	if(MainIndex>-1)
	{
		//PrintToChatAll("Switcher_GetWeapon MainIndex %d",MainIndex);

		Handle pack;
		if(CreateDataTimer(0.1,Timer_ReplaceWeapon,pack) != null)
		{
			WritePackCell(pack, client);
			WritePackCell(pack, MainIndex);
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock AddAttribute(client, String:attribute[], Float:value)
{
	if (ValidPlayer(client))
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock RemoveAttribute(client, String:attribute[])
{
	if (ValidPlayer(client))
	{
		TF2Attrib_RemoveByName(client, attribute);
	}
}

stock SetAmmo2(client, iWeapon, iAmmo = 999)
{
	new iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iAmmoType != -1) SetEntProp(client, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock SetClip2(iWeapon, iClip = 99)
{
	SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClip);
}

/** Copied form FF2
 *
 * Gives ammo to a weapon
 *
 * @param client	Client's index
 * @param weapon	Weapon
 * @param ammo		Ammo (set to 1 for clipless weapons, then set the actual ammo using clip)
 * @param clip		Clip
 * @noreturn
 */
stock SetAmmo3(client, weapon, ammo=-1, clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip>-1)
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
		}

		new ammoType=(ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType!=-1)
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
		}
		else if(ammo>-1)  //Only complain if we're trying to set ammo
		{
			decl String:classname[64];
			GetEdictClassname(weapon, classname, sizeof(classname));
			LogError("Cannot give ammo to weapon %s!", classname);
		}
	}
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon == INVALID_HANDLE)
		return -1;
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 1)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);

	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public Action Timer_ReplaceWeapon(Handle timer, Handle datapack)
{
	ResetPack(datapack);
	int client = ReadPackCell(datapack);
	int MainIndex = ReadPackCell(datapack);

	if(!SB_ValidPlayer(client)) return Plugin_Continue;

	//PrintToChatAll("Timer_ReplaceWeapon client %d",client);

	//char old_weapon[64];  // h_Old_Weapon_String
	char new_weapon[64];
	GetArrayString(h_New_Weapon_String, MainIndex, STRING(new_weapon));

	if(StrEqual("",new_weapon))
	{
		//PrintToChatAll("new weapon in sb_weapons.cfg is a empty string");
		return Plugin_Continue;
	}

	int ForceActiveWeapon = GetArrayCell(h_ForceWeaponActive, MainIndex);
	int WeaponIndex = GetArrayCell(h_WeaponIndex, MainIndex);
	int WeaponLevel = GetArrayCell(h_WeaponLevel, MainIndex);
	int WeaponQuality = GetArrayCell(h_WeaponQuality, MainIndex);

	char WeaponAttribute[64];
	GetArrayString(h_WeaponAttribute, MainIndex, STRING(WeaponAttribute));

	//int Ammo1 = GetArrayCell(h_WeaponAmmo1, MainIndex);
	int Ammo2 = GetArrayCell(h_WeaponAmmo2, MainIndex);
	int Ammo3 = GetArrayCell(h_WeaponAmmo3, MainIndex);
	//int Clip1 = GetArrayCell(h_WeaponClip1, MainIndex);
	int Clip2 = GetArrayCell(h_WeaponClip2, MainIndex);
	int Clip3 = GetArrayCell(h_WeaponClip3, MainIndex);


	int iweapon = SpawnWeapon(client, new_weapon, WeaponIndex, WeaponLevel, WeaponQuality, WeaponAttribute);
	if(ForceActiveWeapon)
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iweapon);
	}
	//if(Ammo1)
	//{
	//}

	if(Ammo2)
	{
		SetAmmo2(client, iweapon, Ammo2);
	}
	if(Clip2)
	{
		SetClip2(iweapon, 0);
	}

	if(Ammo3 || Clip3)
	{
		SetAmmo3(client, iweapon, Ammo3, Clip3);
	}

	return Plugin_Continue;
}
