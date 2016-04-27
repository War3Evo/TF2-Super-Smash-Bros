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

public bool FakeDeath(int victim, int attacker)
{
	if(SB_ValidPlayer(victim))
	{
		if(SB_GetPlayerProp(victim,iLives)>1)
		{
			SB_SetPlayerProp(victim,iLives,SB_GetPlayerProp(victim,iLives)-1);
			//CreateTimer(3.0,instaspawn,victim);

			iTotalScore[victim]=SB_GetPlayerProp(victim,iLives);

			int RedTeam, BlueTeam;
			CalculateTeamScores(RedTeam,BlueTeam);

			// fake death
			if(GetConVarBool(FindConVar("sb_chatmsg")))
			{
				SB_ChatMessage(0,"{default}[{yellow}Total Lives{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",RedTeam,BlueTeam);
			}

#if defined _sb_addon_fc_included
			if(bHopEnabled)
			{
				//ServerCommand("sm_bhop_enabled %d 0",GetClientUserId(victim));
				FC_SetBhop(victim, false);
			}
#endif

			SB_SpawnPlayer(victim);

			//PrintToChatAll("fake death start");
			//PrintToChatAll("victim = %d, attacker = %d",victim, attacker);
			/*
			Handle pack;
			if(CreateDataTimer(0.1,FakeKillFeedTimer,pack) != null)
			{
				WritePackCell(pack, victim);			// the hacker
				WritePackCell(pack, attacker);			// The Sentry Owner
			}*/
			if(attacker > 32)
			{
				if(attacker!=victim && LastValidAttacker[victim]>0)
				{
					attacker = LastValidAttacker[victim];
				}
				else
				{
					attacker = victim;
				}
			}
			if(!firstblood) firstblood=true;
			SB_FakeKillFeed_TEST(victim, attacker, firstblood);
			LastValidAttacker[victim]=0;
			//PrintToChatAll("fake death end");

			return true;
		}
	}
	return false;
}

