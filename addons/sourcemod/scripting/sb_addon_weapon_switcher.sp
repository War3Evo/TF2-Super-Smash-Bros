#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2items>
#tryinclude <DiabloStocks>
#include <tf2attributes>
//#include <sb_interface>

#if !defined _diablostocks_included
#include <tf2_stocks>
#endif

#define TEAM_RED 2


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

//new Spam[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Weapon Blocker",
	author = "El Diablo",
	description = "Weapon Blocker",
	version = "1.0.0.0",
	url = "http://Www.war3evo.info"
};

// https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes
/*
public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
		}
	}
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKUnhook(i,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
		}
	}
}*/

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

/* Removes all weapons from a client's weapon slot
*
* @param client Player's index.
* @param slot Slot index (0-5)
* @noreturn
* @error Invalid client, invalid slot or lack of mod support
*/
stock TF2_RemoveWeaponSlot2(client, slot)
{
	decl ew;
	new weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		ew = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearable");
		if(IsValidEntity(ew))
		{
			TF2_RemoveWearable(client, ew);
		}
		ew = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearableViewModel");
		if(IsValidEntity(ew))
		{
			TF2_RemoveWearable(client, ew);
		}
		RemovePlayerItem(client, weaponIndex);
		AcceptEntityInput(weaponIndex, "Kill");
	}
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
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

stock Handle:PrepareItemHandle(Handle:hItem, String:name[] = "", index = -1, const String:att[] = "", bool:dontpreserve = false)
{
	static Handle:hWeapon;
	new addattribs = 0;

	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);

	new flags = OVERRIDE_ATTRIBUTES;
	if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
	if (hWeapon == INVALID_HANDLE) hWeapon = TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);
