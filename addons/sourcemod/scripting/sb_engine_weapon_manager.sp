/*
 * =============================================================================
 * Smash Bros Interface Includes File
 * Includes, stocks, natives, and other resources required by Smash Bros Plugins
 *
 * (C)2014 El Diablo of www.war3evo.info                       All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License , version 3.0, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sb_interface>
#include <tf2attributes>

#define LoopMaxWeapons(%1) for(new %1=0;%1<=7;++%1)

#define LoopMaxClients(%1) for(new %1=1;%1<=MaxClients;++%1)


public Plugin:myinfo = {
	name = "Smash Bros Weapons Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}


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

public OnPluginStart()
{
	RegAdminCmd("reloadcfg", SB_TESTING_CONFIG, ADMFLAG_ROOT);

	sb_weapon_enabled = CreateConVar("sb_weapon_enabled", "1", "0 - disable, 1 - enable", FCVAR_PLUGIN);
}

public Action:SB_TESTING_CONFIG(client,args)
{
	PrintToChatAll("reloading configuration");

	Handle kv = PrePareTheFile();

	if(kv != null)
	{
		LoopMaxClients(target)
		{
			if(SB_ValidPlayer(target))
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

public OnSB_EventSpawn_Post(client)
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
						ApplyWeaponValues(kv, client, weapon_index, weapon_entity, false);
					}
				}
			}
			CloseTheFile(kv);
		}
	}
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
								if(!found && StrContains(sSubKeyBuffer,"all") == 0)
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