public OnSB_TakeDmgAllPre(int victim, int attacker, float damage, int damagecustom)
{
	if(!SB_GetGamePlaying())
	{
		SB_DamageModPercent(0.0);
		return;
	}

	if(damage>0.0 && (attacker > 0 && attacker < 33))
	{
		LastValidAttacker[victim]=attacker;
	}

	// help prevent demos from using stickies to keep themselves launched in the air!
	int inflictor = SB_GetDamageInflictor();
	if(victim==attacker && inflictor>0 && IsValidEdict(inflictor))
	{
		//tf_projectile_flare
		char ent_name[64];
		GetEdictClassname(inflictor,ent_name,64);
		if (StrEqual(ent_name, "tf_projectile_pipe_remote"))
		{
			//SB_DP("m_bTouched? %s",GetEntProp(inflictor, Prop_Send, "m_bTouched")?"TRUE":"FALSE");
			if(!GetEntProp(inflictor, Prop_Send, "m_bTouched"))
			{
				//SB_DP("!m_bTouched");
				SB_DamageModPercent(0.0);
				return;
			}
			/*
			if(!(GetEntityFlags(victim) & FL_ONGROUND) && !(GetEntityFlags(inflictor) & FL_ONGROUND))
			{
				//SB_DP("victim %d is not on ground",victim);
				float inflictorPOS[3];
				GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", inflictorPOS);

				float victimPOS[3];
				GetClientAbsOrigin(victim, victimPOS);

				float distancetoentity = GetVectorDistance(victimPOS, inflictorPOS);

				SB_DP("distancetoentity %f",distancetoentity);

				return;
			}*/
		}
	}

	bool DamageHandled = false;

	/*
	int inflictor = SB_GetDamageInflictor();

	if(attacker!=inflictor)
	{
		if(inflictor>0 && IsValidEdict(inflictor))
		{
			char ent_name[64];
			GetEdictClassname(inflictor,ent_name,64);
			//	DP("ent name %s",ent_name);
			if(StrContains(ent_name,"tf_projectile_rocket",false)==0)
			{
				SB_DP("tf_projectile_rocket");
				return;
			}
		}
	}*/

	//new passcheck = 0;

	//SB_DP("victim %d attacker %d damage %.2f",victim,attacker,damage);
	//SB_DP("SB_GetDamageType %d",SB_GetDamageType());
	//SB_DP("SB_GetDamageInflictor %d",SB_GetDamageInflictor());

	//if(SB_GetDamageType()==DMG_CRUSH)
	//{
		//SB_DP("DMG_CRUSH");
	//}

	//new iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");

	//else if(SB_GetDamageType()==DMG_CRUSH)
	//{
		//SB_DP("DMG_CRUSH");
	//}

	/*
	if(!(GetEntityFlags(victim) & FL_ONGROUND))
	{
		if(SB_GetPlayerProp(victim,iDamage)>10000)
		{
			//ForcePlayerSuicide(victim);
			//SDKHooks_TakeDamage(victim, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
			int pointHurt=CreateEntityByName("point_hurt");
			if(pointHurt)
			{
				DispatchKeyValue(victim,"targetname","sb_hurtme"); //set victim as the target for damage
				DispatchKeyValue(pointHurt,"Damagetarget","sb_hurtme");
				DispatchKeyValue(pointHurt,"Damage","99999");
				DispatchKeyValue(pointHurt,"DamageType","32");
				DispatchKeyValue(pointHurt,"classname","sb_point_hurt");
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt,"Hurt",-1);
				DispatchKeyValue(victim,"targetname","sb_donthurtme"); //unset the victim as target for damage
				RemoveEdict(pointHurt);
			}

			return;
		}
	}*/

	bool DamageCustom = false;
	int customdamage = 0;

	switch (damagecustom)
	{
		case TF_CUSTOM_TAUNT_HADOUKEN, TF_CUSTOM_TAUNT_HIGH_NOON, TF_CUSTOM_TAUNT_GRAND_SLAM, TF_CUSTOM_TAUNT_FENCING,
		TF_CUSTOM_TAUNT_ARROW_STAB, TF_CUSTOM_TAUNT_GRENADE, TF_CUSTOM_TAUNT_BARBARIAN_SWING,
		TF_CUSTOM_TAUNT_UBERSLICE, TF_CUSTOM_TAUNT_ENGINEER_SMASH, TF_CUSTOM_TAUNT_ENGINEER_ARM, TF_CUSTOM_TAUNT_ARMAGEDDON:
		{
			DamageHandled = true;
			DamageCustom = true;
			SB_DamageModPercent(0.0);
		}
	}

	switch (damagecustom)
	{
		case TF_CUSTOM_BACKSTAB, TF_CUSTOM_HEADSHOT:
		{
			DamageHandled = true;
			DamageCustom = true;
			customdamage = 100;
			SB_DamageModPercent(0.0);
		}
	}

	if(SB_ValidPlayer(attacker) && attacker == victim)
	{
		int currentwpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		// boston basher
		if(currentwpn > MaxClients && GetEntProp(currentwpn, Prop_Send, "m_iItemDefinitionIndex")==325)
		{
			//SB_DP("boston basher");
			SB_DamageModPercent(0.0);
			return;
		}
	}

	/*
	if(attacker==victim && SB_GetDamageInflictor()>MaxClients)
	{
		int iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");
		if(iItemDefinitionIndex == 325)
		{
			//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
			//SB_DP("iItemDefinitionIndex 0.0");
			SB_DamageModPercent(0.0);
			return;
		}
	}*/

	if(SB_ValidPlayer(victim) && SB_GetDamageType()==DMG_FALL)
	{
		//SB_DP("FALL DAMAGE");
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		if(GetEntityFlags(victim) & FL_ONGROUND)
		{
			//SB_DP("victim & DMG_FALL 0.0");
			SB_DamageModPercent(0.0);
			//passcheck++;
			return;
		}
	}

	//SB_DP("victim & DMG_FALL pass");

	//else if(SB_ValidPlayer(attacker) && attacker==victim)
	//{
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		//SB_DamageModPercent(0.0);
		//passcheck++;
	//}
	else if(SB_ValidPlayer(attacker) && SB_ValidPlayer(victim) && (GetClientTeam(attacker) != GetClientTeam(victim)))
	{
		//if(iItemDefinitionIndex != 325)
		//{
		if(!DamageCustom)
		{
			int newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
			SB_SetPlayerProp(victim,iDamage,newdamage);
			SB_DamageModPercent(0.01);
		}
		else
		{
			int newdamage = (SB_GetPlayerProp(victim,iDamage) + customdamage);
			SB_SetPlayerProp(victim,iDamage,newdamage);
		}
		//}
		//SB_DP("valid attacker 0.0");
		//passcheck++;
	}
	/*
	else if(SB_ValidPlayer(attacker) && attacker==victim)
	{
		//if(iItemDefinitionIndex != 325)
		//{
		new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		SB_SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		SB_DamageModPercent(0.01);
		//passcheck++;
	}*/

	//SB_DP("valid attacker pass");

	/*
	if(SB_ValidPlayer(victim))
	{
		new Float:vec[3];
		GetClientAbsOrigin(victim, vec);
		if(TR_PointOutsideWorld(vec))
		{
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			// allow to kill
			//ForcePlayerSuicide(victim);
			//SDKHooks_TakeDamage(victim, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
		}
	}*/
	//SB_DP("iItemDefinitionIndex pass");

	if(SB_ValidPlayer(victim))
	{
		if(!DamageHandled && RoundToCeil(damage)>MAXHEALTHCHECK)
		{
			if(SB_GetPlayerProp(victim,iLives)>1)
			{
				SB_DamageModPercent(0.0);
				FakeDeath(victim, attacker);
			}
		}
	}
}