//  new Handle:hWeapon = TF2Items_CreateItem(flags);    //INVALID_HANDLE;
	if (hItem != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(hItem);
		if (addattribs > 0)
		{
			for (new i = 0; i < 2 * addattribs; i += 2)
			{
				new bool:dontAdd = false;
				new attribIndex = TF2Items_GetAttributeId(hItem, i);
				for (new z = 0; z < attribCount+i; z += 2)
				{
					if (StringToInt(weaponAttribsArray[z]) == attribIndex)
					{
						dontAdd = true;
						break;
					}
				}
				if (!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(hItem, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount += 2 * addattribs;
		}
		CloseHandle(hItem); //probably returns false but whatever
	}

	if (name[0] != '\0')
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, name);
	}
	if (index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, index);
	}
	if (attribCount > 1)
	{
		TF2Items_SetNumAttributes(hWeapon, (attribCount/2));
		new i2 = 0;
		for (new i = 0; i < attribCount && i < 32; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}
/*
public OnClientPutInServer(client){
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public SDK_OnWeaponSwitch(client, weapon)
{
//
	//DP("weapon from OnWeaponSwitch = %i",weapon);
	if (ValidPlayer(client))
	{
		new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
		new THEweapon = GetEntDataEnt2(client, activeweapon);
		if(IsValidEntity(THEweapon))
		{
			new weaponindex = GetEntProp(THEweapon, Prop_Send, "m_iItemDefinitionIndex");
			//DP("weaponindex = %i",weaponindex);
			if(weaponindex==589)
			{
				PrintCenterText(client,"The Eureka Effect is not allowed!");
				TF2_RemoveWeaponSlot(client, 2);
				//TF2_RemoveAllWeapons(client);
				//new weaponX = GetPlayerWeaponSlot(client, 0);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
				//TF2_RemoveWeaponSlot(client, 1);
				//CreateTimer(0.1, WpnCheck,client);
				//WpnCheck(INVALID_HANDLE, client);

				CreateTimer(0.1, WpnCheck_slot_0,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}

			else if(weaponindex==142) // tf_weapon_robot_arm
			{
				PrintCenterText(client,"The Gunslinger is not allowed!");
				TF2_RemoveWeaponSlot(client, 2);
				CreateTimer(0.1, WpnCheck_slot_0,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
			else if(weaponindex==58 || weaponindex==1083 || weaponindex==1105) // tf_weapon_jar
			{
				PrintCenterText(client,"Jarate is not allowed!");
				TF2_RemoveWeaponSlot(client, 1);
				CreateTimer(0.1, WpnCheck_slot_2,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 2);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
			else if(weaponindex==237) // tf_weapon_rocketlauncher
			{
				PrintCenterText(client,"Rocket Jumper is not allowed!");
				TF2_RemoveWeaponSlot(client, 0);
				CreateTimer(0.1, WpnCheck_slot_2,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 2);
				if(IsValidEntity(weaponX))
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
				}
			}
			else if(weaponindex==222 || weaponindex==1121) // tf_weapon_jar_milk
			{
				PrintCenterText(client,"Mad Milk is not allowed!");
				TF2_RemoveWeaponSlot(client, 1);
				CreateTimer(0.1, WpnCheck_slot_2,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 2);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			} else if(weaponindex==264) // PAN
			{
				PrintCenterText(client,"No Pans!");
				TF2_RemoveWeaponSlot(client,2);

				CreateTimer(0.1, WpnCheck_slot_2,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 2);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);

			}
		}

		//decl String:weaponName[128];
		//GetEdictClassname(THEweapon, weaponName, sizeof(weaponName));
		//DP("Weapon name: %s",weaponName);
	}
	//return Plugin_Continue;
	//return true;
}

public Action:WpnCheck(Handle:timer, any:client)
{
	//FakeClientCommand(client, "slot1");
	if (ValidPlayer(client))
	{
		//PrintCenterText(client,"The Eureka Effect is not allowed! All Weapons Cooldown %i seconds.",Spam[client]);
		PrintCenterText(client,"The Eureka Effect is not allowed!");
		TF2_RemoveAllWeapons(client);
		//new weaponX = GetPlayerWeaponSlot(client, 0);
		//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
		//Spam[client]=Spam[client]-1;
		//if(Spam[client]>0)
			//CreateTimer(1.0, WpnCheck,client);
	}
}

public OnTF2Jail_EventSpawn(client)
{
	if (ValidPlayer(client) && IsPlayerAlive(client))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if(class==TFClass_Pyro)
		{
			AddAttribute(client, "airblast disabled", 1.0);
		}

		//new weaponX = GetPlayerWeaponSlot(client, 0);
		new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
		new THEweapon = GetEntDataEnt2(client, activeweapon);
		if(IsValidEntity(THEweapon))
		{
			new weaponindex = GetEntProp(THEweapon, Prop_Send, "m_iItemDefinitionIndex");
			//DP("weaponindex = %i",weaponindex);
			if(weaponindex==589)
			{
				PrintCenterText(client,"The Eureka Effect is not allowed!");
				TF2_RemoveWeaponSlot(client, 2);
				//TF2_RemoveAllWeapons(client);
				//new weaponX = GetPlayerWeaponSlot(client, 0);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
				//TF2_RemoveWeaponSlot(client, 1);
				//CreateTimer(0.1, WpnCheck,client);
				//WpnCheck(INVALID_HANDLE, client);

				CreateTimer(0.1, WpnCheck_slot_0,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
			else if(weaponindex==142) // tf_weapon_robot_arm
			{
				PrintCenterText(client,"The Gunslinger is not allowed!");
				//TF2_RemoveWeaponSlot(client, 2);

				//TF2_RemoveWeaponSlot2(client, TFWeaponSlot_Melee);
				//SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");

				//weapon = SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");
				//CreateTimer(0.1, WpnCheck_slot_0,client);
				//Spam[client]=10;
				//new weaponX = GetPlayerWeaponSlot(client, 0);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
			else if(weaponindex==58 || weaponindex==1083 || weaponindex==1105) // tf_weapon_jar
			{
				PrintCenterText(client,"Jarate is not allowed!");
				//TF2_RemoveWeaponSlot(client, 1);
				//CreateTimer(0.1, WpnCheck_slot_2,client);
				//Spam[client]=10;
				//new weaponX = GetPlayerWeaponSlot(client, 2);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
			else if(weaponindex==237) // tf_weapon_rocketlauncher
			{
				PrintCenterText(client,"Rocket Jumper is not allowed!");
				//TF2_RemoveWeaponSlot(client, 0);
				//CreateTimer(0.1, WpnCheck_slot_2,client);
				//Spam[client]=10;
				//new weaponX = GetPlayerWeaponSlot(client, 2);
				//if(IsValidEntity(weaponX))
				//{
					//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
				//}
			}
			else if(weaponindex==222 || weaponindex==1121) // tf_weapon_jar_milk
			{
				PrintCenterText(client,"Mad Milk is not allowed!");
				//TF2_RemoveWeaponSlot(client, 1);
				//CreateTimer(0.1, WpnCheck_slot_2,client);
				//Spam[client]=10;
				//new weaponX = GetPlayerWeaponSlot(client, 2);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}	else if((weaponindex==56 || weaponindex==1005 || weaponindex==1092) && GetClientTeam(client)==TEAM_RED) // tf_weapon_jar_milk
			{
				PrintCenterText(client,"NO BOWS ON RED");
				//TF2_RemoveWeaponSlot(client, 1);
				//CreateTimer(0.1, WpnCheck_slot_2,client);
				//Spam[client]=10;
				//new weaponX = GetPlayerWeaponSlot(client, 2);
				//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
		}
	}
}


public Action:WpnCheck_slot_0(Handle:timer, any:client)
{
	//FakeClientCommand(client, "slot1");
	if (ValidPlayer(client))
	{
		new weaponX = GetPlayerWeaponSlot(client, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
		Spam[client]=Spam[client]-1;
		if(Spam[client]>0)
			CreateTimer(1.0, WpnCheck_slot_0, client);
	}
}

public Action:WpnCheck_slot_2(Handle:timer, any:client)
{
	//FakeClientCommand(client, "slot1");
	if (ValidPlayer(client))
	{
		new weaponX = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
		Spam[client]=Spam[client]-1;
		if(Spam[client]>0)
			CreateTimer(1.0, WpnCheck_slot_2, client);
	}
}*/

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	//PrintToChat(client,"%d",iItemDefinitionIndex);
	//static Handle:item = INVALID_HANDLE;

	//if (item != INVALID_HANDLE)
	//{
		//CloseHandle(item);
		//item = INVALID_HANDLE;
	//}

	//PrintToChat(client,"%s",classname);

	// Spectators shouldn't have their items
	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (StrContains(classname, "tf_weapon_sniperrifle") > -1)
	{
		CreateTimer(0.1, Timer_ReplaceWeapon, client);
		return Plugin_Handled;
	}
	if(iItemDefinitionIndex==589) //The Eureka Effect
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_Eureka, client);
		return Plugin_Handled;
	}
	if(iItemDefinitionIndex==947 || iItemDefinitionIndex==60|| iItemDefinitionIndex==297) //The Cloak and Dagger
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_Cloak_And_Dagger, client);
		return Plugin_Handled;
	}
	if(iItemDefinitionIndex==59) //Dead Ringer
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_Cloak_And_Dagger, client);
		return Plugin_Handled;
	}

	if (StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper"))
	{
		return Plugin_Stop;
	}
	/*
	if(iItemDefinitionIndex==325 || iItemDefinitionIndex==452) //The Boston Basher  / Three-Rune Blade
	{
		TF2Attrib_SetByName(iEntity, String:strAttrib[], Float:flValue);
		CreateTimer(0.1, Timer_ReplaceWeapon_SpikeBat, client);
		return Plugin_Handled;
	}*/

/*
	if(iItemDefinitionIndex==589 || iItemDefinitionIndex==142)
	{
		//new Handle:hItemOverride = PrepareItemHandle(hItem, "tf_weapon_wrench", 7, "");
		//if (hItemOverride != INVALID_HANDLE)
		//{
			//hItem = hItemOverride;
			//return Plugin_Changed;
		//}

		// Give the player a Huntsman instead of a Sniper Rifle
		//if (StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap"))
		//{
		//item = TF2Items_CreateItem(OVERRIDE_ALL);
		//TF2Items_SetClassname(item, "tf_weapon_wrench");
		//TF2Items_SetItemIndex(item, 7);
		//TF2Items_SetLevel(item, 10);
		//TF2Items_SetQuality(item, 6);
		//TF2Items_SetNumAttributes(item, 2);
		//TF2Items_SetAttribute(item, 0, 37, 0.5);
		//TF2Items_SetAttribute(item, 1, 328, 1.0);
		//hItem = item;
		//return Plugin_Changed;
		//}
		CreateTimer(0.1, Timer_ReplaceWeapon, client);
		return Plugin_Handled;
	}
	else if(iItemDefinitionIndex==58 || iItemDefinitionIndex==1083 || iItemDefinitionIndex==1105)
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_2, client);
		return Plugin_Handled;
	}
	else if(iItemDefinitionIndex==237) // tf_weapon_rocketlauncher
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_3, client);
		return Plugin_Handled;
	}
	else if(iItemDefinitionIndex==222 || iItemDefinitionIndex==1121) // tf_weapon_jar_milk
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_4, client);
		return Plugin_Handled;
	}
	else if(iItemDefinitionIndex==60) //  tf_weapon_invis // cloak and dagger
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_5, client);
		return Plugin_Handled;
	}
	else if(iItemDefinitionIndex==25 || iItemDefinitionIndex==737 || iItemDefinitionIndex==26 || iItemDefinitionIndex==28) //  tf_weapon_pda_engineer_build
	{
		return Plugin_Handled;
	}else if((iItemDefinitionIndex==56 || iItemDefinitionIndex==1005 || iItemDefinitionIndex==1092) && GetClientTeam(client)==TEAM_RED)
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_6, client);
		return Plugin_Handled;
	}	else if(iItemDefinitionIndex==264)
	{
		CreateTimer(0.1, Timer_ReplaceWeapon_7, client);
		return Plugin_Handled;
	}*/
	return Plugin_Continue;
}

