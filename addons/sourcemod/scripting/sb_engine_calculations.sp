#include "do not compile"

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
#include <sdkhooks>

#tryinclude <sb_addon_fc>


#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))



public Plugin:myinfo = {
	name = "Smash Bros Calculations Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}

public OnPluginStart()
{
	RegConsoleCmd("allowengineering",SB_ENGINEERING,"allowengineering");



}

//CreateTimer(1.2,instaspawn,victim);
/*
public Action:instaspawn(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client))
	{
		//TF2_RespawnPlayer(client);
		SDKCall(hSpawnPlayer,client);
	}
}*/


/*
public void OnSB_EventDeath(int victim, int attacker, int assister, int distance, int attacker_hpleft, Handle event)
{
	if(SB_ValidPlayer(victim))
	{
		if(SB_GetPlayerProp(victim,iLives)>0)
		{
			SB_SetPlayerProp(victim,iLives,SB_GetPlayerProp(victim,iLives)-1);
			CreateTimer(3.0,instaspawn,victim);
		}
		//SDKUnhook(victim,SDKHook_OnTakeDamage,OnTakeDamage);
	}
}*/






/*
public Action FakeKillFeedTimer(Handle timer, Handle datapack)
{
	PrintToChatAll("FakeKillFeedTimer start");
	ResetPack(datapack);
	PrintToChatAll("ResetPack(datapack)");
	int victim = ReadPackCell(datapack);
	PrintToChatAll("victim = %d", victim);
	int attacker = ReadPackCell(datapack);
	PrintToChatAll("attacker = %d", attacker);
	SB_FakeKillFeed_TEST(victim, attacker);
	PrintToChatAll("FakeKillFeedTimer end");
	return Plugin_Continue;
}
*/
/*
public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

		SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
	}
}*/

/*
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	PrintToChatAll("victim: %i",victim);
	PrintToChatAll("attacker: %i",attacker);
	PrintToChatAll("inflictor: %i",inflictor);
	PrintToChatAll("Hitgroup: %i",hitgroup);
	PrintToChatAll("Hitbox: %i",hitbox);
	PrintToChatAll("Damage Type: %i",damagetype);
	PrintToChatAll("Ammo Type: %i",ammotype);

	if(inflictor>-1)
	{
		char eClassName[128];
		GetEntityClassname(inflictor, STRING(eClassName));

		PrintToChatAll("GetEntityClassname: %s",eClassName);
	}
	return Plugin_Continue;
}*/