public OnSBEventPostHurt(victim,attacker,dmgamount,const String:weapon[32])
{
	if(SB_ValidPlayer(victim,true) && SB_ValidPlayer(attacker))
	{
		int inflictor = SB_GetDamageInflictor();

		//SB_DP("OnSBEventPostHurt weapon name %s",weapon);

		if(StrEqual(weapon,"tf_weapon_bat"))
		{
			int currentwpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			// boston basher
			if(currentwpn > MaxClients && GetEntProp(currentwpn, Prop_Send, "m_iItemDefinitionIndex")==325)
			{
				//SB_DP("boston basher");
				return;
			}
		}

		if(attacker!=inflictor && (GetClientTeam(attacker) == GetClientTeam(victim)))
		{
			if(inflictor>0 && IsValidEdict(inflictor))
			{
				char ent_name[64];
				GetEdictClassname(inflictor,ent_name,64);
				//SB_DP("ent name %s",ent_name);
				if(StrContains(ent_name,"tf_projectile_rocket",false)==0)
				{
					int owner = GetEntPropEnt(inflictor, Prop_Data, "m_hOwnerEntity");
					if(attacker==owner)
					{
						int MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
						SB_SetHealth(victim, MaxHealth);

						//SB_DP("projectile rocket post hurt");
						return;
					}
				}
			}
		}
		//new iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");
		//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + dmgamount);
		//SB_SetPlayerProp(victim,iDamage,newdamage);

		//new Float:totaldamage = float(newdamage)*4;

		//bool PlayerIsOnFire = TF2_IsPlayerInCondition(victim, TFCond_OnFire);

		if(TF2_IsPlayerInCondition(victim, TFCond_OnFire))
		{
			ExtinguishEntity(victim);
			TF2_RemoveCondition(victim, TFCond_OnFire);
		}

		float totaldamage;

		/*
		if(PlayerIsOnFire)
		{
			totaldamage = FloatDiv(float(SB_GetPlayerProp(victim,iDamage)),0.5);
		}
		else
		{*/
		//totaldamage = FloatMul(float(SB_GetPlayerProp(victim,iDamage)),6.0);
		totaldamage = FloatMul(float(SB_GetPlayerProp(victim,iDamage)),3.0);
		//}

		int MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		SB_SetHealth(victim, MaxHealth);
		//new Float:stren = FloatMul(float(totaldamage),0.1);
		//new Float:stren = float(dmgamount);

		//if(TF2_GetPlayerClass(attacker)==TFClass_Scout)
		//{
			//SB_DP("scout damage %.2f",totaldamage);
		//}

		if(totaldamage)
		{
			//SB_DP("totaldamage %.2f",totaldamage);
			new Float:vAngles[3], Float:vReturn[3];
			//Since m_angEyeAngles or m_angEyeAngles[0] works, I am using the harsh number
			GetClientEyeAngles(attacker, vAngles);

			//if(PlayerIsOnFire)
			//{
				//vAngles[0] = 89.0;
			//}
			vAngles[0] = g_fsb_angles; //50.0

			vReturn[0] = FloatMul( Cosine( DegToRad(vAngles[1])  ) , totaldamage);
			vReturn[1] = FloatMul( Sine( DegToRad(vAngles[1])  ) , totaldamage);
			vReturn[2] = FloatMul( Sine( DegToRad(vAngles[0])  ) , FloatMul(totaldamage,g_fsb_upward_force)); //upward force 1.5

			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vReturn);
		}
		//}
	}
}



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