//sm_rcon sm plugins reload sb_addon_weapon_switcher.smx

public Action:Timer_ReplaceWeapon(Handle:timer, any:client)
{
	new iweapon = SpawnWeapon(client, "tf_weapon_compound_bow", 56, 1, 6, "");
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iweapon);
	SetAmmo3(client, iweapon, 12, 1);

	//SetAmmo3(client, iweapon, 1, 25);
	//SetAmmo2(client, iweapon, 1);
	//SetClip2(iweapon, 25);
}

public Action:Timer_ReplaceWeapon_Cloak_And_Dagger(Handle:timer, any:client)
{
	//new iweapon =
	SpawnWeapon(client, "tf_weapon_invis", 30, 1, 6, "");
	//SetAmmo2(client, iweapon, 0);
	//SetClip2(iweapon, 0);
}

public Action:Timer_ReplaceWeapon_Eureka(Handle:timer, any:client)
{
	new iweapon = SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 6, "");
	SetAmmo2(client, iweapon, 0);
	SetClip2(iweapon, 0);
}

public Action:Timer_ReplaceWeapon_3(Handle:timer, any:client)
{
	new iweapon = SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 6, "");
	//new iweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	SetAmmo2(client, iweapon, 0);
	SetClip2(iweapon, 0);

	//new Handle:info = CreateKeyValues("");
	//KvSetNum(info, "client", client);
	//KvSetNum(info, "iweapon", iweapon);
	//CreateTimer(1.0, Take_Ammo_Timer, info);
}

public Action:Timer_ReplaceWeapon_4(Handle:timer, any:client)
{
	new iweapon = SpawnWeapon(client, "tf_weapon_pistol_scout", 23, 1, 6, "");
	//new iweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	SetAmmo2(client, iweapon, 0);
	SetClip2(iweapon, 0);

	//new Handle:info = CreateKeyValues("");
	//KvSetNum(info, "client", client);
	//KvSetNum(info, "iweapon", iweapon);
	//CreateTimer(1.0, Take_Ammo_Timer, info);
}

public Action:Timer_ReplaceWeapon_5(Handle:timer, any:client)
{
	SpawnWeapon(client, "tf_weapon_invis", 30, 1, 6, "");
}
public Action:Timer_ReplaceWeapon_6(Handle:timer, any:client)
{
	//PrintToChat(client,"attempting");
	new iweapon = SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 1, 6, "");
	SetAmmo2(client, iweapon, 0);
	SetClip2(iweapon, 25);

}
public Action:Timer_ReplaceWeapon_7(Handle:timer, any:client)
{
	//PrintToChat(client,"attempting");

	//new iweapon = SpawnWeapon(client, "tf_weapon_bat", 0, 1, 6, "");


	//Client_EquipWeapon(client, iweapon, true);
	//SetAmmo2(client, iweapon, 0);
	//SetClip2(iweapon, 0);

}
// take ammo
/*
public Action:Take_Ammo_Timer(Handle:timer, Handle:info)
{
	new client = KvGetNum(info, "client");
	if(ValidPlayer(client))
	{
		new iweapon = KvGetNum(info, "iweapon");
		SetAmmo2(client, iweapon, 0);
	}
	CloseHandle(info);
}*/
